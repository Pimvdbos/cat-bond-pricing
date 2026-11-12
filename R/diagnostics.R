# Independent diagnostic implementation. Never replaces the Appendix C engine.
# Exact GBM endpoints and conditional Brownian-bridge survival share its normals.
diagnostic_pair <- function(seed, config) {
  with(config, {
    set.seed(seed)
    dt <- maturity / N
    z <- rnorm(N)
    counts <- rpois(N, jump_intensity * dt)
    jump_sum <- numeric(N)
    for (i in which(counts > 0))
      jump_sum[i] <- sum(exp(rnorm(counts[i]) * jump_sd + mean_log_jump) - 1)
    drift <- mu - market_price_of_risk * sigma
    diffusion <- drift * dt + sigma * z * sqrt(dt)
    # Vectorized products are diagnostic only (different floating-point ordering).
    pjd <- c(initial_index, initial_index * cumprod(1 + diffusion + jump_sum))
    gbm_euler <- c(initial_index, initial_index * cumprod(1 + diffusion))
    logs <- c(0, cumsum((drift - sigma^2 / 2) * dt + sigma * z * sqrt(dt)))
    barrier <- log(threshold / initial_index)
    exact_grid_hit <- any(logs >= barrier)
    survival <- if (exact_grid_hit) 0 else {
      exponent <- -2 * (barrier - head(logs, -1)) * (barrier - tail(logs, -1)) / (sigma^2 * dt)
      exp(sum(log(-expm1(exponent))))
    }
    discounted <- face_value * exp(-risk_free_rate * maturity)
    c(PJD=discounted*(1-loss_fraction*(max(pjd)>=threshold)),
      GBM_Euler=discounted*(1-loss_fraction*(max(gbm_euler)>=threshold)),
      GBM_exact_grid=discounted*(1-loss_fraction*exact_grid_hit),
      GBM_bridge=discounted*(1-loss_fraction+loss_fraction*survival),
      negative_PJD=any(pjd < 0), multiple_jump_steps=sum(counts > 1))
  })
}

diagnostic_experiment <- function(j, config) {
  n <- config$nsim
  # Teaching part 5 convention, distinct from faithful one-experiment seed rule.
  pay <- t(vapply(seq_len(n), function(p) diagnostic_pair(n * p + j, config), numeric(6)))
  benchmark <- gbm_benchmark(config)
  x <- pay[, "PJD"]; y <- pay[, "GBM_Euler"]; b <- pay[, "GBM_bridge"]
  original <- control_variate(x, y, benchmark)
  bridge <- control_variate(x, b, benchmark)
  # Opposite-half coefficients: each coefficient is independent of the payoffs
  # to which it is applied. This removes same-sample coefficient bias in mean.
  half <- rep(1:2, length.out = n)
  cross <- numeric(n)
  for (h in 1:2) {
    training <- half != h; test <- !training
    coefficient <- cov(x[training], b[training]) / var(b[training])
    cross[test] <- x[test] - coefficient * (b[test] - benchmark)
  }
  data.frame(repetition=j, N=config$N, nsim=n, lambda=config$market_price_of_risk,
    raw=mean(x), original_vrt=mean(original$adjusted), bridge_vrt=mean(bridge$adjusted),
    bridge_crossfit=mean(cross), original_se=sd(original$adjusted)/sqrt(n),
    raw_se=sd(x)/sqrt(n), coefficient=original$coefficient,
    path_correlation=cor(x,y), path_variance_ratio=var(x)/var(original$adjusted),
    gbm_euler=mean(y), gbm_exact_grid=mean(pay[,"GBM_exact_grid"]),
    gbm_bridge=mean(b), gbm_formula=benchmark,
    euler_minus_exact=mean(y-pay[,"GBM_exact_grid"]),
    monitoring_gap=mean(pay[,"GBM_exact_grid"]-b),
    bridge_minus_formula=mean(b)-benchmark,
    vrt_shift=mean(original$adjusted)-mean(x),
    negative_paths=sum(pay[,"negative_PJD"]), multi_jump_steps=sum(pay[,"multiple_jump_steps"]))
}
