# Optional follow-up to scripts/reproduce.R; records original warnings and LL cutoff sensitivity.
source("R/data.R")
source("R/estimation.R")
out <- readLines("results/generated/latest-reproduction.txt")
ace <- load_ace()
fit <- estimate_pjd(ace$data$ACE_log_return)
dput(fit$warnings, file.path(out, "estimation-warnings.R"))
env <- new.env(); env$return.cat <- na.omit(ace$data$ACE_log_return); env$delta.t <- 1
sys.source("original/teaching/LL.R", env)
checks <- lapply(c(10,25,50,100), function(k) {
  env$njumps <- k
  data.frame(njumps=k, log_likelihood=sum(env$LL(fit$fit$estimate)),
             omitted_poisson_mass=ppois(k,fit$fit$estimate[4],lower.tail=FALSE))
})
write.csv(do.call(rbind,checks),file.path(out,"likelihood-truncation.csv"),row.names=FALSE)
env$njumps <- 50
refined <- maxLik::maxLik(env$LL,start=fit$fit$estimate,method="BHHH",control=list(iterlim=1000,reltol=1e-12))
writeLines(capture.output(summary(refined)),file.path(out,"estimation-tight-tolerance.txt"))
# Refined estimates are diagnostic only; fixed report pricing inputs are unchanged.
