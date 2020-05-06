rsquared <- function ( x, x0 ) {
	ss.tot <- sum ( ( x0 - mean ( x0 ) ) ^ 2 )
	ss.err <- sum ( ( x - x0 ) ^ 2 )
	return ( 1 - ss.err / ss.tot )
}
