#!/usr/bin/env bash
set -euo pipefail

# A minimal, self-contained cell-level compatibility example using bundled extdata.
# It intentionally builds a toy quantitative phenotype and a per-cell genotype VCF
# so Step1/Step2 can be validated with --use_cell_level_genotype TRUE.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

PIXI_BIN="${PIXI_BIN:-$HOME/.pixi/bin/pixi}"
MANIFEST="${REPO_ROOT}/pixi.toml"
OUT_DIR="${1:-${REPO_ROOT}/test_output_celllevel_example}"
mkdir -p "$OUT_DIR"

PHENO_IN="extdata/input/seed_1_100_nindep_100_ncell_100_lambda_2_tauIntraSample_0.5_Poisson.txt"
PLINK_STEP1="extdata/input/n.indep_100_n.cell_1_01.step1"
VCF_IN="extdata/input/n.indep_100_n.cell_1.vcf.gz"

echo "[1/6] Build compatible phenotype with CELL_ID and toy quantitative trait"
"$PIXI_BIN" run --manifest-path "$MANIFEST" Rscript -e '
  suppressPackageStartupMessages(library(data.table))
  set.seed(42)
  dt <- fread(commandArgs(trailingOnly = TRUE)[1])
  dt[, CELL_ID := sprintf("%s_c%03d", IND_ID, seq_len(.N)), by = IND_ID]
  dt[, q_trait := 0.4 * X1 + 0.2 * X2 + 0.3 * pf1 - 0.2 * pf2 + rnorm(.N, 0, 0.05)]
  setcolorder(dt, c("IND_ID", "CELL_ID", setdiff(names(dt), c("IND_ID", "CELL_ID"))))
  fwrite(dt, commandArgs(trailingOnly = TRUE)[2], sep = "\t")
' "$PHENO_IN" "$OUT_DIR/pheno_with_cellid_quanttoy.txt"

echo "[2/6] Run Step1 (non-shrink, cell-level IDs enabled)"
"$PIXI_BIN" run --manifest-path "$MANIFEST" Rscript extdata/step1_fitNULLGLMM_qtl.R \
  --useSparseGRMtoFitNULL=FALSE \
  --useGRMtoFitNULL=FALSE \
  --phenoFile="$OUT_DIR/pheno_with_cellid_quanttoy.txt" \
  --phenoCol=q_trait \
  --covarColList=pf1,pf2 \
  --sampleCovarColList= \
  --sampleIDColinphenoFile=IND_ID \
  --cellIDColinphenoFile=CELL_ID \
  --traitType=quantitative \
  --isShrinkModelOutput=FALSE \
  --outputPrefix="$OUT_DIR/quanttoy_cellonlycov_noshrink" \
  --skipVarianceRatioEstimation=TRUE \
  --isRemoveZerosinPheno=FALSE \
  --isCovariateOffset=FALSE \
  --isCovariateTransform=TRUE \
  --skipModelFitting=FALSE \
  --tol=0.00001 \
  --plinkFile="$PLINK_STEP1" \
  --IsOverwriteVarianceRatioFile=TRUE \
  > "$OUT_DIR/step1_quanttoy_celllevel.log" 2>&1

if ! rg -q "Convergence Status: SUCCESS" "$OUT_DIR/quanttoy_cellonlycov_noshrink.status.txt"; then
  echo "Step1 failed. See $OUT_DIR/step1_quanttoy_celllevel.log" >&2
  exit 1
fi

echo "[3/6] Build cell_id_order.txt from Step1 barcode"
"$PIXI_BIN" run --manifest-path "$MANIFEST" Rscript -e '
  load(commandArgs(trailingOnly = TRUE)[1])
  writeLines(as.character(modglmm$barcode), commandArgs(trailingOnly = TRUE)[2])
' "$OUT_DIR/quanttoy_cellonlycov_noshrink.rda" "$OUT_DIR/cell_id_order.txt"

echo "[4/6] Build per-cell genotype-like matrix by expanding bundled VCF GT to cells"
"$PIXI_BIN" run --manifest-path "$MANIFEST" Rscript -e '
  suppressPackageStartupMessages(library(data.table))
  args <- commandArgs(trailingOnly = TRUE)
  ph <- fread(args[1], select = c("IND_ID", "CELL_ID"))
  vcf <- args[2]
  out <- args[3]
  cmd <- sprintf("bcftools query -f \"%%ID[\\\\t%%GT]\\\\n\" %s | head -n 100", vcf)
  gt <- fread(cmd = cmd, header = FALSE)
  sample_ids <- scan(pipe(sprintf("bcftools query -l %s", vcf)), what = character(), quiet = TRUE)
  if (ncol(gt) != length(sample_ids) + 1) stop("GT table/sample count mismatch")
  marker_ids <- as.character(gt[[1]])
  gtm <- as.matrix(gt[, -1, with = FALSE])
  rownames(gtm) <- marker_ids
  colnames(gtm) <- sample_ids
  gt_to_ds <- function(x) {
    x <- gsub("\\|", "/", x)
    y <- rep(NA_real_, length(x))
    y[x == "0/0"] <- 0
    y[x %in% c("0/1", "1/0")] <- 1
    y[x == "1/1"] <- 2
    y
  }
  ds <- apply(gtm, 2, gt_to_ds)
  if (!is.matrix(ds)) ds <- matrix(ds, nrow = nrow(gtm), ncol = ncol(gtm))
  rownames(ds) <- marker_ids
  colnames(ds) <- sample_ids
  idx <- match(ph$IND_ID, sample_ids)
  if (anyNA(idx)) stop("Some IND_ID not found in VCF samples")
  cell_ds <- t(ds[, idx, drop = FALSE])
  colnames(cell_ds) <- marker_ids
  cell_mat <- cbind(data.table(barcode = ph$CELL_ID), as.data.table(cell_ds))
  fwrite(cell_mat, out, sep = "\t")
' "$OUT_DIR/pheno_with_cellid_quanttoy.txt" "$VCF_IN" "$OUT_DIR/celllevel_gt_matrix_100markers.tsv"

echo "[5/6] Convert matrix to cell-level VCF"
"$PIXI_BIN" run --manifest-path "$MANIFEST" Rscript scripts/expression_matrix_to_vcf.R \
  --expression-matrix "$OUT_DIR/celllevel_gt_matrix_100markers.tsv" \
  --sample-order "$OUT_DIR/cell_id_order.txt" \
  --output-vcf "$OUT_DIR/celllevel_gt_100markers.vcf.gz" \
  --scale-mode none \
  > "$OUT_DIR/convert_to_vcf.log" 2>&1

if [[ ! -f "$OUT_DIR/celllevel_gt_100markers.vcf.gz.csi" ]]; then
  "$PIXI_BIN" run --manifest-path "$MANIFEST" bcftools index -f -c "$OUT_DIR/celllevel_gt_100markers.vcf.gz"
fi

echo "[6/6] Run Step2 with --use_cell_level_genotype TRUE"
SAIGEQTL_USE_SEQUENTIAL_FUTURE=1 \
"$PIXI_BIN" run --manifest-path "$MANIFEST" Rscript extdata/step2_tests_qtl.R \
  --vcfFile "$OUT_DIR/celllevel_gt_100markers.vcf.gz" \
  --vcfFileIndex "$OUT_DIR/celllevel_gt_100markers.vcf.gz.csi" \
  --vcfField DS \
  --chrom expr \
  --LOCO FALSE \
  --minMAF 0 \
  --minMAC 0.5 \
  --markers_per_chunk 1000 \
  --GMMATmodelFile "$OUT_DIR/quanttoy_cellonlycov_noshrink.rda" \
  --SAIGEOutputFile "$OUT_DIR/celllevel_gt100_results_quanttoy_cellonlycov_noshrink" \
  --use_cell_level_genotype TRUE \
  > "$OUT_DIR/step2_celllevel.log" 2>&1

if rg -F -q "Cell-level genotype mode: using exact Sigma^{-1} projection" "$OUT_DIR/step2_celllevel.log" \
  && ! rg -q "0 samples will be used" "$OUT_DIR/step2_celllevel.log" \
  && ! rg -q "Error" "$OUT_DIR/step2_celllevel.log"; then
  echo "PASS: compatible cell-level example completed."
  echo "Output: $OUT_DIR/celllevel_gt100_results_quanttoy_cellonlycov_noshrink"
else
  echo "FAILED: see $OUT_DIR/step2_celllevel.log" >&2
  exit 1
fi
