mypairs <- function(mytable) {
  pairs(mytable,
    # pairs draws scatter plots on both triangles by default
    # but one can personalize each triangle with custom functions
    upper.panel = function(x, y) {
      # we won't report p-values smaller than this
      minp = 1.E-120
      # we use spearman rank correlation just in case..
      # but we must turn off the exact p-value calculation
      mytest = cor.test(x, y, method='spearman', exact=F)
      # coordinates for custom charts and texts
      myx = (max(x,na.rm=T) + min(x,na.rm=T)) / 2
      myy = (max(y,na.rm=T) + min(y,na.rm=T)) / 2
      # we draw points with sizes and color intensities varying with the
      # extent of the correlation
      points( myx, myy, pch=16, xaxt='n', yaxt='n', xlab='', ylab='',
        col = ifelse( mytest$estimate < 0,
          rgb(t(c(0,0,1)), alpha = abs(mytest$estimate)),
          rgb(t(c(1,0,0)), alpha = abs(mytest$estimate))
        ),
        cex = 20*abs(mytest$estimate)
      )
      if(mytest$p.value > minp) {
          text(myx, myy, sprintf('p=%.2G', mytest$p.value))
      } else text(myx, myy, sprintf('p<%.2G', minp))
    }
  )
}

