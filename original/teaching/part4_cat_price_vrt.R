# Load libraries
# (Install first if needed using install.packages command)

# package needed for fast parallel computing
library(doMC)
registerDoMC(cores=24)

# Read  parameters that we estimated before using ML

param.est=as.matrix(read.table("est_param.txt", header=TRUE),5,1)

# next step is to use the estimated parameters to price a CAT bond

mu=param.est[1]
sigma=param.est[2]
delta=param.est[3]
lambda.p=param.est[4]
kv=param.est[5]

# Now propose some cat bond and set the parameters right
# For instance:

F=100 # face value
I0=80 # starting value of the index
K=100 # threshold for the option (make sure I0/K<1!!!)
T=1 # maturity of cat bond counted in years
w=0.4 # fraction of the face value that is lost if the index exceeds the attachment point prior to maturityr=0.05 # risk-free rate, choose appropriate value yourself

# Not estimated, guess, needs sensitivity analysis in pricing later on!!!
lambda=0.1 

# load functions

source("functions.R")

#############################################################################################################################
# RISK NEUTRAL WORLD pricing
# Based on the Vaugirard paper
#############################################################################################################################

#### STEP 1

# FIRST USE PRICING FORMULA FOR CASE ***WITHOUT*** JUMPS
# Will not give the right price because of the jumps
# But is needed for the variance reduction technique

delta1=mu-lambda*sigma
d1=(log(I0/K)+(delta1-sigma^2/2)*T)/(sigma*T^0.5)
d2=(log(I0/K)-(delta1-sigma^2/2)*T)/(sigma*T^0.5)

E=pnorm(d1)+(I0/K)^(1-2*delta1/sigma^2)*pnorm(d2)

EPV.formula=exp(-r*T)*(F-w*F*E)   
		
EPV.formula

#### STEP 2 

# RISK NEUTRAL WORLD simulation for pricing purposes
# We use simulation to price a cat bond assuming a PJD
# We make use of  control variates as a variance reduction technique

N=500 # number of steps used in discretization; does not have to be the same as in part 2!!
delta.t=T/N  # does not have to be the same as in part 2!!

# Note that N and delta.t do not have to be equal
# to the values corresponding to our data used to estimate the parameters 
# The values below are chosen ad hoc and need a sensitivity check
# Especially if K and I0 are close delta.t has to be small enough
# as pointed out in Vaugirard paper

nsim=5000 # number of simulations (nsim simulation runs form 1 simulation experiment)

risk.index1=matrix(0,(N+1),1)
risk.index1[1]=I0

risk.index2=matrix(0,(N+1),1)
risk.index2[1]=I0


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

incr1=(mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i))*delta.t + sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) + sum(Z2)
risk.index1[i+1]=risk.index1[i]+incr1*risk.index1[i]

incr2=(mut(delta.t*i) - lambdat(delta.t*i)*sigmat(delta.t*i))*delta.t + sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) 
risk.index2[i+1]=risk.index2[i]+incr2*risk.index2[i]


}

PV.jumps=exp(-r*T)*(F-w*F*(max(risk.index1)>=K))     
PV.brownian=exp(-r*T)*(F-w*F*(max(risk.index2)>=K)) 

c(PV.jumps, PV.brownian, EPV.formula)


}

save(list = ls(all=TRUE), file = "part4_cat_price_vrt.RData")

# If you have run the above once and saved the RData file, you can 
# always run the code below again if you first load the saved file
# load("part4_cat_price_vrt.RData")

# Below take means to approximate expected present values, but with a slight adjustment
# We apply the variance reduction technique discussed in Vaugirard, but slightly different
# He uses coeff=1 (=fixed to 1), while we set this coefficient in an optimal way

diffprice.GBM=sim.res[,2]-sim.res[,3] # price difference between GBM simulation and formula
coeff=cov(sim.res[,1],diffprice.GBM)/var(diffprice.GBM)
adjustedprice.PJD=sim.res[,1]-coeff*diffprice.GBM # adjusted price based on PJD
value.sim1=mean(adjustedprice.PJD) # price 1: simulation of jump diffusion + variance reduction technique

c(value.sim1,colMeans(sim.res))

# 1: price (EPV under RN measure) using PJD + variance reduction technique 
# 2: price (EPV under RN measure) using PJD but no variance reduction 
# 3: price (EPV under RN measure) using simulation with GBM part 
# 4: price (EPV under RN measure) using the formula that assumes a GBM (no simulation, but exact calculation)
# Price 4 Does not vary over the simulation runs, so taking the average of this column is a bit silly 
# (but easy because of the use of the colMeans command)

### sanity check:
### prices 1 and 2 should be close to each other
### prices 3 and 4 should also be close to each other

write.table(c(value.sim1,colMeans(sim.res)), file="part4_cat_price_vrt.txt")


# Instead of looking at prices
# We could calculate the yield corresponding to prices and the resulting yield spread (using risk free rate)
# Yield Y is such that F*exp(-Y*T)=price
# Yield spread is differencd relative to risk free rate
# See also Vaugirard article

yield.sp1=-log(value.sim1/F)/T-r
yield.sp2=-log(colMeans(sim.res)[1]/F)/T-r
yield.sp3=-log(colMeans(sim.res)[2]/F)/T-r
yield.sp4=-log(colMeans(sim.res)[3]/F)/T-r

c(yield.sp1,yield.sp2,yield.sp3,yield.sp4)

write.table(c(yield.sp1,yield.sp2,yield.sp3,yield.sp4), file="part4_cat_yield_vrt.txt")

