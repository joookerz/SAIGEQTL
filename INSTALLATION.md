# SAIGEQTL Installation Guide

SAIGEQTL is an R package for scalable and accurate expression quantitative trait locus (eQTL) mapping for single-cell studies. This guide provides multiple installation methods ordered from easiest to most complex.

## Quick Start (Ordered by Ease of Use)

**🥇 Easiest: Docker (zero setup, any system):**
```bash
# Just need Docker - everything else is included
docker run --rm -v $(pwd):/data weizhou0/saigeqtl:latest step1_fitNULLGLMM_qtl.R --help
```

**🥈 Easy: Binary (Linux only, no compilation):**
```bash
# Fast installation for Linux with pixi
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.bashrc
git clone https://github.com/weizhou0/qtl.git && cd qtl

# Auto-detect latest binary file
BINARY_FILE=$(ls binaries/SAIGEQTL_*_linux-x86_64.tgz | head -n1)
CONDA_OVERRIDE_GLIBC=2.28 pixi run R -e "install.packages('${BINARY_FILE}', repos=NULL, type='source'); library(SAIGEQTL)"
```

**🥉 Moderate: Conda/Bioconda (any system, managed environment):**
```bash
# Conda handles all dependencies automatically
conda install -c aryarm r-saigeqtl
```

**🔧 Moderate: Pixi Source (any system, managed environment):**
```bash
# Pixi handles all dependencies (R, compiler, libraries)
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.bashrc
git clone https://github.com/weizhou0/qtl.git && cd qtl
pixi run install-standard
```

**🔧 Advanced: R remotes (requires system setup):**
```r
# Uses your R + compiler - potential dependency conflicts
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("weizhou0/qtl", dependencies = TRUE)
```

## Installation Methods (Easiest to Most Complex)

### Method 1: Docker Container (🥇 Easiest - Zero Setup)

**Advantages:**
- ✅ **No installation required - runs directly**
- ✅ **Works on any system with Docker**
- ✅ **Completely isolated environment**
- ✅ **No dependency conflicts**
- ✅ **Consistent across all platforms**
- ✅ **Includes all tools and test data**

**System Requirements:**
- Docker installed on your system
- No other requirements

**Installation and Usage:**
```bash
# Quick test - verify Docker image works
docker run --rm weizhou0/saigeqtl:latest step1_fitNULLGLMM_qtl.R --help

# Run analysis with your data (mount current directory)
docker run --rm -v $(pwd):/data weizhou0/saigeqtl:latest \
  step1_fitNULLGLMM_qtl.R \
  --plinkFile=/data/your_genotypes \
  --phenoFile=/data/your_phenotypes.txt \
  --outputPrefix=/data/results

# Interactive R session with SAIGEQTL loaded
docker run --rm -it -v $(pwd):/data weizhou0/saigeqtl:latest \
  pixi run R

# Available commands in container:
# - step1_fitNULLGLMM_qtl.R
# - step2_tests_qtl.R  
# - step3_gene_pvalue_qtl.R
# - makeGroupFile.R
```

**Docker Image Details:**
- **Image:** `weizhou0/saigeqtl:latest`
- **Base:** Ubuntu 20.04 with pixi environment
- **Size:** ~2GB (includes R, dependencies, and tools)
- **Updates:** Automatically built from latest code

### Method 2: Binary Installation (🥈 Easy - Linux Only)

**Advantages:**
- ✅ **Fastest installation (no compilation required)**
- ✅ **No compiler or build tools needed**
- ✅ **Avoids common compilation errors**
- ✅ Pre-built optimized binaries
- ✅ Consistent environment
- ✅ Works on most modern Linux systems

**System Requirements:**
- Linux x86_64
- R 4.4+
- GLIBC 2.28+ (CentOS 7+, Ubuntu 18.04+, most modern systems)
- Pixi package manager

**Installation:**
```bash
# 1. Install pixi if not available
curl -fsSL https://pixi.sh/install.sh | bash
source ~/.bashrc  # Restart shell or reload environment

# 2. Clone repository
git clone https://github.com/weizhou0/qtl.git
cd qtl

# 3. Install from pre-built binary (auto-detect latest version)
BINARY_FILE=$(ls binaries/SAIGEQTL_*_linux-x86_64.tgz | head -n1)
echo "Installing: $BINARY_FILE"

CONDA_OVERRIDE_GLIBC=2.28 pixi run R -e "
install.packages('${BINARY_FILE}', repos = NULL, type = 'source')
library(SAIGEQTL)
cat('✓ SAIGEQTL', as.character(packageVersion('SAIGEQTL')), 'installed successfully\n')
"
```

**Alternative: One-liner for Binary Installation**
```bash
# One-liner that clones repo and installs latest binary
git clone https://github.com/weizhou0/qtl.git && cd qtl && \
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.bashrc && \
BINARY_FILE=$(ls binaries/SAIGEQTL_*_linux-x86_64.tgz | head -n1) && \
CONDA_OVERRIDE_GLIBC=2.28 pixi run R -e "install.packages('${BINARY_FILE}', repos=NULL, type='source')"
```

**Custom Installation Path:**
```bash
# Install to specific directory (for HPC, shared systems)
Rscript scripts/install_binary.R /path/to/your/R/library

# Example: Install to home directory
Rscript scripts/install_binary.R ~/R-packages/

# Then use with --library option in analysis:
step1_fitNULLGLMM_qtl.R --library='/path/to/your/R/library' [other_options]
step2_tests_qtl.R --library='/path/to/your/R/library' [other_options]
step3_gene_pvalue_qtl.R --library='/path/to/your/R/library' [other_options]
```

**Version Update Notes:**
- The auto-detection method (`ls binaries/SAIGEQTL_*_linux-x86_64.tgz`) automatically finds any version
- No need to update documentation when binary versions change
- Always installs the latest available binary in the repository

### Method 3: Conda/Bioconda Installation (🥉 Easy - Any System)

**Advantages:**
- ✅ **Automatic dependency management**
- ✅ **No compilation required**
- ✅ **Works on any system with conda**
- ✅ **Cross-platform (Linux, macOS, Windows)**
- ✅ **Isolated environment management**
- ✅ **Fast installation**

**System Requirements:**
- Conda or Mamba package manager
- No R installation required (conda provides R)

**Installation:**
```bash
# Option 1: If you have conda/mamba installed
conda install -c aryarm r-saigeqtl

# Option 2: Create new environment with SAIGEQTL
conda create -n saigeqtl -c aryarm r-saigeqtl
conda activate saigeqtl

# Option 3: If you don't have conda, install miniconda first
curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b
~/miniconda3/bin/conda install -c aryarm r-saigeqtl
```

**Usage:**
```bash
# Activate environment (if using option 2)
conda activate saigeqtl

# Use R with SAIGEQTL
R -e "library(SAIGEQTL)"

# Use command-line tools
step1_fitNULLGLMM_qtl.R --help
step2_tests_qtl.R --help
```

### Method 4: Pixi Source Installation (🔧 Moderate - Any System)

**How it works:** Download source code manually, use pixi to manage all dependencies and compilation

**Advantages:**
- ✅ **Complete environment isolation - no dependency conflicts**
- ✅ **All dependencies managed by pixi (R, compiler, libraries)**
- ✅ **Reproducible builds across systems**
- ✅ **Optimized performance libraries**
- ✅ **No system compiler/library requirements**
- ✅ **Always works if pixi is available**

**Disadvantages:**
- ❌ Requires pixi installation
- ❌ Manual source code download
- ❌ Larger disk space (pixi environment)

**System Requirements:**
- **Pixi package manager only**
- **No R, compiler, or libraries needed on your system**

**Installation:**
```bash
# 1. Install pixi
curl -fsSL https://pixi.sh/install.sh | bash
source ~/.bashrc

# 2. Download source code
git clone https://github.com/weizhou0/qtl.git
cd qtl

# 3. Install with pixi-managed environment
# Default installation (to pixi's R library):
pixi run install-standard

# Custom installation path (optional):
export SAIGEQTL_LIB_PATH="/path/to/your/custom/R/library"
pixi run install-standard

# Test installation
pixi run R -e "library(SAIGEQTL); packageVersion('SAIGEQTL')"
```

**Custom Library Path:**
- Set `SAIGEQTL_LIB_PATH` environment variable to specify a custom installation directory
- If not set, installs to the default R library path within the pixi environment
- Useful for shared systems or when you need packages in a specific location

```bash
# Example: Install to a custom directory
export SAIGEQTL_LIB_PATH="$HOME/R-packages"
mkdir -p "$SAIGEQTL_LIB_PATH"
pixi run install-standard

# To use the custom library, add it to R's library path:
pixi run R -e ".libPaths('$HOME/R-packages'); library(SAIGEQTL)"
```

### Method 5: R remotes Installation (🔧 Advanced - System Dependencies)

**How it works:** R automatically downloads source from GitHub, uses your system's dependencies

**Advantages:**
- ✅ Works on all R platforms  
- ✅ Automatic R dependency management via CRAN
- ✅ No manual source code download
- ✅ Always gets latest version
- ✅ Integrates with existing R environment

**Disadvantages:**
- ❌ **Requires C++ compiler setup on your system**
- ❌ **Can fail due to missing system libraries**
- ❌ **Dependency version conflicts with your R environment**
- ❌ Slower installation (compilation time)
- ❌ Complex troubleshooting on older systems

**System Requirements:**
- R (>= 3.5.0) 
- C/C++ compiler (gcc/clang with C++11 support)
- BLAS/LAPACK libraries (automatically detected by R)
- OpenMP (optional, for parallel processing)
- **Compatible versions of all R dependencies in your environment**

**Installation:**
```r
# Install using remotes package
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("weizhou0/qtl", dependencies = TRUE)

# Test installation
library(SAIGEQTL)
packageVersion("SAIGEQTL")
```

### Method 6: Automated Script (🔧 Advanced - Wrapper for remotes)

**Advantages:**
- ✅ Guided installation with dependency checking
- ✅ Automatic environment validation
- ✅ Helpful error messages

**Installation:**
```bash
# Download and run the automated installer
wget https://raw.githubusercontent.com/weizhou0/qtl/main/scripts/install_standard.R
Rscript scripts/install_standard.R
```

### Method 7: Development Installation (🔧🔧 Most Complex - For Contributors)

**For contributors or users needing the latest development version:**

```bash
# Clone and install from source
git clone https://github.com/weizhou0/qtl.git
cd qtl
Rscript scripts/install_standard.R --dev
```

## Verification

### For Local Installations (Methods 2-7):

```r
# Load the package
library(SAIGEQTL)

# Check version
cat("SAIGEQTL version:", as.character(packageVersion("SAIGEQTL")), "\n")

# Check main functions are available
main_functions <- c("fitNULLGLMM_multiV", "SPAGMMATtest")
for (func in main_functions) {
  if (exists(func)) {
    cat("✓", func, "available\n")
  } else {
    cat("✗", func, "missing\n")
  }
}

# Check total functions
cat("Total functions:", length(ls("package:SAIGEQTL")), "\n")
```

### For Docker Installation (Method 1):

```bash
# Test Docker image functionality
docker run --rm weizhou0/saigeqtl:latest step1_fitNULLGLMM_qtl.R --help
docker run --rm weizhou0/saigeqtl:latest step2_tests_qtl.R --help

# Test R package in container
docker run --rm weizhou0/saigeqtl:latest pixi run R -e "
library(SAIGEQTL)
cat('SAIGEQTL version:', as.character(packageVersion('SAIGEQTL')), '\n')
"
```

Expected output:
```
SAIGEQTL version: 0.3.4
✓ fitNULLGLMM_multiV available
✓ SPAGMMATtest available
Total functions: 257
```

## Troubleshooting

### Common Source Installation Issues

**1. Compilation errors (missing/outdated compiler):**
```bash
# Ubuntu/Debian - install build tools:
sudo apt update && sudo apt install build-essential r-base-dev

# CentOS/RHEL - install development tools:
sudo yum groupinstall "Development Tools"
sudo yum install R-devel

# macOS - install Xcode command line tools:
xcode-select --install
```

**⚠️ Recommendation: If you encounter compiler issues, use Method 1 (Docker) or Method 2 (Binary) instead!**

**2. Missing dependencies:**
```r
# Install missing dependencies manually
install.packages(c("Matrix", "data.table", "Rcpp", "RcppArmadillo"))
```

**3. Permission errors:**
```bash
# Install to user library instead
R -e "install.packages('remotes', lib = '~/R-library')"
R -e "remotes::install_github('weizhou0/qtl', lib = '~/R-library')"
```

**4. Binary installation fails:**
- Ensure you have R 4.4+: `R --version`
- Check GLIBC version: `ldd --version`
- **Check binary file exists**: `ls binaries/SAIGEQTL_*_linux-x86_64.tgz`
- **For version updates**: The auto-detection should find the latest binary automatically
- Use Method 1 (Docker) or Method 3 (Conda) as fallback

**5. All installation methods fail:**
- **Use Method 1 (Docker) - guaranteed to work on any system with Docker**
- No local dependencies, compilers, or libraries needed

### Getting Help

- **Documentation:** https://weizhou0.github.io/SAIGE-QTL-doc/
- **Issues:** https://github.com/weizhou0/qtl/issues
- **Examples:** See `extdata/` directory in the package

## System Requirements Summary

| Method | Type | OS | R Version | Additional Requirements |
|--------|------|----|-----------|-----------------------|
| Method 1 (Docker) | **Container** | **Any** | **Built-in** | **Docker only** |
| Method 2 (Binary) | **Pre-built** | Linux x86_64 | ≥ 4.4 **managed** | Pixi, GLIBC ≥ 2.28 |
| Method 3 (Conda) | **Pre-built** | **Any** | **Managed by conda** | **Conda/Mamba only** |
| Method 4 (Pixi Source) | Source (manual) | Any | **Managed by pixi** | **Pixi only** (includes R + compiler) |
| Method 5 (R remotes) | Source (auto) | Any | ≥ 3.5.0 **on system** | **System:** C++ compiler, BLAS/LAPACK |
| Method 6 (Script) | Source (auto) | Any | ≥ 3.5.0 **on system** | wget/curl |
| Method 7 (Dev) | Source (manual) | Any | ≥ 3.5.0 **on system** | git, **system** C++ compiler |

## Quick Reference

```bash
# Docker (zero setup, any system) - RECOMMENDED
docker run --rm weizhou0/saigeqtl:latest step1_fitNULLGLMM_qtl.R --help

# Conda (easy, cross-platform)
conda install -c aryarm r-saigeqtl

# Binary installation (fastest for Linux)
git clone https://github.com/weizhou0/qtl.git && cd qtl
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.bashrc
BINARY_FILE=$(ls binaries/SAIGEQTL_*_linux-x86_64.tgz | head -n1)
CONDA_OVERRIDE_GLIBC=2.28 pixi run R -e "install.packages('${BINARY_FILE}', repos=NULL, type='source'); library(SAIGEQTL)"

# Standard installation (source compilation)
R -e "if (!require('remotes')) install.packages('remotes'); remotes::install_github('weizhou0/qtl')"
```

## Directory Structure

After installation, you'll find scripts organized in these directories:

```
qtl/
├── scripts/          # Installation and build scripts
│   ├── install.R     # Smart installer (use via GitHub URL)
│   ├── install_binary.R
│   ├── cluster_install.sh
│   └── build_*.sh    # Build scripts
├── testing/          # Test and validation scripts
│   ├── run_regression_test.sh  # Main validation script
│   ├── test_binary_*.sh
│   └── test_package_regression.R
├── config/           # Configuration files
│   ├── pixi-multi-r.toml
│   └── .saigeqtl_config
└── extdata/          # Example data and documentation
    └── INSTALLATION_VALIDATION.md
```

**Key Script Locations:**
- **Testing**: `./testing/run_regression_test.sh comprehensive`
- **Validation**: See `extdata/INSTALLATION_VALIDATION.md`
- **Build scripts**: Located in `scripts/` directory
- **Custom paths**: See [CUSTOM_LIBRARY_PATHS.md](CUSTOM_LIBRARY_PATHS.md) for detailed guide

**Using Custom Installation Paths:**
```bash
# For HPC, shared systems, or when you need specific locations
Rscript scripts/install_binary.R /your/custom/path

# Use with analysis commands:
step1_fitNULLGLMM_qtl.R --library='/your/custom/path' --plinkFile=data/geno
step2_tests_qtl.R --library='/your/custom/path' --vcfFile=data/variants.vcf
step3_gene_pvalue_qtl.R --library='/your/custom/path' --inputFile=results.txt
```

Choose the method that best fits your environment and requirements!

**Recommendation Order:**
1. Try **Docker** first (works everywhere)
2. Try **Conda** (easy, cross-platform)
3. If on Linux, try **Binary** (fastest local install)
4. If you need isolation, try **Pixi Source**
5. As last resort, try **R remotes** (potential issues)