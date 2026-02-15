# SAIGEQTL Cell-Level Test: Standard Usage Flow

This document describes the validated standard workflow to run SAIGEQTL in **cell-level genotype mode** (Step1 -> Step2) in this environment.

## Scope

- Mode: `--use_cell_level_genotype TRUE`
- Goal: run Step1 null model and Step2 association successfully on a 100-gene subset
- In this mode, Step2 uses exact `Sigma^{-1}` projection and does **not** require variance-ratio estimation

## Environment

- Repository: `/humgen/atgu1/fin/zhangjun/SAIGEQTL`
- Test workspace: `/humgen/atgu1/fin/zhangjun/projects/saigeqtl_cell_level_test`
- Runner: `~/.pixi/bin/pixi`
- Required env:
  - `CONDA_OVERRIDE_GLIBC=2.28`

## Inputs

- Expression matrix (TSV): first two columns must include `individual` and `barcode`
  - Current test input:
    `/humgen/atgu1/fin/wzhou/projects/eQTL_method_dev/realdata/oneK1K/AnnaCuomo_Yavar/input_files/SCT_counts/B_all_sc_pheno_cov_pseudotime.renamegene2.tsv`
- PLINK prefix for Step1:
  - `.bed/.bim/.fam` for
    `/humgen/atgu1/fin/wzhou/projects/eQTL_method_dev/realdata/oneK1K/AnnaCuomo_Yavar/input_files/SCT_counts/full_genome_chr17`

## Standard Run (Recommended)

### 1) Submit Step1 on cluster (qsub)

```bash
qsub /humgen/atgu1/fin/zhangjun/projects/saigeqtl_cell_level_test/step1_qsub.sh
```

What this script does:

- installs current SAIGEQTL source
- subsets to first 100 genes
- filters sparse/low-variance genes and selects one phenotype gene
- runs Step1 with:
  - `--skipVarianceRatioEstimation TRUE`
  - `--isShrinkModelOutput FALSE`
  - `--cellIDColinphenoFile barcode`

### 2) Verify Step1 success

Expected files:

- `outputs/step1_null.rda`
- `outputs/step1_null.status.txt` with `Convergence Status: SUCCESS`

Notes:

- `step1_null.varianceRatio.txt` is intentionally absent in this mode.

### 3) Run Step2 in cell-level exact mode

Use the validated command pattern:

```bash
SAIGEQTL_USE_SEQUENTIAL_FUTURE=1 CONDA_OVERRIDE_GLIBC=2.28 ~/.pixi/bin/pixi run --manifest-path /humgen/atgu1/fin/zhangjun/SAIGEQTL/pixi.toml \
Rscript /humgen/atgu1/fin/zhangjun/SAIGEQTL/extdata/step2_tests_qtl.R \
  --vcfFile /humgen/atgu1/fin/zhangjun/projects/saigeqtl_cell_level_test/outputs/gene_expr.vcf.gz \
  --vcfFileIndex /humgen/atgu1/fin/zhangjun/projects/saigeqtl_cell_level_test/outputs/gene_expr.vcf.gz.csi \
  --vcfField DS \
  --chrom expr \
  --LOCO FALSE \
  --minMAF 0 \
  --minMAC 0.5 \
  --markers_per_chunk 1000 \
  --GMMATmodelFile /humgen/atgu1/fin/zhangjun/projects/saigeqtl_cell_level_test/outputs/step1_null.rda \
  --SAIGEOutputFile /humgen/atgu1/fin/zhangjun/projects/saigeqtl_cell_level_test/outputs/gene_gene_results \
  --use_cell_level_genotype TRUE
```

## Expected Outputs

- VCF + index:
  - `outputs/gene_expr.vcf.gz`
  - `outputs/gene_expr.vcf.gz.csi`
- Step2 result:
  - `outputs/gene_gene_results`
- Step2 log:
  - `outputs/step2.log`

## Required Log Checks

Step2 log must contain:

- `Cell-level genotype mode: using exact Sigma^{-1} projection; variance ratio file is ignored.`

Step2 log must NOT contain:

- `0 samples will be used`

## Important Compatibility Notes

- For cell-level exact mode (`--use_cell_level_genotype TRUE`), Step2 ignores variance-ratio input.
- Keep non-cell-level workflows (legacy variance-ratio paths) validated separately if needed.
- `scripts/expression_matrix_to_vcf.R` expects **cell IDs in the first column**. Use a barcode-first matrix for conversion.

