# Likelihood function for each return observation = pdf evaluated in returns
# Conditional on the number of jumps, log returns are normal
# We use conditioning to get the unconditional pdf,
# meaning that we multiply the normal pdf by the poisson pdf and 
# sum over the number of jumps  during delta.t

njumps=50  
# during a sufficiently small timer interval the number of jumps will usually be small (0 or 1)
# (property of Poisson distribution)
# so njumps=50 is a safe choice if your delta.t is small enough, 
# but you may want to run a robustness check
# by changing this number

LL<-function(param){

# input is a vector param=c(mu, sigma, delta, lambda.p, kv)
# return data (in the vector return.cat) is a global variable

mu=param[1]
sigma=param[2]
delta=param[3]
lambda.p=param[4]
kv=param[5]

total.dens=0

for (k in 0:njumps){

# mean and sd of normal distribution associated with log returns over delta.t
mean.norm=(mu-sigma^2/2)*delta.t+k*kv
sigma.norm=sqrt(sigma^2*delta.t+k*delta^2)

# we use the pdf conditional on k jumps
# and condition out the number of jumps bij multiplying by the Poisson pdf

total.dens=total.dens + dpois(k, lambda=(lambda.p*delta.t))*dnorm(return.cat, mean=mean.norm, sd=sigma.norm)

}

LogLik=log(total.dens) 
# Loglik returns a vector with the loglikelihood for each return
# the summation to get the total loglikelihood is done by the optimization algorithm
# See the help of the maxlik function in R

return(LogLik) 

}
