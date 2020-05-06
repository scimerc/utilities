pp.plot <- function ( pvalstat, filename = "qq_gwa.bmp" ) {
	bmp ( filename )
	par ( bty = "l" )
	plot (
		-log10 ( ppoints ( length ( pvalstat ), 0 ) ),
		-log10 ( sort ( pvalstat ) ),
		col = "red",
		pch = 19,
		xlab = "Expected -Log ( p-value )",
		ylab = "Observed -Log ( p-value )"
	)
	abline ( 0, 1 )
	dev.off ()
}

qq.plot <- function ( chisqstat, filename = "qq_gwa.bmp" ) {
	bmp ( filename )
	par ( bty = "l" )
	plot (
		qchisq ( ppoints ( length ( chisqstat ), 0 ), 1 ),
		sort ( chisqstat ),
		col = "red",
		pch = 19,
		xlab = "Expected chi-square value",
		ylab = "Observed chi-square statistic"
	)
	points (
		qchisq ( ppoints ( length ( chisqstat ), 0 ), 1 ),
		sort ( chisqstat / ( median ( chisqstat ) / .675 ** 2 ) ),
		col = "blue",
		bg = "blue",
		pch = 23
	)
	abline ( 0, 1 )
	dev.off ()
}

qq.plot.from.p <- function ( pvalstat, filename = "qq_gwa.bmp" ) {
	chisqstat <- qchisq ( pvalstat, 1, lower.tail = F )
	bmp ( filename )
	par ( bty = "l" )
	plot (
		qchisq ( ppoints ( length ( chisqstat ), 0 ), 1 ),
		sort ( chisqstat ),
		col = "red",
		pch = 19,
		xlim = c ( 0, 25 ),
		ylim = c ( 0, 75 ),
		xlab = "Expected chi-square value",
		ylab = "Observed chi-square statistic"
	)
	points (
		qchisq ( ppoints ( length ( chisqstat ), 0 ), 1 ),
		sort ( chisqstat / ( median ( chisqstat ) / .675 ** 2 ) ),
		col = "blue",
		bg = "blue",
		pch = 23
	)
	abline ( 0, 1 )
	dev.off ()
}

