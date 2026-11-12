# Load libraries
# (Install first if needed using install.packages command)

# package needed for fast parallel computing
library(doMC)
registerDoMC(cores=24)

# Read  parameters that we estimated before using MLE

param.est=as.matrix(read.table("est_param.txt", header=TRUE),5,1)

# next step is to use the estimated parameters to price a CAT bond

mu=param.est[1]
sigma=param.est[2]
delta=param.est[3]
lambda.p=param.est[4]
kv=param.est[5]


# Now propose some cat bond and set the parameters right
# For instance: (change these values for your assignment!)

F=100 # face value
I0=80 # starting value of the index
K=100 # threshold for the option (make sure I0/K<1!!!)
T=1 # maturity of cat bond counted in years
w=0.4 # fraction of the face value that is lost if the index exceeds the attachment point prior to maturity
r=0.05 # risk-free rate, choose appropriate value yourself

# Not estimated, guess, needs sensitivity analysis in pricing later on!!!
lambda=0.1 


# load functions

source("functions.R")


#############################################################################################################################
# RISK NEUTRAL WORLD pricing
# Based on the Vaugirard paper
# We use simulation to price a cat bond assuming a Poisson jump diffusion
#############################################################################################################################

N=500 # number of steps used in discretization; does not have to be the same as in part 2!!
delta.t=T/N  # does not have to be the same as in part 2!!

# Note that N and delta.t do not have to be equal
# to the values corresponding to our data used to estimate the parameters 
# The values below are chosen ad hoc and need a sensitivity check
# Especially if K/I0<1 but close to 1, then  delta.t has to be small enough
# as pointed out in Vaugirard paper

nsim=5000 # number of simulations (nsim simulation runs form 1 simulation experiment)

risk.index=matrix(0,(N+1),1)
risk.index[1]=I0

# Extra information:
# %dopar%: We make use of parallel computing for faster results, change %dopar% into %do% and
# you turn off this feature

sim.res<-foreach(p=1:nsim, .combine=rbind) %dopar% {

# ensure reproducability of random numbers used
set.seed(nsim*p)

Z1=rnorm(N)
N.Poisson=rpois(N,lambda.p*delta.t)

for(i in 1:N){

if(N.Poisson[i]>0){
Z2=exp(rnorm(N.Poisson[i])*delta+kv)-1
}else{
Z2=0}

incr=(mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i))*delta.t + sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) + sum(Z2)
risk.index[i+1]=risk.index[i]+incr*risk.index[i]

}

PV=exp(-r*T)*(F-w*F*(max(risk.index)>=K))     

PV


}

save(list = ls(all=TRUE), file = "part3_cat_price.RData")

# If you have run the above and saved the RData file, you can 
# always run the code below again if you first load the saved file
# load("part3_cat_price.RData")

mean(sim.res)

write.table(mean(sim.res), file="part3_cat_price.txt")


# Instead of looking at prices
# We could calculate the yield corresponding to prices and the resulting yield spread 
# (using risk free rate)
# Yield Y is such that F*exp(-Y*T)=price
# Yield spread is difference relative to risk free rate
# See also Vaugirard article

-log(mean(sim.res)/F)/T-r

write.table(-log(mean(sim.res)/F)/T-r, file="part3_cat_yield.txt")


