#!/usr/bin/env Rscript
# Convert a cell-by-gene expression matrix into a multi-variant VCF that can
# be used as "genotype" input for SAIGE-QTL Step2 (with --use_cell_level_genotype).

suppressPackageStartupMessages({
  library(optparse)
  library(data.table)
})

option_list <- list(
  make_option("--expression-matrix", type = "character",
              help = "TSV/CSV file; first column is cell_id, remaining columns are genes."),
  make_option("--sample-order", type = "character",
              help = "Text file listing cell IDs in the exact Step1 order (one per line)."),
  make_option("--output-vcf", type = "character",
              help = "Output .vcf or .vcf.gz path."),
  make_option("--chromosome", type = "character", default = "expr",
              help = "Chromosome string to use in the synthetic VCF [default=expr]."),
  make_option("--reference-allele", type = "character", default = "A",
              help = "REF allele symbol used in the VCF [default=A]."),
  make_option("--alternate-allele", type = "character", default = "T",
              help = "ALT allele symbol used in the VCF [default=T]."),
  make_option("--scale-mode", type = "character", default = "none",
              help = "none (raw expression), per_gene, or global scaling [default=none]."),
  make_option("--global-min", type = "double", default = NA,
              help = "Optional global minimum for scaling (used when scale-mode=global)."),
  make_option("--global-max", type = "double", default = NA,
              help = "Optional global maximum for scaling."),
  make_option("--compress", type = "character", default = "bgzip",
              help = "Compression method: bgzip, gzip, or none [default=bgzip]."),
  make_option("--scaling-info", type = "character", default = NA,
              help = "Optional TSV to save per-gene/global scaling factors.")
)

opt <- parse_args(OptionParser(option_list = option_list))
required <- c("expression_matrix", "sample_order", "output_vcf")
if (any(is.na(opt[required]))) stop("Missing required argument(s): ", paste(required[is.na(opt[required])], collapse = ", "))

expr_dt <- fread(opt$`expression-matrix`, header = TRUE)
if (ncol(expr_dt) < 2) stop("expression-matrix must contain cell_id plus at least one gene column")
if (!tolower(names(expr_dt)[1]) %in% c("cell_id", "cellid", "barcode")) {
  warning("Treating first column as cell_id; rename before running if needed.")
}
setnames(expr_dt, names(expr_dt)[1], "cell_id")

genes <- setdiff(names(expr_dt), "cell_id")
if (length(genes) == 0) stop("No gene columns detected")

sample_order <- fread(opt$`sample-order`, header = FALSE)$V1
if (length(sample_order) == 0) stop("sample-order file is empty")
expr_dt <- expr_dt[match(sample_order, expr_dt$cell_id), ]
if (any(is.na(expr_dt$cell_id))) stop("Some IDs in sample-order are missing from expression-matrix")

expr_mat <- as.matrix(expr_dt[, ..genes])
mode(expr_mat) <- "numeric"

scale_to_unit <- function(values, minv, maxv) {
  if (maxv <= minv) {
    return(rep(1, length(values)))
  }
  out <- (values - minv) / (maxv - minv)
  out[out < 0] <- 0
  out[out > 1] <- 1
  out
}

scaled_mat <- matrix(NA_real_, nrow = nrow(expr_mat), ncol = ncol(expr_mat))
colnames(scaled_mat) <- genes
scale_df <- data.table(gene = genes, min = NA_real_, max = NA_real_)

if (opt$`scale-mode` == "global") {
  gmin <- if (is.na(opt$`global-min`)) min(expr_mat) else opt$`global-min`
  gmax <- if (is.na(opt$`global-max`)) max(expr_mat) else opt$`global-max`
  scaled_mat <- 2 * scale_to_unit(expr_mat, gmin, gmax)
  scale_df[, `:=`(min = gmin, max = gmax)]
} else if (opt$`scale-mode` == "per_gene") {
  for (j in seq_along(genes)) {
    vals <- expr_mat[, j]
    gmin <- min(vals)
    gmax <- max(vals)
    scaled_mat[, j] <- 2 * scale_to_unit(vals, gmin, gmax)
    scale_df[j, `:=`(min = gmin, max = gmax)]
  }
} else if (opt$`scale-mode` == "none") {
  scaled_mat <- expr_mat
  scale_df[, `:=`(min = NA_real_, max = NA_real_)]
} else {
  stop("scale-mode must be 'per_gene', 'global', or 'none'")
}

# Prepare VCF header
sample_header <- paste(sample_order, collapse = "\t")
format_desc <- if (opt$`scale-mode` == "none") {
  "Raw expression values (no scaling applied)"
} else {
  "Scaled expression in [0,2]"
}
vcf_header <- c(
  "##fileformat=VCFv4.2",
  paste0("##FORMAT=<ID=DS,Number=1,Type=Float,Description=\"", format_desc, "\">"),
  paste0("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t", sample_header)
)

tmp_vcf <- tempfile(fileext = ".vcf")
con <- file(tmp_vcf, open = "wt")
writeLines(vcf_header, con)

ref <- opt$`reference-allele`
alt <- opt$`alternate-allele`
chrom <- opt$chromosome
for (idx in seq_along(genes)) {
  pos <- idx
  gene <- genes[idx]
  variant_id <- paste0(gene)
  variant_full <- paste0(chrom, ":", pos, "_", ref, "/", alt)
  ds_values <- paste(sprintf("%.6f", scaled_mat[, idx]), collapse = "\t")
  line <- paste0(chrom, "\t", pos, "\t", variant_id, "\t", ref, "\t", alt,
                 "\t.\tPASS\t.\tDS\t", ds_values)
  writeLines(line, con)
}
close(con)

out_path <- opt$`output-vcf`
compress <- tolower(opt$compress)
if (compress == "bgzip") {
  system2("bgzip", c("-c", tmp_vcf), stdout = out_path)
  system2("tabix", c("-f", "-p", "vcf", out_path))
} else if (compress == "gzip") {
  system2("gzip", c("-c", tmp_vcf), stdout = out_path)
} else {
  file.copy(tmp_vcf, out_path, overwrite = TRUE)
}

if (!is.na(opt$`scaling-info`)) {
  fwrite(scale_df, opt$`scaling-info`, sep = "\t")
}
cat("VCF written to", out_path, "with", length(genes), "variants.\n")
if (opt$`scale-mode` != "none") {
  scale_factor_note <- if (opt$`scale-mode` == "global") {
    "global factor = (max-min)/2"
  } else {
    "per-gene factors saved in scaling-info"
  }
  cat("Remember to rescale Step2 beta/SE by (max-min)/2 for each gene (", scale_factor_note, ").\n")
} else {
  cat("Raw expression values stored in DS; no rescaling needed.\n")
}
