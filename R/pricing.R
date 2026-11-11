# Appendix C maintained implementation. No external packages or historical data.
load_config <- function(path = "config/default.R") {
  config <- dget(path)
  validate_config(config)
  config
}

validate_config <- function(config) {
  required <- c("mu", "sigma", "jump_sd", "jump_intensity", "mean_log_jump",
                "face_value", "initial_index", "threshold", "maturity",
                "loss_fraction", "risk_free_rate", "market_price_of_risk", "N", "nsim")
  stopifnot(all(required %in% names(config)))
  stopifnot(all(vapply(config[required], function(x)
    is.numeric(x) && length(x) == 1L && is.finite(x), logical(1))))
  with(config, stopifnot(sigma > 0, jump_sd >= 0, jump_intensity >= 0,
    face_value > 0, initial_index > 0, threshold > initial_index, maturity > 0,
    loss_fraction >= 0, loss_fraction <= 1, N >= 1, N == floor(N),
    nsim >= 2, nsim == floor(nsim), nsim^2 <= .Machine$integer.max))
  invisible(config)
}

principal_pv <- function(path, config) {
  with(config, exp(-risk_free_rate * maturity) * face_value *
    (1 - loss_fraction * (max(path) >= threshold)))
}

# Continuous GBM upper-barrier formula, exactly as printed in Appendix C.
gbm_benchmark <- function(config) {
  with(config, {
    drift <- mu - market_price_of_risk * sigma
    d1 <- (log(initial_index / threshold) + (drift - sigma^2 / 2) * maturity) /
      (sigma * maturity^0.5)
    d2 <- (log(initial_index / threshold) - (drift - sigma^2 / 2) * maturity) /
      (sigma * maturity^0.5)
    hit_probability <- pnorm(d1) + (initial_index / threshold)^
      (1 - 2 * drift / sigma^2) * pnorm(d2)
    exp(-risk_free_rate * maturity) * (face_value - loss_fraction * face_value * hit_probability)
  })
}

# Preserve draw order, per-path seeds, Euler updates and summation of relative jumps.
simulate_pair <- function(p, config) {
  with(config, {
    set.seed(nsim * p)
    dt <- maturity / N
    brownian <- rnorm(N)
    arrivals <- rpois(N, jump_intensity * dt)
    pjd <- gbm <- numeric(N + 1L)
    pjd[1] <- gbm[1] <- initial_index
    for (i in seq_len(N)) {
      jumps <- if (arrivals[i] > 0) {
        exp(rnorm(arrivals[i]) * jump_sd + mean_log_jump) - 1
      } else 0
      diffusion <- (mu - market_price_of_risk * sigma) * dt + sigma * brownian[i] * sqrt(dt)
      pjd[i + 1L] <- pjd[i] + (diffusion + sum(jumps)) * pjd[i]
      gbm[i + 1L] <- gbm[i] + diffusion * gbm[i]
    }
    c(PJD = principal_pv(pjd, config), GBM = principal_pv(gbm, config))
  })
}

control_variate <- function(pjd, gbm, benchmark) {
  stopifnot(length(pjd) == length(gbm), length(pjd) >= 2,
            all(is.finite(c(pjd, gbm, benchmark))))
  difference <- gbm - benchmark
  variance <- var(difference)
  # A tiny run can have constant GBM payoffs. Its control contains no information.
  coefficient <- if (variance == 0) 0 else cov(pjd, difference) / variance
  if (variance == 0) warning("Constant GBM payoffs: control coefficient set to zero.")
  list(adjusted = pjd - coefficient * difference, coefficient = coefficient,
       difference = difference)
}

price_bond <- function(config = load_config(), workers = 1L) {
  validate_config(config)
  stopifnot(length(workers) == 1, is.finite(workers), workers >= 1, workers == floor(workers))
  # Explicit RNG settings and restore caller state, including after an error.
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, .GlobalEnv)
    else if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  backend <- "serial"
  cluster <- NULL
  if (workers > 1L) {
    cluster <- tryCatch(parallel::makePSOCKcluster(workers, outfile = ""),
      error = function(e) { warning("PSOCK unavailable; using serial: ", conditionMessage(e)); NULL })
  }
  if (!is.null(cluster)) {
    on.exit(parallel::stopCluster(cluster), add = TRUE)
    parallel::clusterExport(cluster, c("simulate_pair", "principal_pv"),
                            envir = environment(price_bond))
    parallel::clusterEvalQ(cluster, RNGkind("Mersenne-Twister", "Inversion", "Rejection"))
    paths <- parallel::parLapply(cluster, seq_len(config$nsim), simulate_pair, config = config)
    backend <- "PSOCK"
  } else paths <- lapply(seq_len(config$nsim), simulate_pair, config = config)
  payoffs <- do.call(rbind, paths)
  formula <- gbm_benchmark(config)
  cv <- control_variate(payoffs[, "PJD"], payoffs[, "GBM"], formula)
  prices <- c(mean(cv$adjusted), mean(payoffs[, "PJD"]), mean(payoffs[, "GBM"]), formula)
  se <- c(sd(cv$adjusted), sd(payoffs[, "PJD"]), sd(payoffs[, "GBM"]), NA_real_) / sqrt(config$nsim)
  spreads <- rep(NA_real_, 4)
  positive <- prices > 0
  spreads[positive] <- -log(prices[positive] / config$face_value) / config$maturity - config$risk_free_rate
  summary <- data.frame(method = c("PJD with VRT", "PJD without VRT", "GBM simulation", "GBM formula"),
    market_price_of_risk = config$market_price_of_risk, N = config$N, nsim = config$nsim,
    price = prices, spread = spreads, se = se, ci_lower = prices - 1.96 * se,
    ci_upper = prices + 1.96 * se, ci_width = 2 * 1.96 * se)
  list(summary = summary, coefficient = cv$coefficient, config = config,
       backend = backend, workers_requested = workers,
       rng = "Mersenne-Twister / Inversion / Rejection; set.seed(nsim * p)",
       payoffs = payoffs, adjusted_payoffs = cv$adjusted)
}
