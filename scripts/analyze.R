# Rscript --vanilla scripts/analyze.R [initial|estimate|correlation] [ace.csv] [entity] [sp500.rds-or-csv] [indicator]
source("R/data.R")
source("R/estimation.R")
source("R/output.R")
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1] else "initial"
stopifnot(mode %in% c("initial", "estimate", "correlation"))
ace_path <- if (length(args) >= 2) args[2] else "data/raw/ace-north-atlantic-hurricanes.csv"
entity <- if (length(args) >= 3) args[3] else "North Atlantic"
sp_path <- if (length(args) >= 4) args[4] else "data/cache/GSPC.rds"
indicator <- if (length(args) >= 5) args[5] else NULL
ace <- load_ace(ace_path, entity, indicator)
run <- new_run(mode)
dput(ace$provenance, file.path(run, "ace-provenance.R"))
if (mode %in% c("initial", "estimate")) {
  sensitivity <- epsilon_sensitivity(ace$data$ACE_log_return)
  print(sensitivity)
  write.csv(sensitivity, file.path(run, "epsilon.csv"), row.names = FALSE)
  initial <- initial_estimates(ace$data$ACE_log_return)
  print(initial)
  dput(initial, file.path(run, "initial.R"))
  if (mode == "estimate") {
    fit <- estimate_pjd(ace$data$ACE_log_return)
    saveRDS(fit, file.path(run, "estimation.rds"))
    writeLines(capture.output(summary(fit$fit)), file.path(run, "estimation.txt"))
  }
} else {
  sp <- load_sp500(sp_path)
  dput(sp$provenance, file.path(run, "sp500-provenance.R"))
  result <- correlation_analysis(ace$data, sp$data)
  print(result$pearson)
  print(result$spearman)
  saveRDS(result, file.path(run, "correlation.rds"))
  write.csv(result$paired, file.path(run, "paired-returns.csv"), row.names = FALSE)
  writeLines(capture.output(result[c("omitted_years", "pearson", "spearman")]), file.path(run, "correlation.txt"))
}
cat("Generated outputs:", run, "\n")
