shr.ibd.basic <- function(id.pairs) {
  ### setup ibd jobs
  source("ibd.pairs.R")
  ibd.pairs(id.pairs)

  rcmd.1 <- "source(\"ibd.summary.R\")"
  rcmd.2 <- paste("ibd.summary(\"",id.pairs,"\")",sep="")
  write(c(rcmd.1,rcmd.2),paste("rcmd.ibd.summary.pairs.",id.pairs,sep=""),ncol=1)
  write(paste("R --vanilla < rcmd.ibd.summary.pairs.",id.pairs,sep=""),
        paste("cmd.ibd.summary.pairs.",id.pairs,sep=""))
}
