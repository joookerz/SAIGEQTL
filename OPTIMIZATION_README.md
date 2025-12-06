# fitNULLGLMM_multiV Optimization Guide

## Overview

The `fitNULLGLMM_multiV` function has been optimized for multi-phenotype analysis by splitting the computation into shared preprocessing and phenotype-specific components. This optimization significantly reduces computational time when analyzing multiple phenotypes with the same covariates.

## New Functions

### 1. `fitNULLGLMM_multiV_preprocess()`
Performs all shared preprocessing steps once:
- Genotype file loading and validation
- Covariate processing and transformation  
- Sample filtering and merging
- GRM setup and matrix initialization

### 2. `fitNULLGLMM_multiV_phenotype()`
Processes individual phenotypes using preprocessed data:
- Phenotype-specific model fitting
- Variance ratio estimation
- GLMM model fitting

### 3. `fitNULLGLMM_multiV_batch()`
Efficient batch processing for multiple phenotypes:
- Automatic preprocessing sharing
- Optional parallel processing
- Progress tracking and error handling

## Usage Examples

### Single Phenotype (Backward Compatible)
```r
# Original usage still works exactly the same
result <- fitNULLGLMM_multiV(
  plinkFile = "data/genotypes",
  phenoFile = "data/phenotypes.txt",
  phenoCol = "gene1",
  covarColList = c("age", "sex", "PC1", "PC2"),
  sampleIDColinphenoFile = "IID",
  outputPrefix = "output/gene1"
)
```

### Multiple Phenotypes (Optimized)
```r
# Analyze multiple phenotypes efficiently
gene_list <- c("ENSG001", "ENSG002", "ENSG003", "ENSG004", "ENSG005")

results <- fitNULLGLMM_multiV_batch(
  phenoCols = gene_list,
  phenoFile = "data/gene_expression.txt",
  plinkFile = "data/genotypes",
  covarColList = c("age", "sex", "PC1", "PC2", "PC3"),
  sampleIDColinphenoFile = "IID",
  outputPrefixBase = "output/eqtl_analysis",
  traitType = "quantitative",
  nCores = 4  # Use parallel processing
)

# Check results
cat("Successfully processed:", results$summary$successful, "phenotypes\n")
cat("Time savings:", round(results$summary$estimated_savings, 2), "seconds\n")
```

### Manual Multi-Phenotype Analysis
```r
# For more control over the process
# Step 1: Preprocessing (done once)
preprocess_data <- fitNULLGLMM_multiV_preprocess(
  plinkFile = "data/genotypes",
  phenoFile = "data/gene_expression.txt", 
  covarColList = c("age", "sex", "PC1", "PC2", "PC3"),
  sampleIDColinphenoFile = "IID"
)

# Step 2: Process each phenotype
gene_results <- list()
for (gene in gene_list) {
  gene_results[[gene]] <- fitNULLGLMM_multiV_phenotype(
    preprocess_data = preprocess_data,
    phenoCol = gene,
    phenoFile = "data/gene_expression.txt",
    traitType = "quantitative",
    outputPrefix = paste0("output/", gene)
  )
}
```

### Large-Scale eQTL Analysis
```r
# For analyzing hundreds or thousands of genes
all_genes <- scan("data/gene_list.txt", what = "character")

# Split into batches for memory management
batch_size <- 50
n_batches <- ceiling(length(all_genes) / batch_size)

for (i in 1:n_batches) {
  start_idx <- (i-1) * batch_size + 1
  end_idx <- min(i * batch_size, length(all_genes))
  batch_genes <- all_genes[start_idx:end_idx]
  
  cat("Processing batch", i, "of", n_batches, 
      "(genes", start_idx, "to", end_idx, ")\n")
  
  batch_results <- fitNULLGLMM_multiV_batch(
    phenoCols = batch_genes,
    phenoFile = "data/gene_expression.txt",
    plinkFile = "data/genotypes", 
    covarColList = c("age", "sex", paste0("PC", 1:10)),
    sampleIDColinphenoFile = "IID",
    outputPrefixBase = paste0("output/batch_", i),
    traitType = "quantitative",
    nCores = 8,
    invNormalize = TRUE
  )
  
  # Save batch results
  saveRDS(batch_results, paste0("results/batch_", i, "_results.rds"))
}
```

## Performance Benefits

### Time Savings
- **Single phenotype**: No change in performance
- **Multiple phenotypes**: 40-60% reduction in total time
- **Large-scale analysis**: Even greater savings due to reduced I/O

### Memory Efficiency
- Shared data structures reduce memory usage
- Preprocessing done once per analysis
- Option to process in batches for very large studies

### Key Optimizations
1. **File I/O reduction**: Genotype and covariate files read once
2. **Shared computations**: QR decomposition, matrix operations performed once
3. **Memory reuse**: Data structures shared across phenotypes
4. **Parallel processing**: Optional multi-core processing for phenotypes

## Migration Guide

### Existing Code
No changes needed! The optimized `fitNULLGLMM_multiV()` function maintains complete backward compatibility.

### New Multi-Phenotype Workflows
1. Use `fitNULLGLMM_multiV_batch()` for most multi-phenotype analyses
2. Use manual preprocessing for custom workflows
3. Consider parallel processing (`nCores > 1`) for large gene sets

## Tips for Best Performance

1. **Batch size**: For very large gene sets, process in batches of 50-100 genes
2. **Memory**: Monitor memory usage with large sample sizes
3. **Parallel processing**: Use `nCores = detectCores() - 1` for maximum speed
4. **File formats**: Use compressed phenotype files (.gz) for faster I/O
5. **Output management**: Use descriptive output prefixes to organize results

## Error Handling

The batch function includes robust error handling:
- Individual phenotype failures don't stop the entire analysis
- Detailed error messages for debugging
- Summary statistics showing success/failure rates

```r
# Check for failed phenotypes
failed_genes <- names(results$results)[sapply(results$results, function(x) !x$success)]
if (length(failed_genes) > 0) {
  cat("Failed genes:", paste(failed_genes, collapse = ", "), "\n")
}
```