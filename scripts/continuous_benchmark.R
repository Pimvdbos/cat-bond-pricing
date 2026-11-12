# Rscript --vanilla scripts/continuous_benchmark.R [paths] [workers]
source("R/pricing.R"); source("R/continuous_benchmark.R"); source("R/output.R")
args <- commandArgs(trailingOnly=TRUE)
n <- if(length(args)) as.integer(args[1]) else 200000L
workers <- if(length(args)>=2) as.integer(args[2]) else 2L
stopifnot(n>=100,n<1000000,workers>=1)
out <- new_run("continuous-benchmark")
writeLines(out,"results/generated/latest-continuous-benchmark.txt")
run <- function() {
  cluster <- if(workers>1) parallel::makePSOCKcluster(workers,outfile="") else NULL
  if(!is.null(cluster)) {
    on.exit(parallel::stopCluster(cluster))
    parallel::clusterExport(cluster,"continuous_pair",envir=.GlobalEnv)
    parallel::clusterEvalQ(cluster,RNGkind("Mersenne-Twister","Inversion","Rejection"))
  }
  RNGkind("Mersenne-Twister","Inversion","Rejection")
  cfg <- load_config(); rows <- list()
  for(i in seq_along(cfg$scenarios)) {
    cfg$market_price_of_risk <- cfg$scenarios[i]
    seeds <- 10000000L+1000000L*i+seq_len(n)
    cat("Continuous diagnostic lambda",cfg$market_price_of_risk,"\n")
    results <- if(is.null(cluster)) lapply(seeds,continuous_pair,config=cfg)
      else parallel::parLapply(cluster,seeds,continuous_pair,config=cfg)
    pay <- do.call(rbind,results)
    benchmark <- gbm_benchmark(cfg)
    # Fixed coefficient 1 avoids coefficient-estimation bias; expectation is known.
    adjusted <- pay[,1]-(pay[,2]-benchmark)
    se <- sd(adjusted)/sqrt(n)
    rows[[i]] <- data.frame(lambda=cfg$market_price_of_risk,paths=n,
      continuous_pjd=mean(adjusted),se=se,ci_lower=mean(adjusted)-1.96*se,
      ci_upper=mean(adjusted)+1.96*se,raw=mean(pay[,1]),raw_se=sd(pay[,1])/sqrt(n),
      gbm=mean(pay[,2]),gbm_se=sd(pay[,2])/sqrt(n),gbm_formula=benchmark)
    dput(list(config=cfg,paths=n,workers=workers,seed_min=min(seeds),seed_max=max(seeds),
      control_coefficient=1,rng=RNGkind()),file.path(out,paste0("config-",i,".R")))
  }
  write.csv(do.call(rbind,rows),file.path(out,"summary.csv"),row.names=FALSE)
  print(do.call(rbind,rows))
}
run()
