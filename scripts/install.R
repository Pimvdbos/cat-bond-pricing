# Optional data and archival dependencies; pricing, figures and tests use base R.
packages <- c("quantmod", "digest", "maxLik", "foreach", "doParallel")
missing <- packages[!vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
stopifnot(all(vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))))
dir.create("results/generated", recursive = TRUE, showWarnings = FALSE)
write.csv(as.data.frame(installed.packages()[packages, c("Package", "Version")]),
          "results/generated/installed-packages.csv", row.names = FALSE)
