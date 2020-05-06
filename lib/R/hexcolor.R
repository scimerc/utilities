hexcolor <- function( colorname=NULL, alphalevel='ff' ) {
  if ( is.null(colorname) ) return( NULL )
  return(
    paste( c( '#',
      as.character( as.hexmode( col2rgb( as.character(colorname) ) ) ),
      as.character(alphalevel)
    ), collapse='' )
  )
}

