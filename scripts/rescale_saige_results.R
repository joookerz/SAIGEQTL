#!/usr/bin/env Rscript
# Rescale SAIGE-QTL Step2 results that were obtained using scaled expression
# (DS in [0,2]) back to the original expression units.

suppressPackageStartupMessages({
  library(optparse)
  library(data.table)
})

option_list <- list(
  make_option("--results-file", type = "character", help = "SAIGE results file (tsv/csv)."),
  make_option("--scaling-info", type = "character", help = "TSV with columns gene,min,max from expression_matrix_to_vcf.R."),
  make_option("--output-file", type = "character", help = "Path to write rescaled results."),
  make_option("--marker-column", type = "character", default = "MarkerID", help = "Column name identifying variants/genes [default=MarkerID]."),
  make_option("--beta-column", type = "character", default = "BETA", help = "Column name for beta estimates [default=BETA]."),
  make_option("--se-column", type = "character", default = "SE", help = "Column name for standard errors [default=SE]."),
  make_option("--delimiter", type = "character", default = "auto", help = "Delimiter for results file: auto, tab, comma."),
  make_option("--na-action", type = "character", default = "drop", help = "drop or keep rows without scaling info [default=drop].")
)

opt <- parse_args(OptionParser(option_list = option_list))
required <- c("results_file", "scaling_info", "output_file")
if (any(is.na(opt[required]))) {
  stop("Missing required argument(s): ", paste(required[is.na(opt[required])], collapse = ", "))
}

# Read results
if (opt$delimiter == "auto") {
  first_line <- readLines(opt$results_file, n = 1)
  delim <- if (grepl(",", first_line) && !grepl("\t", first_line)) "," else "\t"
} else if (opt$delimiter == "tab") {
  delim <- "\t"
} else if (opt$delimiter == "comma") {
  delim <- ","
} else {
  stop("Unsupported delimiter option")
}
res_dt <- fread(opt$results_file, sep = delim, data.table = TRUE)
scale_dt <- fread(opt$scaling_info, sep = "\t", data.table = TRUE)
if (!all(c("gene", "min", "max") %in% names(scale_dt))) {
  stop("scaling-info must contain columns: gene, min, max")
}

marker_col <- opt$`marker-column`
beta_col <- opt$`beta-column`
se_col <- opt$`se-column`
for (col in c(marker_col, beta_col, se_col)) {
  if (!col %in% names(res_dt)) {
    stop("Column ", col, " not found in results file")
  }
}

setnames(scale_dt, c("gene", "min", "max"), c("__gene__", "__min__", "__max__"))
scale_dt[, scale_factor := fifelse(__max__ > __min__, (__max__ - __min__) / 2, NA_real_)]
res_dt <- merge(res_dt, scale_dt, by.x = marker_col, by.y = "__gene__", all.x = TRUE, sort = FALSE)

if (opt$`na-action` == "drop") {
  before <- nrow(res_dt)
  res_dt <- res_dt[!is.na(scale_factor)]
  if (nrow(res_dt) < before) {
    message("Dropped ", before - nrow(res_dt), " row(s) without scaling info")
  }
}

res_dt[, `:=`(
  BETA_original = get(beta_col) / scale_factor,
  SE_original = get(se_col) / scale_factor
)]

fwrite(res_dt, opt$output_file, sep = delim)
cat("Rescaled results written to", opt$output_file, "using scaling factors from", opt$scaling_info, "\n")
