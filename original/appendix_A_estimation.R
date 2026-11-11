# Reconstructed from PDF Listing A. Not the unavailable original source.
# See docs/code_provenance.md before execution.
library(maxLik)
source( "functions.R")
source( "LL.R")

# Load the ACE data and compute log returns
cat.data = read.csv( "ace-north-atlantic-hurricanes.csv")
ACE = cat.data$Accumulated.cyclone.energy.index
return.cat = log(ACE[2:length(ACE)] / ACE[1:(length(ACE)-1)])
N = length(return.cat)
delta.t = 1 # annual data

summary(return.cat)

# Try different epsilon values to find a good split between jumps and diffusion
for (eps in c(0.8, 1.0, 1.2)) {
jumpindex_temp = which(abs(return.cat) > eps)
cat("Epsilon: ", eps,
" | Jumps: ", length(jumpindex_temp),
" | Lambda: ", length(jumpindex_temp) / (N * delta.t),  "\n")
}

# We go with epsilon = 1.0 as it gives a reasonable number of jumps
epsilon = 1.0
jumpindex = which(abs(return.cat) > epsilon)
diffusionindex = which(abs(return.cat) <= epsilon)
Rjumps = return.cat[jumpindex]
Rdiffusion = return.cat[diffusionindex]

# Compute starting values for MLE
sigma_hat = sd(Rdiffusion) / sqrt(delta.t)
mu_hat = (2*mean(Rdiffusion) + (sigma_hat^2)*delta.t) / (2*delta.t)
lambdap_hat = length(jumpindex) / (N * delta.t)
delta_hat = sqrt(abs(var(Rjumps) - sigma_hat^2*delta.t))
kv_hat = mean(Rjumps) - (mu_hat - sigma_hat^2/2)*delta.t

param.init = c(mu_hat, sigma_hat, delta_hat, lambdap_hat, kv_hat)
print(param.init)

# Run MLE
outp = maxLik(LL, start=param.init, method= "BHHH", control=list(iterlim =1000))
summary(outp)
est.param = outp$estimate

# Verify we found the global maximum by trying 10 different starting points
set.seed(123)
results = list()
for (i in 1:10) {
start_perturbed = param.init * runif(5, 0.5, 1.5)
try({
fit = maxLik(LL, start=start_perturbed, method= "BHHH", control=list (iterlim=1000))
results[[i]] = c(fit$maximum, fit$estimate)
})
}

for (i in 1:10) {
if (!is.null(results[[i]])) {
cat("Run ", i,  " - LogLik: ", results[[i]][1],  "\n")
}
}
