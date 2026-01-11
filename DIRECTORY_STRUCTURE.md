# SAIGEQTL Directory Structure

This document explains the organized directory structure of the SAIGEQTL package after reorganization.

## Overview

The package directory has been reorganized from a cluttered root directory (34 files) to a clean, well-organized structure with logical groupings:

```
qtl/
├── scripts/          # Installation and build scripts (9 files)
├── testing/          # Test and validation scripts (6 files)
├── config/           # Configuration files (3 files)
├── R/               # R source code
├── src/             # C++ source code
├── man/             # Package documentation
├── extdata/         # Example data and validation scripts
├── binaries/        # Pre-built binary packages
├── .github/         # CI/CD workflows
└── [core files]     # Essential R package files only
```

## Directory Contents

### `scripts/` - Installation and Build Scripts
**Purpose**: All user-facing installation and developer build scripts

**Contents**:
- `install.R` - Smart installer (auto-detects best method)
- `install_binary.R` - Binary package installer
- `cluster_install.sh` - HPC/cluster installation script
- `build_binary.R` - Build binary packages
- `build_for_multiple_r.sh` - Multi-R version builds
- `build_multi_r_versions.sh` - Automated multi-version builds
- `build_with_current_r.sh` - Single R version build
- `cluster_install.sh` - Cluster-specific installation
- `update_version.sh` - Release automation script

**Usage**:
```bash
# Install from GitHub (most common)
source("https://raw.githubusercontent.com/weizhou0/qtl/main/scripts/install.R")

# Local usage after cloning
Rscript scripts/install_binary.R
./scripts/update_version.sh 0.3.6
```

### `testing/` - Test and Validation Scripts
**Purpose**: All testing, validation, and quality assurance scripts

**Contents**:
- `run_regression_test.sh` - Main testing script (comprehensive validation)
- `test_binary_package.sh` - Test binary package installations
- `test_binary_pixi.sh` - Test pixi-based binary builds
- `test_package_regression.R` - R regression testing framework
- `test_validation_setup.sh` - Setup validation environment
- `config_test.sh` - Configuration testing

**Usage**:
```bash
# Comprehensive testing (recommended after installation)
./testing/run_regression_test.sh comprehensive

# Quick validation
./testing/run_regression_test.sh test

# Binary testing
./testing/test_binary_pixi.sh
```

### `config/` - Configuration Files
**Purpose**: Package configuration and environment setup files

**Contents**:
- `pixi-multi-r.toml` - Multi-R version pixi configuration
- `.saigeqtl_config` - Package-specific configuration
- `configure.win` - Windows-specific build configuration

**Usage**:
These files are used automatically by build and test scripts. Users typically don't need to modify them directly.

### Core Package Directories

#### `R/` - R Source Code
- Contains all R functions and methods
- Main package functionality

#### `src/` - C++ Source Code  
- C++ implementation for performance-critical functions
- Rcpp integration code

#### `man/` - Documentation
- Generated R documentation files
- Function help pages

#### `extdata/` - Example Data and Scripts
- Example datasets for testing
- User tutorial scripts
- `INSTALLATION_VALIDATION.md` - Validation instructions

#### `binaries/` - Pre-built Packages
- Pre-compiled binary packages for multiple platforms
- Automatically built by CI/CD
- Used by binary installation methods

## Key Script Locations Quick Reference

| Purpose | Location | Usage |
|---------|----------|-------|
| **Installation** | `scripts/install.R` | `source("https://github.com/.../scripts/install.R")` |
| **Binary Install** | `scripts/install_binary.R` | `Rscript scripts/install_binary.R` |
| **Testing** | `testing/run_regression_test.sh` | `./testing/run_regression_test.sh comprehensive` |
| **Validation** | `extdata/INSTALLATION_VALIDATION.md` | Documentation |
| **Release** | `scripts/update_version.sh` | `./scripts/update_version.sh 0.3.6` |
| **Config** | `config/*.toml` | Auto-used by scripts |

## Benefits of New Organization

### For Users:
1. **Clear Installation**: Know exactly where to find installation scripts
2. **Easy Testing**: All validation in one place (`testing/`)
3. **Clean Root**: Easier to navigate, only essential files visible
4. **Logical Grouping**: Related files grouped together

### For Developers:
1. **Maintainable**: Easy to find and update specific types of scripts
2. **Scalable**: Can add new scripts without cluttering root directory
3. **Professional**: Follows standard project organization practices
4. **CI/CD Friendly**: Clear separation of automation scripts

### For Contributors:
1. **Intuitive**: Easy to understand where different files belong
2. **Consistent**: Follows common open-source project patterns
3. **Documented**: Clear purpose for each directory
4. **Organized**: Reduces cognitive load when contributing

## Migration Notes

If you have local scripts or workflows that reference the old file locations, update them as follows:

**Old → New**:
```bash
# Old locations
./run_regression_test.sh          → ./testing/run_regression_test.sh
./install_binary.R                → ./scripts/install_binary.R  
./update_version.sh               → ./scripts/update_version.sh
./test_binary_pixi.sh             → ./testing/test_binary_pixi.sh

# GitHub URLs automatically updated in documentation
```

All documentation (README.md, INSTALLATION.md) has been updated with the new paths.