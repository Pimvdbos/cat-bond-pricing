# Full research reproduction from recovered data and original LL.R.
# Rscript --vanilla scripts/reproduce.R [workers]
source("R/pricing.R")
source("R/estimation.R")
source("R/data.R")
source("R/output.R")
args <- commandArgs(trailingOnly = TRUE)
workers <- if (length(args)) as.integer(args[1]) else 2L
out <- new_run("reproduction")
writeLines(out, "results/generated/latest-reproduction.txt")
write_table <- function(x, name) write.csv(x, file.path(out, name), row.names = FALSE)
config <- load_config()
dput(config, file.path(out, "pricing-config.R"))
ace <- load_ace()
sp <- load_sp500()
dput(ace$provenance, file.path(out, "ace-provenance.R"))
dput(sp$provenance, file.path(out, "sp500-provenance.R"))
write_table(epsilon_sensitivity(ace$data$ACE_log_return), "table_1_epsilon.csv")
cat("Estimating with original LL.R ...\n")
fit <- estimate_pjd(ace$data$ACE_log_return)
saveRDS(fit, file.path(out, "estimation.rds"))
dput(fit$warnings, file.path(out, "estimation-warnings.R"))
estimate_summary <- summary(fit$fit)
writeLines(capture.output(estimate_summary), file.path(out, "estimation-summary.txt"))
coeff <- estimate_summary$estimate
write_table(data.frame(parameter = rownames(coeff), estimate = coeff[, 1], standard_error = coeff[, 2],
                       t_value = coeff[, 3], p_value = coeff[, 4]), "table_2_estimates.csv")
restarts <- do.call(rbind, lapply(seq_along(fit$restarts), function(i) {
  x <- fit$restarts[[i]]
  data.frame(run = i, log_likelihood = if (is.null(x$maximum)) NA_real_ else x$maximum,
    convergence_code = if (is.null(x$code)) NA_integer_ else x$code,
    error = if (is.null(x$error)) "" else x$error)
}))
write_table(restarts, "table_3_restarts.csv")
dput(fit$initial, file.path(out, "estimation-start.R"))
correlation <- correlation_analysis(ace$data, sp$data)
p <- correlation$pearson
write_table(data.frame(statistic = c("correlation", "t_statistic", "degrees_of_freedom", "p_value", "ci_lower", "ci_upper"),
    value = c(unname(p$estimate), unname(p$statistic), unname(p$parameter), p$p.value, p$conf.int)), "table_4_pearson.csv")
write_table(data.frame(statistic = c("paired_observations", "spearman_correlation", "spearman_p_value", "optimum_log_likelihood"),
    value = c(nrow(correlation$paired), correlation$spearman$estimate, correlation$spearman$p.value, fit$fit$maximum)), "narrative_statistics.csv")
# Table 5 is a specification, not an estimated output. Compare the actual config.
keys <- c("face_value", "initial_index", "threshold", "maturity", "loss_fraction", "risk_free_rate")
write_table(data.frame(parameter = keys, value = unlist(config[keys])), "table_5_bond.csv")
grid <- expand.grid(N = config$grid_N, nsim = config$grid_nsim)
rows <- list()
diagnostics <- list()
for (i in seq_len(nrow(grid))) {
  config$N <- grid$N[i]; config$nsim <- grid$nsim[i]
  cat("Grid", i, "of", nrow(grid), ":", config$N, config$nsim, "\n")
  x <- price_bond(config, workers)
  save_run(x, out, paste0("grid-", i))
  rows[[i]] <- x$summary[1, c("N", "nsim", "price", "ci_lower", "ci_upper", "ci_width")]
  diagnostics[[i]] <- data.frame(N=config$N, nsim=config$nsim, coefficient=x$coefficient,
    correlation=cor(x$payoffs[,1], x$payoffs[,2]),
    variance_ratio=var(x$payoffs[,1])/var(x$adjusted_payoffs),
    gbm_gap=mean(x$payoffs[,2])-gbm_benchmark(config),
    price_shift=mean(x$adjusted_payoffs)-mean(x$payoffs[,1]))
}
write_table(do.call(rbind, rows), "table_6_sensitivity.csv")
write_table(do.call(rbind, diagnostics), "grid-diagnostics.csv")
config <- load_config()
rows <- list()
for (i in seq_along(config$scenarios)) {
  config$market_price_of_risk <- config$scenarios[i]
  cat("Scenario", config$market_price_of_risk, "\n")
  x <- price_bond(config, workers)
  save_run(x, out, paste0("scenario-", i))
  rows[[i]] <- data.frame(market_price_of_risk=config$market_price_of_risk,
    pjd_price_vrt=x$summary$price[1], spread_vrt=x$summary$spread[1],
    pjd_price_no_vrt=x$summary$price[2], spread_no_vrt=x$summary$spread[2])
}
write_table(do.call(rbind, rows), "table_7_prices.csv")
cat("Reproduction finished:", out, "\n")
