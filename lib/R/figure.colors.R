my.color.function <- function( k, n, base.colors =  c( "#DD1E2F", "#EBB035", "#06A2CB", "#006500" ) ) {
	if ( is.null( base.colors ) ) {
		cat( "no colors specified: taking default...\n" )
		base.colors <- c( "#DD1E2F", "#EBB035", "#06A2CB", "#006500" )
	}
	if ( length( base.colors ) <= 1 ) {
		cat( "insufficient colors: adding default colors...\n" )
		base.colors <- c( base.colors, "#DD1E2F", "#EBB035", "#06A2CB", "#006500" )
	}
	home.colors <- rgb( t( col2rgb( colors() ) ) / 255 )
	index = length( home.colors )
	take.doubles <- FALSE
	while ( length( base.colors ) < n ) {
		new.color <- home.colors[ index ]
		if ( ! new.color %in% base.colors || take.doubles ) base.colors <- c( base.colors, new.color )
		index <- index - 1
		if ( index == 1 ) {
			take.doubles = TRUE
			index = length( home.colors )
		}
	}
	return( base.colors[ k ] )
}
