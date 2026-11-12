# Rscript --vanilla scripts/investigate.R [workers] [repetitions] [paths]
# Paired repeated experiments; no changes to report parameters or default pricing.
source("R/pricing.R")
source("R/diagnostics.R")
source("R/output.R")
args <- commandArgs(trailingOnly = TRUE)
workers <- if (length(args)) as.integer(args[1]) else 2L
repetitions <- if (length(args)>=2) as.integer(args[2]) else 100L
paths <- if (length(args)>=3) as.integer(args[3]) else 2000L
stopifnot(workers >= 1, repetitions >= 2, paths >= 10, repetitions < paths,
          paths^2 + repetitions <= .Machine$integer.max)
out <- new_run("investigation")
writeLines(out, "results/generated/latest-investigation.txt")
cluster <- if (workers > 1) parallel::makePSOCKcluster(workers, outfile = "") else NULL
run <- function() {
  if (!is.null(cluster)) {
    on.exit(parallel::stopCluster(cluster))
    parallel::clusterExport(cluster, c("diagnostic_pair", "diagnostic_experiment", "control_variate", "gbm_benchmark"), envir=.GlobalEnv)
  }
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  if (!is.null(cluster)) parallel::clusterEvalQ(cluster, RNGkind("Mersenne-Twister", "Inversion", "Rejection"))
  # Grid separation at low lambda plus all report scenarios at selected N.
  settings <- data.frame(N=c(100L,500L,1000L,500L,500L), lambda=c(.05,.05,.05,.30,.70))
  all <- list()
  for (i in seq_len(nrow(settings))) {
    config <- load_config(); config$N <- settings$N[i]; config$nsim <- paths
    config$market_price_of_risk <- settings$lambda[i]
    cat("Investigation", i, "/", nrow(settings), "N", config$N, "lambda", config$market_price_of_risk, "\n")
    dput(list(config=config, repetitions=repetitions, workers=workers,
      seed_rule="set.seed(nsim * p + repetition)", rng=RNGkind()),file.path(out,paste0("config-",i,".R")))
    rows <- if (is.null(cluster)) lapply(seq_len(repetitions), diagnostic_experiment, config=config)
      else parallel::parLapply(cluster, seq_len(repetitions), diagnostic_experiment, config=config)
    all[[i]] <- do.call(rbind,rows)
    write.csv(all[[i]], file.path(out,paste0("experiments-",i,".csv")),row.names=FALSE)
  }
  rows <- do.call(rbind,all)
  write.csv(rows,file.path(out,"experiments.csv"),row.names=FALSE)
  summaries <- lapply(all, function(x) {
    data.frame(N=x$N[1],lambda=x$lambda[1],repetitions=nrow(x),paths_per_repetition=x$nsim[1],
      raw=mean(x$raw),original_vrt=mean(x$original_vrt),bridge_crossfit=mean(x$bridge_crossfit),
      raw_mean_se=sd(x$raw)/sqrt(nrow(x)),
      original_mean_se=sd(x$original_vrt)/sqrt(nrow(x)),
      crossfit_mean_se=sd(x$bridge_crossfit)/sqrt(nrow(x)),
      raw_variance=var(x$raw),original_variance=var(x$original_vrt),crossfit_variance=var(x$bridge_crossfit),
      variance_reduction_factor=var(x$raw)/var(x$original_vrt),
      original_vs_raw=mean(x$original_vrt-x$raw),
      paired_shift_se=sd(x$original_vrt-x$raw)/sqrt(nrow(x)),
      crossfit_vs_raw=mean(x$bridge_crossfit-x$raw),
      crossfit_vs_raw_se=sd(x$bridge_crossfit-x$raw)/sqrt(nrow(x)),
      euler_error=mean(x$euler_minus_exact),monitoring_gap=mean(x$monitoring_gap),
      bridge_error=mean(x$bridge_minus_formula),bridge_error_se=sd(x$bridge_minus_formula)/sqrt(nrow(x)),
      rms_reported_se=sqrt(mean(x$original_se^2)),empirical_sd=sd(x$original_vrt),
      coefficient=mean(x$coefficient),negative_paths=sum(x$negative_paths),multi_jump_steps=sum(x$multi_jump_steps))
  })
  write.csv(do.call(rbind,summaries),file.path(out,"summary.csv"),row.names=FALSE)
  print(do.call(rbind,summaries))
}
run()
cat("Investigation finished:",out,"\n")
