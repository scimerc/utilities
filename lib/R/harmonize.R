# 'rgdyscale' - raggedly scale variables across different subgroups
#  v       variables matrix or data.frame
#  w       covariates matrix or data.frame
#  method  method used for harmonization: one of 'std' or 'dem'
#  use     subset of data to be used with 'std' or 'dem' (ignored with 'res')

rgdyscale <- function( v, w, method=c( 'std', 'dem' ), use=NULL ) {
  method = match.arg( method )
  invisible( cbind( v, w ) )
  v.df = as.data.frame( v )
  w.df = as.data.frame( w )
  if ( dim( v.df )[1] != dim( w.df )[1] ) {
    error( paste(
      "variables and covariates dimensions do not match.\n"
    ) )
  }
  if ( is.null( use ) ) {
    use = T
  } else {
    if ( length( use ) != dim( v.df )[1] ) {
      warning( paste(
        "array dimensions do not match: ignoring parameter `use`.\n"
      ) )
      use = T
    }
  }
  if ( !all( unlist( lapply( w.df, is.factor ) ) ) ) {
    #TODO: implement factorization along the lines of EAtests
    error( paste(
      "not all covariates are factors: reverting to residualization ('res') mode.\n"
    ) )
  }
  vp.df = v.df
  vp.df[!use,] = NA
  my.centers = apply( apply( vp.df, 2, tapply, w.df, mean, na.rm=T ), 2, unsplit, w.df )
  my.scales = 1
  if ( method == 'std' ) {
    my.scales = apply( apply( vp.df, 2, tapply, w.df, sd, na.rm=T ), 2, unsplit, w.df )
    my.scales[ is.na( my.scales ) ] = 1
  }
  return( (v.df-my.centers) / my.scales )
}


# 'harmonize' - harmonize variables across different subgroups or covariate ranges
#  v       variables matrix or data.frame
#  w       covariates matrix or data.frame
#  method  method used for harmonization: one of 'std', 'res' or 'dem'
#  use     subset of data to be used with 'std' or 'dem' (ignored with 'res')

harmonize <- function( v, w, method=c( 'std', 'res', 'dem' ), use=NULL ) {
  method = match.arg( method )
  invisible( cbind( v, w ) )
  v.df = as.data.frame( v )
  w.df = as.data.frame( w )
  if ( dim( v.df )[1] != dim( w.df )[1] ) {
    error( paste(
      "variables and covariates dimensions do not match.\n"
    ) )
  }
  if ( method %in% c( 'std', 'dem' ) ) {
    if ( all( unlist( lapply( w.df, is.factor ) ) ) ) {
      #TODO: implement factorization along the lines of EAtests
      writeLines( strwrap( prefix='harmonize > ', paste(
        'using standardization method', ifelse( method == 'std', 'with scaling.', '.' )
      ) ) )
      hv.df = rgdyscale( v.df, w.df, method=method, use=use )
      return( hv.df )
    } else {
      warning( paste(
        "not all covariates are factors: reverting to residualization ('res') mode.\n"
      ) )
      method = 'res'
    }
  }
  if ( method == 'res' ) {
    writeLines( strwrap( prefix='harmonize > ', paste(
      'using residualization method.'
    ) ) )
    hv.lm = lm( as.matrix(v.df) ~ ., data=w.df )
    print( summary( hv.lm ) )
    hv.df = residuals( hv.lm )
    vhv.cor = diag( cor( v.df, hv.df ) )
    writeLines( strwrap( prefix='harmonize > ', paste(
      'correlations between raw and residualized variables:'
    ) ) )
    print( vhv.cor )
    hv.df = hv.df %*% diag( sign( vhv.cor ) )
    return( hv.df )
  }
}

