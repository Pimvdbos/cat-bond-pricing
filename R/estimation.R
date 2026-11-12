# Appendix A formulas with the recovered original teaching likelihood.
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

# LL.R returns observation-wise log densities for a 0:50 Poisson mixture.
estimate_pjd <- function(returns, helper_dir = "original/teaching") {
  files <- file.path(helper_dir, c("functions.R", "LL.R"))
  if (!all(file.exists(files))) stop("Recovered functions.R and LL.R required in ", helper_dir, ".")
  if (!requireNamespace("maxLik", quietly = TRUE)) stop("Install maxLik first.")
  env <- new.env(parent = globalenv())
  env$return.cat <- returns[is.finite(returns)]
  env$N <- length(env$return.cat)
  env$delta.t <- 1
  # Exact recovered interface: return.cat, delta.t and njumps=50 in LL's closure.
  for (f in files) sys.source(f, envir = env)
  if (!exists("LL", env, inherits = FALSE) || !is.function(env$LL)) stop("LL.R must define LL.")
  initial <- initial_estimates(env$return.cat)
  warning_counts <- list()
  fit_once <- function(start, stage) withCallingHandlers(
    maxLik::maxLik(env$LL, start = start, method = "BHHH", control = list(iterlim = 1000)),
    warning = function(w) {
      key <- paste(stage, conditionMessage(w), sep = ": ")
      warning_counts[[key]] <<- if (is.null(warning_counts[[key]])) 1L else warning_counts[[key]] + 1L
      invokeRestart("muffleWarning")
    })
  fit <- fit_once(initial, "initial")
  set.seed(123)
  restarts <- vector("list", 10)
  for (i in seq_len(10)) {
    start <- initial * runif(5, 0.5, 1.5)
    restarts[[i]] <- tryCatch({
      result <- fit_once(start, paste0("restart-", i))
      list(start = start, maximum = result$maximum, estimate = result$estimate, code = result$code)
    }, error = function(e) list(start = start, error = conditionMessage(e)))
  }
  list(initial = initial, fit = fit, restarts = restarts, warnings = warning_counts)
}
