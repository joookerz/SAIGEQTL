SAIGE-QTL is an R package developed with Rcpp for scalable and accurate expression quantitative trait locus mapping for single-cell studies 

The method
- Model repeat and complex data structure, due to multiple cells per individual and relatedness between individuals 
- Model discrete read counts
- Fast and scalable for large data, test 20k genes, 200 cell types, millions of cells, millions of variants
- Test rare variations. Single-variant test is underpowered

Please see [https://weizhou0.github.io/SAIGE-QTL-doc/](https://weizhou0.github.io/SAIGE-QTL-doc/) for how to run SAIGE-QTL.

## Installation Validation

After installing SAIGEQTL, validate your installation by running the regression test:

```bash
# Quick validation (PLINK format)
./run_regression_test.sh validate

# Comprehensive validation (all formats)
./run_regression_test.sh comprehensive
```

This will test the complete workflow and compare results against reference outputs to ensure your installation is working correctly.

For detailed validation instructions, see `extdata/INSTALLATION_VALIDATION.md`.
