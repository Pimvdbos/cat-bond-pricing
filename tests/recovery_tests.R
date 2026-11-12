# Recovered-code equivalence and analytical fixtures; no teaching data used.
source("R/pricing.R")
source("R/estimation.R")
source("R/diagnostics.R")
source("R/continuous_benchmark.R")
find_parallel <- function(expr) {
  result <- list()
  walk <- function(x) {
    if (missing(x)) return(invisible(NULL))
    if (is.call(x) && identical(x[[1]], as.name("%dopar%"))) result[[length(result)+1L]] <<- x[[3]]
    else if (is.call(x) || is.expression(x) || is.pairlist(x)) for (y in as.list(x)) walk(y)
  }
  walk(expr); result
}
evaluate_body <- function(body, config, p, j=0) {
  env <- list2env(list(mu=config$mu,sigma=config$sigma,delta=config$jump_sd,
    lambda.p=config$jump_intensity,kv=config$mean_log_jump,lambda=config$market_price_of_risk,
    F=config$face_value,I0=config$initial_index,K=config$threshold,T=config$maturity,
    w=config$loss_fraction,r=config$risk_free_rate,N=config$N,nsim=config$nsim,
    delta.t=config$maturity/config$N,p=p,j=j,EPV.formula=gbm_benchmark(config)))
  sys.source("original/teaching/functions.R",env)
  env$risk.index <- env$risk.index1 <- env$risk.index2 <- c(config$initial_index,rep(0,config$N))
  eval(body,env)
}
config <- load_config();config$N <- 500L;config$nsim <- 100L
for (p in seq_len(30)) {
  pair <- simulate_pair(p,config)
  for (file in c("original/teaching/part4_cat_price_vrt.R", "original/appendix_C_pricing.R"))
    for (body in find_parallel(parse(file)))
      stopifnot(isTRUE(all.equal(unname(pair),evaluate_body(body,config,p)[1:2])))
  body3 <- find_parallel(parse("original/teaching/part3_cat_price.R"))[[1]]
  stopifnot(unname(pair[1]) == evaluate_body(body3,config,p))
  diag <- diagnostic_pair(config$nsim*p,config)
  stopifnot(identical(unname(diag[1:2]),unname(pair)))
  body5 <- find_parallel(parse("original/teaching/part5_cat_price_withCI.R"))[[1]]
  stopifnot(isTRUE(all.equal(unname(diagnostic_pair(config$nsim*p+1,config)[1:2]),
                             evaluate_body(body5,config,p,j=1)[1:2])))
}
env <- new.env();env$return.cat <- c(-.2,.1,.4);env$delta.t <- 1
sys.source("original/teaching/LL.R",env)
stopifnot(length(env$LL(c(.196,.660,1.55,.135,.202)))==3,
  isTRUE(all.equal(env$LL(c(.196,.660,1.55,0,.202)),dnorm(env$return.cat,.196-.660^2/2,.660,log=TRUE))))
# Reflection-principle zero log drift case: hit probability = 2*Phi(-b/(sigma sqrt(T))).
config$mu <- config$sigma^2/2+config$market_price_of_risk*config$sigma
expected <- config$face_value*exp(-config$risk_free_rate*config$maturity)*
  (1-config$loss_fraction*2*pnorm(-log(config$threshold/config$initial_index)/(config$sigma*sqrt(config$maturity))))
stopifnot(isTRUE(all.equal(gbm_benchmark(config),expected)))
# Independently integrate a one-step Brownian-bridge survival over terminal log GBM.
for (lambda in c(.05,.3,.7)) {
  cfg <- load_config();cfg$market_price_of_risk <- lambda
  barrier <- log(cfg$threshold/cfg$initial_index)
  variance <- cfg$sigma^2*cfg$maturity
  mean_log <- (cfg$mu-lambda*cfg$sigma-cfg$sigma^2/2)*cfg$maturity
  survival <- integrate(function(x) -expm1(-2*barrier*(barrier-x)/variance)*
    dnorm(x,mean_log,sqrt(variance)), lower=-Inf,upper=barrier,rel.tol=1e-10)$value
  integrated <- cfg$face_value*exp(-cfg$risk_free_rate*cfg$maturity)*
    (1-cfg$loss_fraction+cfg$loss_fraction*survival)
  stopifnot(abs(integrated-gbm_benchmark(cfg))<1e-7)
}
cfg$jump_intensity <- 0
for(seed in 1:20) {
  pair <- continuous_pair(seed,cfg)
  stopifnot(pair[1]==pair[2],all(pair>=0),all(pair<=cfg$face_value))
}
cfg$loss_fraction <- 0
stopifnot(all(continuous_pair(5,cfg)==cfg$face_value*exp(-cfg$risk_free_rate*cfg$maturity)))
cat("PASS: recovered teaching parts 3/4/5 and both Appendix C kernels agree on 30 seeded paths;\n",
    "independent diagnostic payoff equivalence, original likelihood fixture, analytical barrier fixture.\n")
