ibd.summary <- function(id.pairs)
{
  ######################
  lens <- c(1,2,3,5,10) 
  ######################
  n.lens <- length(lens)
  chrs <- paste("chr",c(1:22),sep="")

  pairs <- read.table(paste("pairs.",id.pairs,sep=""),
                      header=F,row.names=NULL,as.is=T)
  n.pairs <- nrow(pairs)

  len.mm <- matrix(rep(0,n.pairs*n.lens),ncol=n.lens)
  len.mf <- matrix(rep(0,n.pairs*n.lens),ncol=n.lens)
  len.fm <- matrix(rep(0,n.pairs*n.lens),ncol=n.lens)
  len.ff <- matrix(rep(0,n.pairs*n.lens),ncol=n.lens)

  lab.mm <- paste(pairs[,1],"m",pairs[,2],"m",sep="\t")
  lab.mf <- paste(pairs[,1],"m",pairs[,2],"f",sep="\t")
  lab.fm <- paste(pairs[,1],"f",pairs[,2],"m",sep="\t")
  lab.ff <- paste(pairs[,1],"f",pairs[,2],"f",sep="\t")

  for(chr in chrs) {
    dat <- read.table(paste(chr,".ibd.pairs.",id.pairs,sep=""),
                      header=F,row.names=NULL,as.is=T)
    dat$lab <- paste(dat[,2],dat[,3],dat[,4],dat[,5],sep="\t")
    dat$len <- dat[,11]-dat[,10]

    for(j in 1:n.lens) {
      if(any(dat$len >= lens[j])) {
        tdat <- dat[dat$len >= lens[j],]
        tlens <- unlist(lapply(split(tdat$len,tdat$lab),sum))
        n.tlens <- length(tlens)
        if(any(!is.na(match(names(tlens),lab.mm)))) {
          i.tlens <- c(1:n.tlens)[!is.na(match(names(tlens),lab.mm))]
          i.mm <- match(names(tlens)[i.tlens],lab.mm)
          len.mm[i.mm,j] <- len.mm[i.mm,j] + tlens[i.tlens]
        }
        if(any(!is.na(match(names(tlens),lab.mf)))) {
          i.tlens <- c(1:n.tlens)[!is.na(match(names(tlens),lab.mf))]
          i.mf <- match(names(tlens)[i.tlens],lab.mf)
          len.mf[i.mf,j] <- len.mf[i.mf,j] + tlens[i.tlens]
        }
        if(any(!is.na(match(names(tlens),lab.fm)))) {
          i.tlens <- c(1:n.tlens)[!is.na(match(names(tlens),lab.fm))]
          i.fm <- match(names(tlens)[i.tlens],lab.fm)
          len.fm[i.fm,j] <- len.fm[i.fm,j] + tlens[i.tlens]
        }
        if(any(!is.na(match(names(tlens),lab.ff)))) {
          i.tlens <- c(1:n.tlens)[!is.na(match(names(tlens),lab.ff))]
          i.ff <- match(names(tlens)[i.tlens],lab.ff)
          len.ff[i.ff,j] <- len.ff[i.ff,j] + tlens[i.tlens]
        }
      }

    }

  }

  rpt.pairs <- data.frame(pn1=I(pairs[,1]),pn2=I(pairs[,2]),
                          len1.ff=I(len.ff[,1]),
                          len1.fm=I(len.fm[,1]),
                          len1.mf=I(len.mf[,1]),
                          len1.mm=I(len.mm[,1]),
                          len2.ff=I(len.ff[,2]),
                          len2.fm=I(len.fm[,2]),
                          len2.mf=I(len.mf[,2]),
                          len2.mm=I(len.mm[,2]),
                          len3.ff=I(len.ff[,3]),
                          len3.fm=I(len.fm[,3]),
                          len3.mf=I(len.mf[,3]),
                          len3.mm=I(len.mm[,3]),
                          len5.ff=I(len.ff[,4]),
                          len5.fm=I(len.fm[,4]),
                          len5.mf=I(len.mf[,4]),
                          len5.mm=I(len.mm[,4]),
                          len10.ff=I(len.ff[,5]),
                          len10.fm=I(len.fm[,5]),
                          len10.mf=I(len.mf[,5]),
                          len10.mm=I(len.mm[,5]))
  write.table(rpt.pairs,paste("rpt.ibd.pairs.",id.pairs,sep=""),
              quote=F,row.names=F,col.names=F,sep="\t")

}
