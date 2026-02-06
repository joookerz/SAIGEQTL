# Gene–Gene Association With SAIGE-QTL

This guide explains how to use **SAIGE-QTL Step2** to regress the expression of one gene (`gene_A`) on the expression of another gene (`gene_B`) at the **cell level**. The core idea is:

1. Fit the usual Step1 null model for `gene_A` (phenotype) and **save cell IDs**.
2. Convert a cell × gene expression matrix (e.g., `gene_B` or multiple genes) into a VCF in which each gene becomes a “variant” and each cell is treated as a “sample”.
3. Run Step2 with `--use_cell_level_genotype TRUE` so SAIGE-QTL uses the per-cell expression vector directly as the design vector `g`.
4. Rescale the Step2 effect size/SE back to the original expression units.

## Prerequisites

- A Step1 null model fitted for `gene_A` with `--cellIDColinphenoFile <column>` so the saved `.rda` contains a `barcode` (one identifier per cell, ordered as in the phenotype file).
- The order of cells in the expression matrix must match that same order, or you must provide `sample-order` to reorder them.
- `bgzip` and `tabix` must be available if you want a compressed/indexed VCF.

## Step 1: Fit the Null Model With Cell IDs

```bash
Rscript extdata/step1_fitNULLGLMM_qtl.R \
  --plinkFile path/to/genotype_prefix \
  --phenoFile expr_geneA.tsv \
  --phenoCol gene_A_expr \
  --covarColList cov1,cov2 \
  --randomEffectColInphenoFile donor_id \
  --cellIDColinphenoFile cell_id \
  --outputPrefix outputs/geneA_null
```

Result: `outputs/geneA_null.rda` (contains `modglmm$barcode`) and `outputs/geneA_null.varianceRatio.txt`.

## Step 2 (Prep): Convert Expression Matrix to VCF

Use `scripts/expression_matrix_to_vcf.R` to turn a cell × gene expression table into a multi-variant VCF whose `DS` values are linearly scaled to `[0,2]`.

```bash
Rscript scripts/expression_matrix_to_vcf.R \
  --expression-matrix expr_matrix.tsv \
  --sample-order cell_ids_in_step1.txt \
  --output-vcf gene_expr.vcf.gz \
  --scaling-info gene_expr_scaling.tsv \
  --scale-mode per_gene \
  --chromosome expr
```

- `expr_matrix.tsv` must have the first column `cell_id` and one column per gene (`gene_B`, …).
- `cell_ids_in_step1.txt` is the ordered list of cells from Step1 (`modglmm$barcode`).
- `gene_expr_scaling.tsv` stores each gene’s min/max for later rescaling.

Each gene becomes one VCF entry; the DS field contains the scaled expression for every cell.

## Step 2: Run SAIGE-QTL With Cell-Level Genotype

```bash
Rscript extdata/step2_tests_qtl.R \
  --vcfFile gene_expr.vcf.gz \
  --vcfField DS \
  --GMMATmodelFile outputs/geneA_null.rda \
  --varianceRatioFile outputs/geneA_null.varianceRatio.txt \
  --SAIGEOutputFile results/geneA_vs_geneB \
  --use_cell_level_genotype TRUE \
  --chrom expr \
  [other standard Step2 options…]
```

Important flags:

- `--use_cell_level_genotype TRUE` tells Step2 that the genotype file already has one sample per cell.
- `--chrom` must match the chromosome label used during conversion (default `expr`).

The output (`results/geneA_vs_geneB.txt`) will include SAIGE’s usual columns (`MarkerID`, `BETA`, `SE`, `p.value`, …) but the effect sizes correspond to the scaled DS values.

## Step 3: Rescale Beta/SE to Original Expression Units

Use `scripts/rescale_saige_results.R` to convert `BETA`/`SE` back to the original expression scale using the min/max table saved earlier.

```bash
Rscript scripts/rescale_saige_results.R \
  --results-file results/geneA_vs_geneB.txt \
  --scaling-info gene_expr_scaling.tsv \
  --output-file results/geneA_vs_geneB_rescaled.txt \
  --marker-column MarkerID \
  --beta-column BETA \
  --se-column SE
```

For each gene:

```
scale_factor = (max_expression - min_expression) / 2
beta_original = beta_scaled / scale_factor
se_original   = se_scaled   / scale_factor
```

`p`-values and z-scores are unaffected by scaling.

## Interpretation / Notes

- The pipeline works for any number of “predictor genes” simultaneously—each column in the expression matrix becomes a variant tested against `gene_A`.
- Because Step2 residualizes the genotype vector against covariates, constant shifts from scaling do not affect the score statistic; only the multiplicative factor needs correction via the rescaling script.
- The same approach can be used to model other continuous cell-level predictors (e.g., ATAC accessibility) by replacing the expression matrix.

## Summary

1. Step1: fit null model with `--cellIDColinphenoFile`, producing `*.rda` + variance ratio.
2. Convert cell × gene matrix to VCF with `scripts/expression_matrix_to_vcf.R`.
3. Run Step2 with `--use_cell_level_genotype TRUE` and the converted VCF.
4. Rescale Step2 outputs using `scripts/rescale_saige_results.R` to interpret beta/SE on the original expression scale.
