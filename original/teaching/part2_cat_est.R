# load libraries
# (install first if needed using install.packages command)

library(doMC)
registerDoMC(cores=24)
library(readxl)
library(maxLik)
library(geostats) # for example of real world data

# load functions

source("functions.R")


#############################################################################################################################
# REAL WORLD estimation

# Take log returns on some cat index
# We use that, for a Poisson jump diffusion, 
# *****conditional on the number of jumps******, 
# the log returns over delta(t) follow a Normal distribution 
# with parameters mu and sigma^2 

# We use real life monthly data on some risk index I found via Google Dataset Search
# (See https://www.openicpsr.org/openicpsr/project/154781/version/V1/view?path=/openicpsr/154781/fcr:versions/V1/data_paper/data_gpr_export.xls&type=file)
# (Meaning and relevance is omitted here --> in your assignment it will be very important)
# (Don't use this example dataset for your assignment!)

# We estimate the parameters mu and sigma (as well as delta, lambda.p and kv, see set_param.R) 
# using Maximum Likelihood (ML) estimation
# Maximum likelihood estimation: choose the parameters that 
# maximize the probability (likelihood) that the
# observed data occurs


#############################################################################################################################

# First we create and plot log returns

cat.data=as.data.frame(read_excel("monthly_risk_index.xlsx"))
attach(cat.data)
return.cat=log(GPRHA[2:nrow(cat.data)]/GPRHA[1:(nrow(cat.data)-1)])
plot(return.cat, type="l")

N= length(return.cat)  # nyears*12-1
delta.t=1/12 # monthly data
#nyears= 121 # 1900 until end of 2020

# ML requires a vector of starting values for the (relevant) parameters
# They are obtained below, using a simple way known from the properties of 
# Poisson jump diffusions set out in the literature
# Requires an initial choice for epsilon
# You will have to try different values for the choice of epsilon (= subjective choice)

epsilon=0.4
# jump data
jumpindex=which(abs(return.cat)>epsilon)
lambdap_hat=length(jumpindex)/((length(return.cat))*delta.t) 
Rjumps=return.cat[jumpindex]
# non-jump data
diffusionindex=which(abs(return.cat)<=epsilon)
Rdiffusion=return.cat[diffusionindex]

# crude estimation parameters for non-jump part
sigma_hat=sd(Rdiffusion)/sqrt(delta.t)
mu_hat=(2*mean(Rdiffusion)+(sigma_hat^2)*delta.t)/(2*delta.t) 
# crude estimation parameters for non-jump part
delta_hat=sqrt((var(Rjumps)-sigma_hat^2*delta.t))
kv_hat=mean(Rjumps)-(mu_hat-sigma_hat^2/2)*delta.t

param.init=c(mu_hat, sigma_hat, delta_hat, lambdap_hat, kv_hat)

# Next we perform ML estimation applied to log returns
# Important: For reliable ML estimation we need enough data!
# A sufficiently long time horizon of daily data will usually help a great deal

# You may also want to check out the R packages sde and yuima instead!
# These package can also help you to estimate the parameters

# load the code with the ML function

source("LL.R")

# To maximize the LL function sum(LogLik)
# We need a numerical optimization routine
# We use the one in the library maxLik

# Choose the BHHH algorithm for the optimization and
# Set the max number of iterations large enough

outp=maxLik(LL,start=param.init, method="BHHH",  control=list(iterlim=1000))

# look at output
outp # summarizes the estimation
summary(outp) # gives all relevant estimation output!
outp$est # only gives the estimated parameters

write.table(outp$est,file="est_param.txt")

# Estimated parameters look okay, although mean is negative 
# Negative value is not impossible, but we should also know from the literature that 
# often it turns out  hard to estimate mu accuratelty
# Accurate estimation requires long samples