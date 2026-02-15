# SAIGEQTL Cell-Level Test: Portable Standard Workflow

This guide describes a portable Step1 -> Step2 test flow for SAIGEQTL in cell-level genotype mode.

## Scope

- Mode: `--use_cell_level_genotype TRUE`
- Test size: first 100 genes from an expression matrix
- Step2 behavior in this mode: exact `Sigma^{-1}` projection (variance ratio input is ignored)

## Input Requirements

- Expression matrix (TSV):
  - must contain `individual` and `barcode` columns
  - gene expression columns follow those metadata columns
- PLINK prefix for Step1:
  - `${PLINK_PREFIX}.bed`
  - `${PLINK_PREFIX}.bim`
  - `${PLINK_PREFIX}.fam`

## Complete Test Script

Save as `run_cell_level_test_portable.sh` and run:

```bash
bash run_cell_level_test_portable.sh <repo_dir> <expr_matrix.tsv> <plink_prefix> [work_dir]
```

Script:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:?repo_dir required}"
EXPR_MATRIX="${2:?expression_matrix.tsv required}"
PLINK_PREFIX="${3:?plink_prefix required}"
WORK_DIR="${4:-$(pwd)/cell_level_test_outputs}"

PIXI_BIN="${PIXI_BIN:-$HOME/.pixi/bin/pixi}"
CONDA_OVERRIDE_GLIBC="${CONDA_OVERRIDE_GLIBC:-}"

OUT_DIR="${WORK_DIR}/outputs"
mkdir -p "${OUT_DIR}"

SUBSET_EXPR="${OUT_DIR}/expr_first100genes.tsv"
SUBSET_EXPR_BARCODE="${OUT_DIR}/expr_first100genes_barcode.tsv"
TEST_GENE_FILE="${OUT_DIR}/test_gene.txt"
STEP1_PREFIX="${OUT_DIR}/step1_null"
STEP1_MODEL_RDA="${STEP1_PREFIX}.rda"
CELL_ORDER="${OUT_DIR}/cell_id_order.txt"
VCF_OUT="${OUT_DIR}/gene_expr.vcf.gz"
STEP2_PREFIX="${OUT_DIR}/gene_gene_results"
STEP2_LOG="${OUT_DIR}/step2.log"

run_cmd() {
  if [[ -n "${CONDA_OVERRIDE_GLIBC}" ]]; then
    export CONDA_OVERRIDE_GLIBC
  fi
  "${PIXI_BIN}" run --manifest-path "${REPO_DIR}/pixi.toml" "$@"
}

for f in "${EXPR_MATRIX}" "${PLINK_PREFIX}.bed" "${PLINK_PREFIX}.bim" "${PLINK_PREFIX}.fam"; do
  [[ -f "${f}" ]] || { echo "Missing input: ${f}" >&2; exit 1; }
done
[[ -x "${PIXI_BIN}" ]] || { echo "pixi not found: ${PIXI_BIN}" >&2; exit 1; }

echo "[1] Install local SAIGEQTL package"
run_cmd R CMD INSTALL "${REPO_DIR}"

echo "[2] Subset to first 100 genes"
run_cmd Rscript -e '
args <- commandArgs(trailingOnly = TRUE)
suppressPackageStartupMessages(library(data.table))
dt <- fread(args[1])
stopifnot(all(c("individual","barcode") %in% names(dt)))
if (ncol(dt) < 102) stop("Need at least 100 gene columns")
out <- dt[, c(1,2,3:102), with = FALSE]
fwrite(out, args[2], sep = "\t")
' "${EXPR_MATRIX}" "${SUBSET_EXPR}"

echo "[3] Select a non-sparse, non-low-variance gene for Step1"
run_cmd Rscript -e '
args <- commandArgs(trailingOnly = TRUE)
suppressPackageStartupMessages(library(data.table))
dt <- fread(args[1])
genes <- setdiff(names(dt), c("individual","barcode"))
min_nonzero_frac <- 0.05
min_sd <- 0.1
sel <- NA_character_
for (g in genes) {
  x <- suppressWarnings(as.numeric(dt[[g]]))
  if (all(is.na(x))) next
  nz <- mean(x != 0, na.rm = TRUE)
  sx <- sd(x, na.rm = TRUE)
  if (is.finite(nz) && is.finite(sx) && nz >= min_nonzero_frac && sx >= min_sd) {
    sel <- g; break
  }
}
if (is.na(sel)) stop("No gene passed sparse/variance filter")
writeLines(sel, args[2])
' "${SUBSET_EXPR}" "${TEST_GENE_FILE}"

TEST_GENE="$(cat "${TEST_GENE_FILE}")"
echo "Selected gene: ${TEST_GENE}"

echo "[4] Run Step1 (skip variance ratio for cell-level exact Step2)"
run_cmd Rscript "${REPO_DIR}/extdata/step1_fitNULLGLMM_qtl.R" \
  --plinkFile "${PLINK_PREFIX}" \
  --phenoFile "${SUBSET_EXPR}" \
  --phenoCol "${TEST_GENE}" \
  --traitType quantitative \
  --sampleIDColinphenoFile individual \
  --cellIDColinphenoFile barcode \
  --isShrinkModelOutput FALSE \
  --IsOverwriteVarianceRatioFile TRUE \
  --LOCO FALSE \
  --minMAFforGRM 0.2 \
  --maxiter 10 \
  --maxiterPCG 100 \
  --tolPCG 0.001 \
  --nrun 2 \
  --numRandomMarkerforVarianceRatio 1 \
  --traceCVcutoff 0.5 \
  --ratioCVcutoff 0.2 \
  --skipVarianceRatioEstimation TRUE \
  --nThreads 1 \
  --outputPrefix "${STEP1_PREFIX}"

[[ -f "${STEP1_MODEL_RDA}" ]] || { echo "Missing Step1 model: ${STEP1_MODEL_RDA}" >&2; exit 2; }

echo "[5] Extract cell_id_order from Step1 barcode"
run_cmd Rscript -e '
args <- commandArgs(trailingOnly = TRUE)
load(args[1])
if (!exists("modglmm") || is.null(modglmm$barcode)) stop("barcode missing in Step1 model")
writeLines(as.character(modglmm$barcode), args[2])
' "${STEP1_MODEL_RDA}" "${CELL_ORDER}"

echo "[6] Convert expression matrix to barcode-first format"
run_cmd Rscript -e '
args <- commandArgs(trailingOnly = TRUE)
suppressPackageStartupMessages(library(data.table))
dt <- fread(args[1])
genes <- setdiff(names(dt), c("individual","barcode"))
out <- dt[, c("barcode", genes), with = FALSE]
fwrite(out, args[2], sep = "\t")
' "${SUBSET_EXPR}" "${SUBSET_EXPR_BARCODE}"

echo "[7] Build VCF from expression matrix"
run_cmd Rscript "${REPO_DIR}/scripts/expression_matrix_to_vcf.R" \
  --expression-matrix "${SUBSET_EXPR_BARCODE}" \
  --sample-order "${CELL_ORDER}" \
  --output-vcf "${VCF_OUT}" \
  --scale-mode none

if [[ ! -f "${VCF_OUT}.csi" ]]; then
  run_cmd bcftools index -f -c "${VCF_OUT}"
fi

echo "[8] Run Step2 in cell-level exact mode"
SAIGEQTL_USE_SEQUENTIAL_FUTURE=1 run_cmd Rscript "${REPO_DIR}/extdata/step2_tests_qtl.R" \
  --vcfFile "${VCF_OUT}" \
  --vcfFileIndex "${VCF_OUT}.csi" \
  --vcfField DS \
  --chrom expr \
  --LOCO FALSE \
  --minMAF 0 \
  --minMAC 0.5 \
  --markers_per_chunk 1000 \
  --GMMATmodelFile "${STEP1_MODEL_RDA}" \
  --SAIGEOutputFile "${STEP2_PREFIX}" \
  --use_cell_level_genotype TRUE \
  2>&1 | tee "${STEP2_LOG}"

echo "[9] Validate outputs"
[[ -f "${STEP2_PREFIX}" ]] || { echo "Missing Step2 output: ${STEP2_PREFIX}" >&2; exit 3; }
grep -F "Cell-level genotype mode: using exact Sigma^{-1} projection" "${STEP2_LOG}" >/dev/null
! grep -F "0 samples will be used" "${STEP2_LOG}" >/dev/null

echo "PASS"
echo "Step1 model: ${STEP1_MODEL_RDA}"
echo "Step2 result: ${STEP2_PREFIX}"
echo "Step2 log: ${STEP2_LOG}"
```

## Expected Outputs

- `step1_null.rda`
- `gene_expr.vcf.gz` and `gene_expr.vcf.gz.csi`
- `gene_gene_results`
- `step2.log`

## Validation Rules

- Log must include:
  - `Cell-level genotype mode: using exact Sigma^{-1} projection`
- Log must not include:
  - `0 samples will be used`

## Notes

- In cell-level exact mode, Step2 ignores variance ratio input.
- For non-cell-level workflows, keep variance-ratio behavior validated separately.
