# Fresh runs never write to results/reported. Unique directories prevent overwrites.
new_run <- function(label) {
  root <- "results/generated"
  dir.create(root, recursive = TRUE, showWarnings = FALSE)
  path <- tempfile(paste0(format(Sys.time(), "%Y%m%dT%H%M%S"), "-", label, "-"), tmpdir = root)
  dir.create(path)
  writeLines(capture.output(sessionInfo()), file.path(path, "session-info.txt"))
  path
}

save_run <- function(result, path, name = "pricing") {
  write.csv(result$summary, file.path(path, paste0(name, ".csv")), row.names = FALSE)
  dput(result[c("config", "coefficient", "backend", "workers_requested", "rng")],
       file.path(path, paste0(name, "-metadata.R")))
  invisible(path)
}
