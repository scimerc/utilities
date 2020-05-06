reduce.model <- function( p, r, v, x, link='linear', mode='union', signif=0.1 ) {
  # p        parameters to be pruned
  # r        response variable
  # v        fixed explanatory variables as per hypothesis
  # x        data.frame containing all (named) variables of interest
  # link     type of linear model link. for now only 'linear' or 'logit' are
  #          allowed
  # mode     possible options are 'union' (default) and 'intersection'
  #          'union': any optional parameters associating with any variable in
  #          the model will be included
  #          'intersection': any optional parameters associating with both the
  #          response variable and any of the explanatory variables will be
  #          included
  # signif   significance level for association
  # the function returns a minimal model formula (as a text string)
  tmpformula = paste0( r, '~1' )
  myrespformula = paste0( r, '~1' )
  for ( n in 1 : length(p) ) myrespformula = sprintf('%s+%s', myrespformula, p[n])
  cat( 'fitting response model..\n' )
  lmresp = switch( link,
    linear=lm( as.formula( myrespformula ), data=x ),
    logit=glm( as.formula( myrespformula ), data=x, family=binomial(link='logit') )
  )
  lmresp.coeff = summary( lmresp )$coeff
  varsel = grepl( paste0( p, collapse='|' ), row.names( lmresp.coeff ) )
  respp = row.names( lmresp.coeff )[ varsel & lmresp.coeff[, 4] < signif ]
  expp = c()
  for ( k in 1 : length(v) ) {
      tmpformula = sprintf( '%s+%s', tmpformula, v[k] )
      myexpformula = paste0( v[k], '~1' )
      for ( n in 1 : length(p) ) myexpformula = sprintf('%s+%s', myexpformula, p[n])
      cat( 'fitting variable', v[k], 'model..\n' )
      tmpx = x
      tmpx[, v[k] ] = as.numeric( tmpx[, v[k] ] )
      lmexp = lm( as.formula( myexpformula ), data=tmpx )
      lmexp.coeff = summary( lmexp )$coeff
      varsel = grepl( paste0( p, collapse='|' ), row.names( lmexp.coeff ) )
      tmpp = row.names( lmexp.coeff )[ varsel & lmexp.coeff[, 4] < signif ]
      expp = sort( unique( c( expp, tmpp ) ) )
  }
  respp = switch( mode,
    union=sort( union( expp, respp ) ),
    intersection=sort( intersect( expp, respp ) )
  )
  for ( n in 1:length(respp) )
    tmpformula = sprintf( '%s+%s', tmpformula, respp[n] )
  return( tmpformula )
}

