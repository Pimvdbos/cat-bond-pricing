# Compare fresh outputs to published rounding, without writing into reported/.
# Rscript --vanilla scripts/compare_report.R [reproduction-directory]
args <- commandArgs(trailingOnly=TRUE)
out <- if(length(args)) args[1] else readLines("results/generated/latest-reproduction.txt")
read <- function(root,file) read.csv(file.path(root,file),check.names=FALSE,stringsAsFactors=FALSE)
reported <- "results/reported"
records <- list()
add <- function(table,key,field,report,value,digits) {
  text <- as.character(report)
  match <- if(startsWith(text,"<")) value < as.numeric(sub("<","",text)) else
    abs(round(value,digits)-as.numeric(text)) < 10^(-digits)*1e-5
  records[[length(records)+1L]] <<- data.frame(table=table,key=key,field=field,
    reported=text,reproduced=value,published_decimals=digits,matches_published_rounding=match,
    difference=if(startsWith(text,"<")) NA_real_ else value-as.numeric(text))
}
for(t in 1:7) {
  file <- list.files(reported,paste0("^table_",t,"_"))
  a <- read(reported,file); b <- read(out,file)
  if(t==1) {
    for(i in seq_len(nrow(a))) for(f in c("jumps","diffusion_observations","initial_jump_frequency"))
      add(t,a$epsilon[i],f,a[[f]][i],b[[if(f=="diffusion_observations") "diffusion" else f]][match(a$epsilon[i],b$epsilon)],if(f=="initial_jump_frequency")3 else 0)
  } else if(t==2) {
    for(i in seq_len(nrow(a))) for(f in names(a)[-1])
      add(t,a$parameter[i],f,a[[f]][i],b[[f]][match(a$parameter[i],b$parameter)],3)
  } else if(t==3) {
    for(i in seq_len(nrow(a))) add(t,a$run[i],"log_likelihood",a$log_likelihood[i],b$log_likelihood[match(a$run[i],b$run)],4)
  } else if(t==4) {
    for(i in seq_len(nrow(a))) add(t,a$statistic[i],"value",a$value[i],b$value[match(a$statistic[i],b$statistic)],if(a$statistic[i]=="degrees_of_freedom")0 else 4)
  } else if(t==5) {
    for(i in seq_len(nrow(a))) add(t,a$parameter[i],"value",a$value[i],b$value[match(a$parameter[i],b$parameter)],if(a$parameter[i]=="risk_free_rate")2 else 1)
  } else if(t==6) {
    for(i in seq_len(nrow(a))) for(f in names(a)[-(1:2)]) {
      j <- which(b$N==a$N[i]&b$nsim==a$nsim[i])
      add(t,paste(a$N[i],a$nsim[i],sep="/"),f,a[[f]][i],b[[f]][j],2)
    }
  } else {
    for(i in seq_len(nrow(a))) for(f in c("pjd_price_vrt","spread_vrt","pjd_price_no_vrt","spread_no_vrt"))
      add(t,a$market_price_of_risk[i],f,a[[f]][i],b[[f]][match(a$market_price_of_risk[i],b$market_price_of_risk)],if(grepl("spread",f))4 else 2)
  }
}
comparison <- do.call(rbind,records)
write.csv(comparison,file.path(out,"comparison.csv"),row.names=FALSE)
print(aggregate(matches_published_rounding~table,comparison,function(x)paste(sum(x),"/",length(x))))
