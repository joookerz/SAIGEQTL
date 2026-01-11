# SAIGEQTL

SAIGEQTL is an R package for scalable and accurate expression quantitative trait locus (eQTL) mapping for single-cell studies. It implements a Generalized Poisson mixed model to handle complex data structures and large-scale genomic data.

## Key Features

- **Complex data modeling**: Handles multiple cells per individual and relatedness between individuals
- **Discrete read counts**: Specifically designed for count data from single-cell studies  
- **Scalable analysis**: Efficient for large datasets (20k genes, 200 cell types, millions of cells/variants)
- **Rare variant testing**: Supports both single-variant and gene/region-based tests
- **Cross-platform**: Available via multiple installation methods

## Quick Installation

**🐳 Docker (Easiest - Any System):**
```bash
docker run --rm weizhou0/saigeqtl:latest step1_fitNULLGLMM_qtl.R --help
```

**📦 Conda (Easy - Cross-Platform):**
```bash
conda install -c aryarm r-saigeqtl
```

**⚡ Binary (Fast - Linux):**
```bash
git clone https://github.com/weizhou0/qtl.git && cd qtl
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.bashrc
BINARY_FILE=$(ls binaries/SAIGEQTL_*_linux-x86_64.tgz | head -n1)
CONDA_OVERRIDE_GLIBC=2.28 pixi run R -e "install.packages('${BINARY_FILE}', repos=NULL, type='source')"
```
*⏱️ Note: First pixi run takes ~15 minutes (downloads 262 packages), future runs are instant*

**📋 R Package:**
```r
remotes::install_github("weizhou0/qtl")
```

**🎯 Custom Installation Path:**
```bash
# Install to specific directory (for HPC, shared systems)
Rscript scripts/install_binary.R /path/to/your/R/library

# Then use with --library option:
step1_fitNULLGLMM_qtl.R --library='/path/to/your/R/library' [options]
```

👉 **See [INSTALLATION.md](INSTALLATION.md) for complete guide | [CUSTOM_LIBRARY_PATHS.md](CUSTOM_LIBRARY_PATHS.md) for custom paths**

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
- 🐛 **Issues**: https://github.com/weizhou0/qtl/issues

## Citation

If you use SAIGEQTL in your research, please cite our paper: [Citation details to be added]

## Installation

### Quick Start (Most Users)

```r
# Install using smart installer (auto-detects best method)
source("https://raw.githubusercontent.com/weizhou0/qtl/main/scripts/install.R")
```

### Manual Installation Methods

**Method 1: Pre-compiled Binary (Fastest, No Compilation Required)**
```r
# Download and install pre-compiled binary for your platform
source("https://raw.githubusercontent.com/weizhou0/qtl/main/scripts/install_binary.R")
```

**Method 2: Standard GitHub Installation**
```r
# Requires: R >= 3.5, C++ compiler, BLAS/LAPACK libraries
if (!require("remotes")) install.packages("remotes")
remotes::install_github("weizhou0/qtl")
```

**Method 3: HPC/Cluster Installation (Recommended for clusters without compilers)**
```bash
# Download and run pixi-based installer
curl -fsSL https://raw.githubusercontent.com/weizhou0/qtl/main/scripts/cluster_install.sh | bash
```

**Method 4: Docker Installation (If all else fails)**
```bash
docker pull weizhou0/saigeqtl
docker run -it --rm -v $(pwd):/data weizhou0/saigeqtl R
```

### Pre-compiled Binary Availability

Binaries are automatically built for:
- **Linux**: Ubuntu 20.04/22.04 (x86_64) - R 4.1, 4.2, 4.3
- **macOS**: Intel and Apple Silicon (M1/M2) - R 4.1, 4.2, 4.3  
- **Windows**: 64-bit - R 4.1, 4.2, 4.3

Download directly from [GitHub Releases](https://github.com/weizhou0/qtl/releases/latest) or use the binary installer above.

### System Requirements

- **R**: Version 3.5.0 or higher
- **Compiler**: GCC/Clang with C++14 support (for source installation)
- **Libraries**: BLAS/LAPACK (automatically detected by R)
- **Memory**: 8GB+ RAM recommended for large datasets
- **Storage**: 2GB+ free space for dependencies

### Troubleshooting Installation

**Compiler Issues:**
```bash
# Ubuntu/Debian
sudo apt-get install build-essential libopenblas-dev liblapack-dev

# CentOS/RHEL/HPC clusters
sudo yum groupinstall 'Development Tools'
sudo yum install openblas-devel lapack-devel

# macOS
xcode-select --install
```

**HPC/Cluster Users:** Many HPC systems lack proper compilers. Use Method 2 or contact your system administrator.

## Installation Validation

After installing SAIGEQTL, validate your installation by running the regression test:

```bash
# Quick validation (PLINK format)  
./testing/run_regression_test.sh validate

# Comprehensive validation (all formats)
./testing/run_regression_test.sh comprehensive
```

This will test the complete workflow and compare results against reference outputs to ensure your installation is working correctly.

For detailed validation instructions, see `extdata/INSTALLATION_VALIDATION.md`.
