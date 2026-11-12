# New investigation results only; keep separate from the report-based figures.
x <- read.csv("results/generated/investigation-2026-11-12/summary.csv")
x <- x[x$N==500,]
y <- read.csv("results/generated/continuous-benchmark-2026-11-12/summary.csv")
for(format in c("png","svg")) {
  file <- paste0("assets/figures/estimator_investigation.",format)
  if(format=="png") png(file,width=1600,height=900,res=160)
  else svg(file,width=10,height=5.625)
  par(mfrow=c(1,2),mar=c(6.8,4.4,4.2,1),oma=c(1.2,0,0,0),las=1)
  colors <- c("#536170","#087E8B","#B86820","#18354D")
  # Differences relative to the independently estimated continuous benchmark.
  # Intervals combine MC uncertainty from separate seed ranges, not model uncertainty.
  position <- 1:3
  series <- c("raw","original_vrt","bridge_crossfit")
  errors <- c("raw_mean_se","original_mean_se","crossfit_mean_se")
  plot(0,0,type="n",xlim=c(.7,3.3),ylim=c(-4,15),xaxt="n",bty="l",
    xlab="Market price of risk",ylab="Price minus continuous benchmark (USD)",
    main="Different targets, different estimates",cex.main=.92)
  axis(1,at=position,labels=sprintf("%.2f",x$lambda))
  abline(h=0,lty=2,col=colors[4]);abline(h=c(5,10,15),col="#E8EDF1")
  for(i in 1:3) {
    value <- x[[series[i]]]-y$continuous_pjd
    se <- sqrt(x[[errors[i]]]^2+y$se^2)
    pos <- position+(i-2)*.12
    arrows(pos,value-1.96*se,pos,value+1.96*se,angle=90,code=3,length=.035,col=colors[i])
    points(pos,value,pch=c(15,19,17)[i],col=colors[i],cex=1.1)
  }
  legend("topright",c("Raw Euler/grid","Original VRT","Bridge control (grid target)"),
    pch=c(15,19,17),col=colors[1:3],bty="n",cex=.72)
  mtext("Means of 100 x 2,000 paths; N=500\nBars: combined 95% Monte Carlo uncertainty",side=1,line=4.7,cex=.65)
  bars <- barplot(x$variance_reduction_factor,names.arg=sprintf("%.2f",x$lambda),
    col=colors[2],border=NA,ylim=c(0,6.3),xlab="Market price of risk",
    ylab="Raw variance / original VRT variance",main="Real reduction in sampling variance",cex.main=.92)
  text(bars,x$variance_reduction_factor+.25,sprintf("%.2fx",x$variance_reduction_factor),cex=.9)
  abline(h=1,lty=2,col=colors[1])
  mtext("Empirical variance of 100 experiment means\nA variance factor is not a runtime speedup",side=1,line=4.7,cex=.65)
  mtext("New investigation, 12 November 2026. Fixed report inputs; continuous benchmark: 200,000 paths per scenario.",
    outer=TRUE,side=1,line=0,cex=.7)
  dev.off()
}
