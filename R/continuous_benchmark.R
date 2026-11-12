# Independent diagnostic for the continuous multiplicative PJD implied by LL.R.
# Exact Poisson event times + lognormal endpoints + Brownian-bridge survival.
# NOT the report's Euler/grid contract implementation and never used for Tables 6-7.
continuous_pair <- function(seed, config) {
  with(config, {
    set.seed(seed)
    count <- rpois(1, jump_intensity*maturity)
    times <- c(0, sort(runif(count,0,maturity)), maturity)
    dt <- diff(times)
    drift <- mu-market_price_of_risk*sigma-sigma^2/2
    moves <- drift*dt+sigma*sqrt(dt)*rnorm(count+1)
    jumps <- c(rnorm(count,mean_log_jump,jump_sd),0)
    barrier <- log(threshold/initial_index)
    x <- y <- 0
    log_survival_x <- log_survival_y <- 0
    for (i in seq_along(dt)) {
      endx <- x+moves[i]; endy <- y+moves[i]
      if (max(x,endx)>=barrier) log_survival_x <- -Inf
      else log_survival_x <- log_survival_x+log(-expm1(-2*(barrier-x)*(barrier-endx)/(sigma^2*dt[i])))
      if (max(y,endy)>=barrier) log_survival_y <- -Inf
      else log_survival_y <- log_survival_y+log(-expm1(-2*(barrier-y)*(barrier-endy)/(sigma^2*dt[i])))
      x <- endx+jumps[i]; y <- endy
      if (x>=barrier) log_survival_x <- -Inf
    }
    pv <- face_value*exp(-risk_free_rate*maturity)
    c(PJD=pv*(1-loss_fraction+loss_fraction*exp(log_survival_x)),
      GBM=pv*(1-loss_fraction+loss_fraction*exp(log_survival_y)))
  })
}
