# Rscript --vanilla scripts/acquire_data.R [ace|sp500|all]
source("R/data.R")
source("R/output.R")
args <- commandArgs(trailingOnly = TRUE)
which <- if (length(args)) args[1] else "all"
stopifnot(which %in% c("ace", "sp500", "all"))
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/cache", recursive = TRUE, showWarnings = FALSE)
run <- new_run("acquisition")
status <- list()
if (which %in% c("ace", "all")) {
  for (extension in c("csv", "metadata.json")) {
    url <- paste0("https://ourworldindata.org/grapher/ace-north-atlantic-hurricanes.", extension)
    destination <- file.path("data/raw", paste0("ace-north-atlantic-hurricanes.", extension))
    status[[extension]] <- tryCatch({
      if (file.exists(destination)) stop("Existing file preserved; move it before requesting a fresh download.")
      temporary <- tempfile(tmpdir = "data/raw")
      tryCatch(download.file(url, temporary, mode = "wb", method = "libcurl"),
        error = function(e) { unlink(temporary); stop(e) })
      stopifnot(file.rename(temporary, destination))
      file_provenance(destination, url, "downloaded in this run")
    }, error = function(e) list(source_url = url, error = conditionMessage(e)))
  }
}
if (which %in% c("sp500", "all")) {
  status$sp500 <- tryCatch({
    if (file.exists("data/cache/GSPC.rds")) stop("Existing cache preserved; move it before a fresh download.")
    if (!requireNamespace("quantmod", quietly = TRUE)) stop("Install quantmod first.")
    x <- quantmod::getSymbols("^GSPC", src = "yahoo", from = "1950-01-01", to = "2023-01-01", auto.assign = FALSE)
    saveRDS(x, "data/cache/GSPC.rds")
    load_sp500()$provenance
  }, error = function(e) list(symbol = "^GSPC", source = "Yahoo", error = conditionMessage(e)))
}
dput(status, file.path(run, "acquisition.R"))
print(status)
cat("Acquisition record:", run, "\nSee data/README.md for manual routes.\n")
