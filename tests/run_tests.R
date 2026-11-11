# Artificial fixtures only: these tests do not validate the reported research.
files <- c(list.files("R", "\\.R$", full.names = TRUE),
           list.files("scripts", "\\.R$", full.names = TRUE),
           list.files("original", "\\.R$", full.names = TRUE), "config/default.R")
for (file in files) invisible(parse(file))
for (file in list.files("R", "\\.R$", full.names = TRUE)) source(file)
config <- load_config()
discounted <- config$face_value * exp(-config$risk_free_rate * config$maturity)
stopifnot(principal_pv(c(100, 200, 150), config) == 0,
          principal_pv(c(100, 199), config) == discounted)
zero_loss <- config
zero_loss$loss_fraction <- 0
stopifnot(principal_pv(c(100, 250), zero_loss) == discounted)
partial <- config
partial$loss_fraction <- 0.4
stopifnot(all.equal(principal_pv(c(100, 200), partial), discounted * 0.6))
fixture <- control_variate(c(2, 4, 6), c(1, 2, 3), 2)
stopifnot(fixture$coefficient == 2, all(fixture$adjusted == 4))
constant <- suppressWarnings(control_variate(c(1, 2, 3), c(2, 2, 2), 2))
stopifnot(constant$coefficient == 0, identical(constant$adjusted, c(1, 2, 3)))
config$N <- 20L
config$nsim <- 40L
set.seed(42)
saved_seed <- .Random.seed
serial <- price_bond(config, workers = 1)
stopifnot(identical(saved_seed, .Random.seed), all(is.finite(serial$summary$price)),
          nrow(serial$summary) == 4, nrow(serial$payoffs) == 40,
          all.equal(serial$summary$se[1], sd(serial$adjusted_payoffs) / sqrt(40)),
          all.equal(serial$summary$ci_width[1], 3.92 * serial$summary$se[1]))
parallel_run <- price_bond(config, workers = 2)
stopifnot(identical(serial$payoffs, parallel_run$payoffs),
          identical(serial$summary, parallel_run$summary))
cat("Parallel backend actually used:", parallel_run$backend, "\n")
# All paths must pay discounted principal under zero loss.
config$loss_fraction <- 0
lossless <- suppressWarnings(price_bond(config))
stopifnot(all(lossless$payoffs == discounted), all(abs(lossless$summary$price - discounted) < 1e-10))
# Initial jump classification must include both signs.
returns <- c(-1.5, 1.6, -0.2, 0.1, 0.4, -0.3)
stopifnot(epsilon_sensitivity(returns)$jumps[2] == 2,
          initial_estimates(returns)["lambda.p"] == 2 / 6)
cat("PASS: syntax, clean sourcing, config, trigger equality, principal payoffs, zero loss,\n",
    "control arithmetic, initial jump classification, serial simulation, RNG restoration,\n",
    "serial/parallel equality, adjusted standard errors and confidence intervals.\n")
