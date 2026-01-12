# SAIGEQTL

SAIGEQTL is an R package for scalable and accurate expression quantitative trait locus (eQTL) mapping for single-cell studies. It implements a Generalized Poisson mixed model to handle complex data structures and large-scale genomic data.

## Key Features

- **Complex data modeling**: Handles multiple cells per individual and relatedness between individuals
- **Discrete read counts**: Specifically designed for count data from single-cell studies  
- **Scalable analysis**: Efficient for large datasets (20k genes, 200 cell types, millions of cells/variants)
- **Rare variant testing**: Supports both single-variant and gene/region-based tests
- **Cross-platform**: Available via multiple installation methods

## Installation

👉 **See [INSTALLATION.md](INSTALLATION.md) for complete installation guide with platform support**

**Quick Start:**
```bash
# Docker (works on all platforms)
docker run --rm weizhou0/saigeqtl:latest step1_fitNULLGLMM_qtl.R --help
```

## Directory Structure

```
qtl/
├── scripts/          # Installation and build scripts
│   ├── install.R     # Smart installer
│   ├── install_binary.R
│   ├── cluster_install.sh
│   ├── build_*.sh    # Build scripts
│   └── update_version.sh
├── testing/          # Test and validation scripts
│   ├── run_regression_test.sh
│   ├── test_binary_*.sh
│   └── test_package_regression.R
├── config/           # Configuration files
│   ├── pixi-multi-r.toml
│   └── .saigeqtl_config
├── R/               # R source code
├── src/             # C++ source code
├── man/             # Documentation
├── extdata/         # Example data and scripts
└── binaries/        # Pre-built packages
```

## Documentation

- 📖 **User Guide**: https://weizhou0.github.io/SAIGE-QTL-doc/
- 📦 **Installation**: [INSTALLATION.md](INSTALLATION.md)
- 🐛 **Issues**: https://github.com/weizhou0/SAIGEQTL/issues

## Citation

If you use SAIGEQTL in your research, please cite our paper: [Citation details to be added]

## Quick Start

After installation, SAIGEQTL follows a 3-step workflow:

```bash
# Step 1: Fit null model
step1_fitNULLGLMM_qtl.R \
  --plinkFile=data/genotypes \
  --phenoFile=data/phenotypes.txt \
  --phenoCol=trait \
  --outputPrefix=results/step1

# Step 2: Association testing  
step2_tests_qtl.R \
  --vcfFile=data/variants.vcf.gz \
  --GMMATmodelFile=results/step1.rda \
  --varianceRatioFile=results/step1.varianceRatio.txt \
  --SAIGEOutputFile=results/step2.txt

# Step 3: Gene-level p-values
step3_gene_pvalue_qtl.R \
  --assocFile=results/step2.txt \
  --genePval_outputFile=results/gene_pvalues.txt
```

## Installation Validation

Validate your installation:

```bash
# Quick validation
./testing/run_regression_test.sh validate

# Comprehensive validation  
./testing/run_regression_test.sh comprehensive
```
