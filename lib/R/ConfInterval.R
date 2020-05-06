computeChiSqConfidenceInterval <- function ( OddsRatio, ChiSquare ) {
	Zscore <- sqrt ( ChiSquare )
	StdLogErr <- abs ( log ( OddsRatio ) ) / Zscore
	lowerLimit <- OddsRatio * exp ( -1.96 * StdLogErr )
	upperLimit <- OddsRatio * exp ( 1.96 * StdLogErr )
	return ( matrix ( data = c (lowerLimit, upperLimit ), nrow = length ( OddsRatio ), ncol = 2 ) )
}

computePConfidenceInterval <- function ( OddsRatio, CorrPvalue ) {
	StdLogErr <- abs ( log ( OddsRatio ) ) / sqrt ( qchisq ( CorrPvalue, 1, lower.tail = F ) )
	lowerLimit <- OddsRatio * exp ( -1.96 * StdLogErr )
	upperLimit <- OddsRatio * exp ( 1.96 * StdLogErr )
	return ( matrix ( data = c (lowerLimit, upperLimit ), nrow = length ( OddsRatio ), ncol = 2 ) )
}

formatConfidenceInterval <- function ( OddsRatio, lowerBound, higherBound, precision = 2 ) {
	or.ci <- paste ( 
		format ( OddsRatio, digits = precision, nsmall = precision ), 
		" (", 
			format ( lowerBound, digits = precision, nsmall = precision ), ", ", 
			format ( higherBound, digits = precision, nsmall = precision ), 
		")", sep="" 
	) 
	return ( or.ci ) 
}
