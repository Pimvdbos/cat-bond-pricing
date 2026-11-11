# Reconstructed from PDF Listing C. Not the unavailable original source.
# See docs/code_provenance.md before execution.
# Load libraries
library(foreach)
library(doParallel)
registerDoParallel(cores=4)

# MLE parameters from Section 3 (Table 2)
mu     = 0.196
sigma  = 0.660
delta  = 1.550
lambda.p = 0.135
kv     = 0.202

# CAT bond parameters from Section 8 (Table 5)
F  = 1000   # face value
I0 = 100    # starting value of the ACE index
K  = 200    # trigger threshold (I0/K = 0.50 < 1)
T  = 1      # maturity in years
w  = 1.0    # full principal-at-risk
r  = 0.03   # risk-free rate (as specified in assignment)

# Functions defined directly instead of source ( "functions.R")
mut     <- function(t){ mu }
sigmat  <- function(t){ sigma }
lambdat <- function(t){ lambda }

# Sensitivity analysis on N and nsim
# We test combinations of N in (100, 500, 1000) and nsim in (3500, 5000, 6500) for a fixed lambda = 0.05.

lambda = 0.05
N_values    <- c(100, 500, 1000)
nsim_values <- c(3500, 5000, 6500)
results <- data.frame()

for(N in N_values){
for(nsim in nsim_values){

delta.t <- T/N

# GBM formula (needed for variance reduction technique)
delta1 <- mu - lambda*sigma
d1 <- (log(I0/K) + (delta1 - sigma^2/2)*T) / (sigma*T^0.5)
d2 <- (log(I0/K) - (delta1 - sigma^2/2)*T) / (sigma*T^0.5)
E  <- pnorm(d1) + (I0/K)^(1 - 2*delta1/sigma^2)*pnorm(d2)
EPV.formula <- exp(-r*T)*(F - w*F*E)

risk.index1 <- matrix(0,(N+1),1)
risk.index1[1] <- I0
risk.index2 <- matrix(0,(N+1),1)
risk.index2[1] <- I0

sim.res <- foreach(p=1:nsim, .combine=rbind) %dopar% {

set.seed(nsim*p)
Z1 <- rnorm(N)
N.Poisson <- rpois(N, lambda.p*delta.t)

for(i in 1:N){
if(N.Poisson[i]>0){
Z2 <- exp(rnorm(N.Poisson[i])*delta + kv) - 1
}else{
Z2 <- 0
}
incr1 <- (mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i) )*delta.t +
sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) + sum(Z2)
risk.index1[i+1] <- risk.index1[i] + incr1*risk.index1[i]

incr2 <- (mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i) )*delta.t +
sigmat(delta.t*i)*Z1[i]*sqrt(delta.t)
risk.index2[i+1] <- risk.index2[i] + incr2*risk.index2[i]
}

PV.jumps    <- exp(-r*T)*(F - w*F*(max(risk.index1)>=K))
PV.brownian <- exp(-r*T)*(F - w*F*(max(risk.index2)>=K))
c(PV.jumps, PV.brownian, EPV.formula)
}

# Variance reduction technique (as in part4_cat_price_vrt.R)
diffprice.GBM  <- sim.res[,2] - sim.res[,3]
coeff          <- cov(sim.res[,1], diffprice.GBM) / var(diffprice.GBM)
adjustedprice.PJD <- sim.res[,1] - coeff*diffprice.GBM
value.sim1     <- mean(adjustedprice.PJD)

# Confidence interval
se       <- sd(adjustedprice.PJD) / sqrt(nsim)
ci_lower <- value.sim1 - 1.96*se
ci_upper <- value.sim1 + 1.96*se
ci_width <- ci_upper - ci_lower
yield    <- -log(value.sim1/F)/T - r

results <- rbind(results, data.frame(
N = N, nsim = nsim,
Price    = round(value.sim1, 2),
CI_Lower = round(ci_lower, 2),
CI_Upper = round(ci_upper, 2),
CI_Width = round(ci_width, 2),
Yield    = round(yield, 4)
))
}
}
print(results)

# Pricing for three values of lambda, based on the sensitivity analysis we use N = 500 and nsim = 6500.
# The code below is run three times, changing lambda each time for lambda = 0.05 (low), lambda = 0.30 (moderate), lambda = 0.70 (high)

N    = 500
nsim = 6500

# Change lambda for each run
lambda = 0.05  # change to 0.30 or 0.70 for the other runs

# GBM formula (needed for variance reduction technique)
delta1      <- mu - lambda*sigma
d1          <- (log(I0/K) + (delta1 - sigma^2/2)*T) / (sigma*T^0.5)
d2          <- (log(I0/K) - (delta1 - sigma^2/2)*T) / (sigma*T^0.5)
E           <- pnorm(d1) + (I0/K)^(1 - 2*delta1/sigma^2)*pnorm(d2)
EPV.formula <- exp(-r*T)*(F - w*F*E)

delta.t <- T/N
risk.index1 <- matrix(0,(N+1),1)
risk.index1[1] <- I0
risk.index2 <- matrix(0,(N+1),1)
risk.index2[1] <- I0

# PJD simulation with variance reduction
sim.res <- foreach(p=1:nsim, .combine=rbind) %dopar% {

set.seed(nsim*p)
Z1 <- rnorm(N)
N.Poisson <- rpois(N, lambda.p*delta.t)

for(i in 1:N){
if(N.Poisson[i]>0){
Z2 <- exp(rnorm(N.Poisson[i])*delta + kv) - 1
}else{
Z2 <- 0
}
incr1 <- (mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i))* delta.t +
sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) + sum(Z2)
risk.index1[i+1] <- risk.index1[i] + incr1*risk.index1[i]

incr2 <- (mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i))* delta.t +
sigmat(delta.t*i)*Z1[i]*sqrt(delta.t)
risk.index2[i+1] <- risk.index2[i] + incr2*risk.index2[i]
}

PV.jumps    <- exp(-r*T)*(F - w*F*(max(risk.index1)>=K))
PV.brownian <- exp(-r*T)*(F - w*F*(max(risk.index2)>=K))
c(PV.jumps, PV.brownian, EPV.formula)
}

# Variance reduction technique
diffprice.GBM     <- sim.res[,2] - sim.res[,3]
coeff             <- cov(sim.res[,1], diffprice.GBM) / var(diffprice.GBM)
adjustedprice.PJD <- sim.res[,1] - coeff*diffprice.GBM
value.sim1        <- mean(adjustedprice.PJD)

# Prices 1 and 2 should be close, prices 3 and 4 should be close
cat("Lambda: ", lambda,  "\n")
cat("Price (PJD with VRT): ", value.sim1,  "\n")
cat("Price (PJD without VRT): ", colMeans(sim.res)[1],  "\n")
cat("Price (GBM simulation): ", colMeans(sim.res)[2],  "\n")
cat("Price (GBM formula): ", colMeans(sim.res)[3],  "\n")

# Yields
yield.sp1 <- -log(value.sim1/F)/T - r
yield.sp2 <- -log(colMeans(sim.res)[1]/F)/T - r
yield.sp3 <- -log(colMeans(sim.res)[2]/F)/T - r
yield.sp4 <- -log(colMeans(sim.res)[3]/F)/T - r

cat("Yield (PJD with VRT): ", yield.sp1,  "\n")
cat("Yield (PJD without VRT): ", yield.sp2,  "\n")
cat("Yield (GBM simulation): ", yield.sp3,  "\n")
cat("Yield (GBM formula): ", yield.sp4,  "\n")
