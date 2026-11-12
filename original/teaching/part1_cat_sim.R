
# Set parameters for simulation

mu=0.2 # annual mean of Brownian motion part of index return
sigma=0.5 # annual variance of Brownian motion part of index return
lambda.p=10 # intensity of Poisson process
EU1=0.1 # mean of jump size in Poisson process, with log(1+U1) normally distributed, Uj-s iid
kv=log(1+EU1)
delta=0.2 # delta^2=Var(log(1+Uj))
T=1 # maturity of cat bond counted in years
I0=50 # starting value of the index

# number of steps in discretization
N=500  
# size of delta(t)
delta.t=T/N 


# Load some functions that are needed
source("functions.R")

# make matrices to store values in
sim.index1=matrix(0,(N+1),1)
sim.index1[1]=I0

sim.index2=matrix(0,(N+1),1)
sim.index2[1]=I0


#############################################################################################################################

# Simulate returns of Poisson jump diffusion in a case where there is at least one jump (--> while loop)
# The depicted are the resulting index prices
# We show the difference with index prices according to a pure geom. Brownian motion with no jump diffusion part
# Note: This is a REAL WORLD simulation

#############################################################################################################################


# Set a seed if you want somebody else to
# be able to simulate exactly the same data

set.seed(1234) 


# Below we simulate paths of length N 
# Because we want to compare a jump diffusion with a plain geom. Brownian motion
# We repeat our simulations until we really have simulated a path with at least one jump! 
# Without a jump, the jump diffusion is a geom. Brownian motion, making the comparison useless
# Therefore, we start here with a while loop. This loop ensures that we end up
# with a path with a jump and a plain geom. Brownian motion!

Z2=0

# start of while loop to ensure a path with a jump
while(sum(Z2)==0){

Z1=rnorm(N)
N.Poisson=rpois(N,(lambda.p*delta.t))

# start of simulation of paths of jump diffusion and geom. Brownian motion
for(i in 1:N){

if(N.Poisson[i]>0){
Z2=exp(rnorm(N.Poisson[i])*delta+kv)-1
}else{
Z2=0}

# simulate Poisson jump diffusion
# Eq.(3) of Vaugirard simulation paper

incr1=mut(delta.t*i)*delta.t + sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) + sum(Z2)
sim.index1[i+1]=sim.index1[i]+incr1*sim.index1[i]

# Also simulate pure geom. Brownian motion 
# Eq.(3) of Vaugirard simulation paper
# but with jump term left out

incr2=mut(delta.t*i)*delta.t + sigmat(delta.t*i)*Z1[i]*sqrt(delta.t) 
sim.index2[i+1]=sim.index2[i]+incr2*sim.index2[i]

}

}


# Remove # symbol if you want to save graphs to pdf
# pdf("graph_price_processes.pdf", width=12, height=8)

plot(sim.index1,type="s", col="blue", ylab="value of indices with and without jumps")
lines(sim.index2, type="s", col="red")
legend("topright", legend=c("GBM","PJD"),col=c("red","blue"),lty=c(1,1), lwd=c(2,2))

# GBM=geometric Brownian motion
# PJD=Poisson Jump Diffusion

# Turn off plotting device (only necessary if you make a pdf)
# dev.off()

