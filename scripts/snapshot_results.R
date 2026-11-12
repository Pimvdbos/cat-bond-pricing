# Curate aggregate results; never publish raw market data, serialized fit environments or caches.
# Run after reproduce.R, compare_report.R, estimation_diagnostics.R and both investigations.
date <- "2026-11-12"
for(kind in c("reproduction","investigation","continuous-benchmark")) {
  source <- readLines(paste0("results/generated/latest-",kind,".txt"))
  destination <- paste0("results/generated/",kind,"-",date)
  if(dir.exists(destination)) stop("Snapshot already exists; preserve it or choose a new dated snapshot.")
  dir.create(destination)
  files <- list.files(source,pattern="\\.(csv|R|txt)$",full.names=TRUE)
  stopifnot(all(file.copy(files,destination)))
  # Session information is kept, but refuse personal paths before publication.
  text_files <- list.files(destination,full.names=TRUE)
  for(file in text_files) {
    lines <- readLines(file,warn=FALSE)
    if(any(grepl("[A-Za-z]:[/\\\\]Users[/\\\\]",lines))) stop("Personal path found in snapshot: ",basename(file))
    writeLines(sub("[ \\t]+$","",lines),file,useBytes=TRUE)
  }
  source_files <- c(list.files("R",full.names=TRUE),list.files("scripts",pattern="\\.R$",full.names=TRUE),"config/default.R")
  write.csv(data.frame(file=source_files,sha256=vapply(source_files,function(f)digest::digest(file=f,algo="sha256"),character(1))),
    file.path(destination,"source-checksums.csv"),row.names=FALSE)
  writeLines(c(paste("Published snapshot:",date),paste("Execution directory:",basename(source)),
    "Only aggregate results, configurations and session/provenance records are included."),file.path(destination,"SNAPSHOT.txt"))
}
