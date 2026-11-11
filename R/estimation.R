# Recovered Appendix A formulas. No invented LL.R or inferred likelihood.
initial_estimates <- function(returns, epsilon = 1, delta_t = 1) {
  returns <- returns[is.finite(returns)]
  jumps <- returns[abs(returns) > epsilon]
  diffusion <- returns[abs(returns) <= epsilon]
  if (length(jumps) < 2 || length(diffusion) < 2) stop("Need at least two observations in each initial group.")
  sigma <- sd(diffusion) / sqrt(delta_t)
  mu <- (2 * mean(diffusion) + sigma^2 * delta_t) / (2 * delta_t)
  intensity <- length(jumps) / (length(returns) * delta_t)
  delta <- sqrt(abs(var(jumps) - sigma^2 * delta_t))
  kv <- mean(jumps) - (mu - sigma^2 / 2) * delta_t
  c(mu = mu, sigma = sigma, delta = delta, lambda.p = intensity, kv = kv)
}

epsilon_sensitivity <- function(returns, epsilon = c(0.8, 1.0, 1.2), delta_t = 1) {
  returns <- returns[is.finite(returns)]
  if (!length(returns)) stop("No finite annual returns.")
  jumps <- vapply(epsilon, function(e) sum(abs(returns) > e), integer(1))
  data.frame(epsilon = epsilon, jumps = jumps, diffusion = length(returns) - jumps,
             initial_jump_frequency = jumps / (length(returns) * delta_t))
}

# To execute MLE, the user must supply and review the actual original helpers.
estimate_pjd <- function(returns, helper_dir = "data/private_helpers") {
  files <- file.path(helper_dir, c("functions.R", "LL.R"))
  if (!all(file.exists(files))) stop("Original functions.R and LL.R were not recovered. ",
    "Initialization is available; MLE requires those original helpers in ", helper_dir, ".")
  if (!requireNamespace("maxLik", quietly = TRUE)) stop("Install maxLik first.")
  env <- new.env(parent = globalenv())
  env$return.cat <- returns[is.finite(returns)]
  env$N <- length(env$return.cat)
  env$delta.t <- 1
  # Establish the appendix globals before sourcing the unknown helper interface.
  for (f in files) sys.source(f, envir = env)
  if (!exists("LL", env, inherits = FALSE) || !is.function(env$LL)) stop("LL.R must define LL.")
  initial <- initial_estimates(env$return.cat)
  fit <- maxLik::maxLik(env$LL, start = initial, method = "BHHH", control = list(iterlim = 1000))
  set.seed(123)
  restarts <- vector("list", 10)
  for (i in seq_len(10)) {
    start <- initial * runif(5, 0.5, 1.5)
    restarts[[i]] <- tryCatch({
      result <- maxLik::maxLik(env$LL, start = start, method = "BHHH", control = list(iterlim = 1000))
      list(start = start, maximum = result$maximum, estimate = result$estimate, code = result$code)
    }, error = function(e) list(start = start, error = conditionMessage(e)))
  }
  list(initial = initial, fit = fit, restarts = restarts)
}
