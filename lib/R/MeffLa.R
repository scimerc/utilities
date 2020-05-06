corr.matrix<-read.table("correlation.matrix")
SNPnames<-read.table("SNP.names")

## Remove Duplicate Columns:
corr.matrix.RemoveDupCol <- corr.matrix[!duplicated(abs(corr.matrix))]

## Remove Duplicate Rows:
corr.matrix.RemoveDupRow <- unique(abs(corr.matrix.RemoveDupCol))

## Remove Redundant SNP Names:
SNPnames.NonRedundant <- as.matrix(SNPnames[t(!duplicated(abs(corr.matrix)))])
dimnames(SNPnames.NonRedundant)[[2]][1]<-"SNP"

#evals<-La.eigen(t(corr.matrix.RemoveDupRow),symmetric=T,method="dsyevr")$values
evals<-eigen(t(corr.matrix.RemoveDupRow),symmetric=T)$values


oldV<-var(evals)
M<-length(evals)
L<-(M-1)
Meffold<-M*(1-(L*oldV/M^2))

if (evals == 1) { 
  oldV <- 0 
  Meffold <- M
}


labelevals<-array(dim=M)
for(col in 1:M) { labelevals[col]<-c(col) }
levals<-cbind(labelevals, evals)

newevals<-evals
for(i in 1:length(newevals)) { 
  if(newevals[i] < 0) { 
    newevals[i] <- 0
  }
}

newlevals<-cbind(labelevals, newevals)

newV<-var(newevals)
Meffnew<-M*(1-(L*newV/M^2))

if (evals == 1) { 
  newV <- 0 
  Meffnew <- M
}

NewResulttemp<-c('Effective Number of Independent Marker Loci [Meff] (-ve values set to zero):', round(Meffnew,dig=4))
NewBonferronitemp<-c('Experiment-wide Significance Threshold Required to Keep Type I Error Rate at 5%:', 1-(0.95^(1/Meffnew)))
NewEigenvaluestemp<-c('New Eigenvalues Associated with the Correlation Matrix:', round(newevals,dig=4))
NewVariancetemp<-c('Variance of the Eigenvalues (with -ve values set to zero):', round(newV,dig=4))

NewResult<-matrix(NewResulttemp)
NewBonferroni<-matrix(NewBonferronitemp)
NewEigenvalues<-matrix(NewEigenvaluestemp)
NewVariance<-matrix(NewVariancetemp)

Originaltemp<-c('Original (total) number of marker loci (M) after removing redundant SNPs:',
                ' ', M)

OldEigenvalues1temp<-c(' ',
                       'For factor 1 to M, original eigenvalues associated with the LD correlation matrix:')
OldEigenvalues2temp<-round(newlevals,dig=4)

OldVariancetemp<-c(' ',
                   'Variance of the observed eigenvalues:', 
                   ' ', round(newV,dig=4))

OldResulttemp<-c(' ',
                 'Effective number of independent marker loci [Meff]:', 
                 ' ', round(Meffnew,dig=4))

OldBonferronitemp<-c(' ',
                     'Experiment-wide significance threshold required to keep Type I error rate at 5%:', 
                     ' ', 0.05/Meffnew)

Original<-matrix(Originaltemp)

OldResult<-matrix(OldResulttemp)
OldBonferroni<-matrix(OldBonferronitemp)
OldEigenvalues1<-matrix(OldEigenvalues1temp)
OldEigenvalues2<-OldEigenvalues2temp
OldVariance<-matrix(OldVariancetemp)

no.dimnames <- function(a) {
  ## Remove all dimension names from an array for compact printing.
  d <- list()
  l <- 0
  for(i in dim(a)) {
    d[[l <- l + 1]] <- rep("", i)
  }
  dimnames(a) <- d
  a
}

  sink("results1.out")
  print(no.dimnames(Original), quote=F)
  print(no.dimnames(OldEigenvalues1), quote=F)
  print(no.dimnames(OldEigenvalues2), quote=F)
  print(no.dimnames(OldVariance), quote=F)
  print(no.dimnames(OldResult), quote=F)
  print(no.dimnames(OldBonferroni), quote=F)
  sink()

Warningtemp<-c(' ',
               '### Warning ###: there were some negative eigenvalues!',
               'If the above results using negative eigenvalues are equivalent',
               'to the following - obtained by setting negative eigenvalues to zero -',
               'then the results should be fine.',
               ' ')
Warning<-matrix(Warningtemp)

if(any(evals < 0)) { 
  sink("results1.out")
  print(no.dimnames(Original), quote=F)
  print(no.dimnames(OldEigenvalues1), quote=F)
  print(no.dimnames(OldEigenvalues2), quote=F)
  print(no.dimnames(OldVariance), quote=F)
  print(no.dimnames(OldResult), quote=F)
  print(no.dimnames(OldBonferroni), quote=F)
  sink()
}

#=============================================================================
# Perform VARIMAX Rotation to Sharpen SNP Loadings to Particular Eigenvectors

# Compute the singular-value decomposition
svdout <- La.svd(t(corr.matrix.RemoveDupRow),method = "dgesdd")

# Get the eigenvalues from the singular-value decomposition
svdevals <- svdout$d

# Get the standard deviations of the principal components 
# (i.e., sqrt of the eigenvalues) from the singular-value decomposition
svdsdev <- sqrt(svdevals)

# Specify the Number of Factors to Extract
factors<-M

# Matrix of Variable Loadings (i.e., a matrix whose columns contain the eigenvectors)

Laloadings <- svdout$u

# Principal Component Coefficients for Unrotated Matrix

coefficients <- Laloadings [ ,1:factors ] %*% diag ( svdsdev[1:factors] )

# Principal Component Coefficients for Varimax Rotated Matrix
vrcoefficients <- varimax ( coefficients ) $loadings 

# Squared Principal Component Coefficients [eigenvectors] for Varimax Rotated Matrix
vrcoefficients2 <- vrcoefficients^2

# Sum of Squared Principal Component Coefficients for Varimax Rotated Matrix (i.e., eigenvalues)
vevals <- apply(vrcoefficients, 2, function(x) sum(x^2) )

lvevals<-cbind(labelevals, vevals, vevals/cumsum(vevals)[M])

dimnames(lvevals)[[2]][1]<-"Eigenvalue"
dimnames(lvevals)[[2]][2]<-"Cumulative proportion of variance"

# Find the Maximum Value making up each Factor's Rotated Eigenvalue
vmaxvalues<-array(dim=M)
for(col in 1:M) { vmaxvalues[col]<-c(round(max(vrcoefficients2[,col]),dig=8))
}

# Designate which SNP Contributes the Most to each Rotated Eigenvalue
vindependent<-matrix(data=0,nrow=M,ncol=M)
for(col in 1:M) {
for(row in 1:M) {
if(round(vrcoefficients2[row,col],dig=8) == vmaxvalues[col])
vindependent[row,col]<-1
if(round(vrcoefficients2[row,col],dig=8) == 0) vindependent[row,col]<-0
}
}
#=============================================================================


OldvEigenvalues1temp<-c(' ',
                       '--------------------------------------------------------------------------------',
                       ' ',                       ' ',
                       'SELECT A SUBSET OF SNPs WHILE OPTIMISING INFORMATION:',
                       ' ',
                       'For factor 1 to M, Eigenvalues and Proportion of Variance, after Varimax Rotation:')
OldvEigenvalues2temp<-round(lvevals,dig=4)

Oldvrcoefficients1temp<-c(' ',
                         'Principal component coefficients for varimax-rotated matrix:',
                         ' - Columns represent factors (principal components) 1 to M',
                         ' - Rows represent SNP 1 to M',
                         ' ')
Oldvrcoefficients2temp<-cbind(SNPnames.NonRedundant,round(vrcoefficients, dig=4))

dimnames(Oldvrcoefficients2temp)[[2]][2:(M+1)] <- dimnames(Oldvrcoefficients2temp)[[1]]
#dimnames(Oldvrcoefficients2temp)[[2]][1]<-"SNP"


OldvEigenLoadings1temp<-c(' ',
                         'Factor "loadings" after varimax rotation:',
                         ' - Columns represent factors 1 to M',
                         ' - Rows represent SNP 1 to M',
                         ' - SNPs contributing the MOST to each rotated factor are designated by a "1"',
                         ' ')


OldvEigenLoadings2temp<-cbind(SNPnames.NonRedundant,vindependent)


dimnames(OldvEigenLoadings2temp)[[2]][2:(M+1)] <- dimnames(OldvEigenLoadings2temp)[[1]]
#dimnames(OldvEigenLoadings2temp)[[2]][1]<-"SNP"


OldvEigenLoadings3temp<-c(' => Select one SNP to represent either:',
                          '    i.   each factor,',
                          '    ii.  the factors with the largest Meff eigenvalues, or',
                          '    iii. the factors explaining a selected proportion of variance.')

OldvEigenvalues1<-matrix(OldvEigenvalues1temp)
OldvEigenvalues2<-OldvEigenvalues2temp
Oldvrcoefficients1<-matrix(Oldvrcoefficients1temp)
Oldvrcoefficients2<-Oldvrcoefficients2temp
OldvEigenLoadings1<-matrix(OldvEigenLoadings1temp)
OldvEigenLoadings2<-OldvEigenLoadings2temp
OldvEigenLoadings3<-matrix(OldvEigenLoadings3temp)

  sink("results2.out")
  print(no.dimnames(OldvEigenvalues1), quote=F)
  print(no.dimnames(OldvEigenvalues2), quote=F)
  print(no.dimnames(Oldvrcoefficients1), quote=F)
  print(Oldvrcoefficients2, quote=F)
  print(no.dimnames(OldvEigenLoadings1), quote=F)
  print(OldvEigenLoadings2, quote=F)
  print(no.dimnames(OldvEigenLoadings3), quote=F)
  sink()


Warningtemp<-c(' ',
               '### Warning ###: there were some negative eigenvalues!',
               'If the above results using negative eigenvalues are equivalent',
               'to the following - obtained by setting negative eigenvalues to zero -',
               'then the results should be fine.',
               ' ')
Warning<-matrix(Warningtemp)

if(any(evals < 0)) { 
  sink("results2.out")
  print(no.dimnames(OldvEigenvalues1), quote=F)
  print(no.dimnames(OldvEigenvalues2), quote=F)
  print(no.dimnames(Oldvrcoefficients1), quote=F)
  print(Oldvrcoefficients2, quote=F)
  print(no.dimnames(OldvEigenLoadings1), quote=F)
  print(OldvEigenLoadings2, quote=F)
  print(no.dimnames(OldvEigenLoadings3), quote=F)

  sink()
}


#=============================================================================
#=============================================================================
# Perform PROMAX Rotation to Sharpen SNP Loadings to Particular Eigenvectors

# Principal Component Coefficients for Promax Rotated Matrix
prcoefficients <- promax ( coefficients ) $loadings 

# Squared Principal Component Coefficients [eigenvectors] for Promax Rotated Matrix
prcoefficients2 <- prcoefficients^2

# Sum of Squared Principal Component Coefficients for Promax Rotated Matrix (i.e., eigenvalues)
pevals <- apply(prcoefficients, 2, function(x) sum(x^2) )
lpevals<-cbind(labelevals, pevals, pevals/cumsum(pevals)[M])

dimnames(lpevals)[[2]][1]<-"Eigenvalue"
dimnames(lpevals)[[2]][2]<-"Cumulative proportion of variance"

# Find the Maximum Value making up each Factor's Rotated Eigenvalue
pmaxvalues<-array(dim=M)
for(col in 1:M) { pmaxvalues[col]<-c(round(max(prcoefficients2[,col]),dig=8))
}

# Designate which SNP Contributes the Most to each Rotated Eigenvalue
pindependent<-matrix(data=0,nrow=M,ncol=M)
for(col in 1:M) {
for(row in 1:M) {
if(round(prcoefficients2[row,col],dig=8) == pmaxvalues[col])
pindependent[row,col]<-1
if(round(prcoefficients2[row,col],dig=8) == 0) pindependent[row,col]<-0
}
}
#=============================================================================


OldpEigenvalues1temp<-c(' ',
                       '--------------------------------------------------------------------------------',
                       ' ',                       ' ',
                       'SELECT A SUBSET OF SNPs WHILE OPTIMISING INFORMATION:',
                       ' ',
                       'For factor 1 to M, Eigenvalues and Proportion of Variance, after Promax Rotation:')
OldpEigenvalues2temp<-round(lpevals,dig=4)

Oldprcoefficients1temp<-c(' ',
                         'Principal component coefficients for promax-rotated matrix:',
                         ' - Columns represent factors (principal components) 1 to M',
                         ' - Rows represent SNP 1 to M',
                         ' ')
Oldprcoefficients2temp<-cbind(SNPnames.NonRedundant,round(prcoefficients, dig=4))


dimnames(Oldprcoefficients2temp)[[2]][2:(M+1)] <- dimnames(Oldprcoefficients2temp)[[1]]
#dimnames(Oldprcoefficients2temp)[[2]][1]<-"SNP"


OldpEigenLoadings1temp<-c(' ',
                         'Factor "loadings" after promax rotation:',
                         ' - Columns represent factors 1 to M',
                         ' - Rows represent SNP 1 to M',
                         ' - SNPs contributing the MOST to each rotated factor are designated by a "1"',
                         ' ')
OldpEigenLoadings2temp<-cbind(SNPnames.NonRedundant,pindependent)


dimnames(OldpEigenLoadings2temp)[[2]][2:(M+1)] <- dimnames(OldpEigenLoadings2temp)[[1]]
#dimnames(OldpEigenLoadings2temp)[[2]][1]<-"SNP"


OldpEigenLoadings3temp<-c(' => Select one SNP to represent either:',
                          '    i.   each factor,',
                          '    ii.  the factors with the largest Meff eigenvalues, or',
                          '    iii. the factors explaining a selected proportion of variance.')

#=============================================================================
#=============================================================================

OldpEigenvalues1<-matrix(OldpEigenvalues1temp)
OldpEigenvalues2<-OldpEigenvalues2temp
Oldprcoefficients1<-matrix(Oldprcoefficients1temp)
Oldprcoefficients2<-Oldprcoefficients2temp
OldpEigenLoadings1<-matrix(OldpEigenLoadings1temp)
OldpEigenLoadings2<-OldpEigenLoadings2temp
OldpEigenLoadings3<-matrix(OldpEigenLoadings3temp)

  sink("results3.out")
  print(no.dimnames(OldpEigenvalues1), quote=F)
  print(no.dimnames(OldpEigenvalues2), quote=F)
  print(no.dimnames(Oldprcoefficients1), quote=F)
  print(Oldprcoefficients2, quote=F)
  print(no.dimnames(OldpEigenLoadings1), quote=F)
  print(OldpEigenLoadings2, quote=F)
  print(no.dimnames(OldpEigenLoadings3), quote=F)
  sink()


Warningtemp<-c(' ',
               '### Warning ###: there were some negative eigenvalues!',
               'If the above results using negative eigenvalues are equivalent',
               'to the following - obtained by setting negative eigenvalues to zero -',
               'then the results should be fine.',
               ' ')
Warning<-matrix(Warningtemp)

if(any(evals < 0)) { 
  sink("results3.out")
  print(no.dimnames(OldpEigenvalues1), quote=F)
  print(no.dimnames(OldpEigenvalues2), quote=F)
  print(no.dimnames(Oldprcoefficients1), quote=F)
  print(Oldprcoefficients2, quote=F)
  print(no.dimnames(OldpEigenLoadings1), quote=F)
  print(OldpEigenLoadings2, quote=F)
  print(no.dimnames(OldpEigenLoadings3), quote=F)

  sink()
}

q()
n
