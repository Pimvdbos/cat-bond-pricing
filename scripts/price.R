# Rscript --vanilla scripts/price.R [small|full|sensitivity] [workers]
source("R/pricing.R")
source("R/output.R")
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[1] else "small"
workers <- if (length(args) >= 2) as.integer(args[2]) else 1L
stopifnot(mode %in% c("small", "full", "sensitivity"))
config <- load_config()
path <- new_run(mode)
if (mode == "small") {
  config$N <- 50L
  config$nsim <- 100L
  result <- price_bond(config, workers)
  print(result$summary, row.names = FALSE)
  save_run(result, path)
} else {
  grid <- if (mode == "full") {
    data.frame(N = config$N, nsim = config$nsim, market_price_of_risk = config$scenarios)
  } else expand.grid(N = config$grid_N, nsim = config$grid_nsim, market_price_of_risk = 0.05)
  summaries <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    config[names(grid)] <- as.list(grid[i, ])
    result <- price_bond(config, workers)
    print(result$summary, row.names = FALSE)
    save_run(result, path, paste0("run-", i))
    summaries[[i]] <- result$summary
  }
  write.csv(do.call(rbind, summaries), file.path(path, "all-results.csv"), row.names = FALSE)
}
cat("Generated outputs:", path, "\n")
