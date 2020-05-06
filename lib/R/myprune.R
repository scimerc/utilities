myprune <- function ( mrk.names, corr.mat, myrsq, mode = "max", verbose = FALSE ) {
	corr.list <- c()
	repr.list <- c()
	sort.criterion <- "P"
# 	sort.criterion <- "OR"
	N <- length( mrk.names )
	if ( verbose ) {
        cat( N, 'variants read.\n' );
        cat( 'correlation matrix dimensions:', dim( corr.mat ), '\n' )
    }
	rsq.mat <- matrix( NA, N, N )
	rsq.mat[ upper.tri( rsq.mat ) ] <- corr.mat[ upper.tri( rsq.mat ) ]^2
	rsq.mat[ lower.tri( rsq.mat ) ] <- t( corr.mat )[ lower.tri( rsq.mat ) ]^2
	diag( rsq.mat ) <- 1
	total.rsq <- apply( rsq.mat, 1, sum, na.rm=T )
	# check if mode specifies an existing filename
	if ( file.exists( mode ) ) {
		if ( verbose ) cat( "entering stat mode..\n" )
		read.table( mode, header=T ) -> metadata
		log.mrk.names <- mrk.names %in% metadata$SNP
		mrk.names <- mrk.names[ log.mrk.names ]
		metadata <- metadata[ metadata$SNP %in% mrk.names, ]
		rsq.mat <- rsq.mat[ log.mrk.names, log.mrk.names ]
		total.rsq <- total.rsq[ log.mrk.names ]
		N <- length( mrk.names )
		mode <- "stat"
	} else {
		if ( verbose ) cat( "file", mode, "not found, reverting to max mode..\n" )
		mode = "max"
	}
	tmprepr <- NULL
	if ( N > 1 ) {
		for ( i in 1 : N ) {
			if ( ! as.character( mrk.names[ i ] ) %in% corr.list ) {
				tmplog <- !is.na( rsq.mat[, i ] ) & rsq.mat[, i ] >= myrsq
				corr.mrk.names <- mrk.names[ tmplog ]
				if ( verbose ) cat( "SNP", as.character( mrk.names[ i ] ), "correlates with", as.character( corr.mrk.names ), "\n" )
				if ( mode == "max" ) tmprepr <- corr.mrk.names[ total.rsq[ tmplog ] == max( total.rsq[ tmplog ], na.rm=T ) ][ max( round( sum( total.rsq[ tmplog ] == max( total.rsq[ tmplog ], na.rm=T ), na.rm=T ) / 2 ), 1 ) ]
				if ( mode == "center" ) tmprepr <- corr.mrk.names[ max( round( sum( ( 1 : sum( tmplog ) ) * rsq.mat[ tmplog, i ] ) / sum( rsq.mat[ tmplog, i ] ) ), 1 ) ]
				if ( mode == "stat" ) tmprepr <- corr.mrk.names[ metadata[ tmplog, sort.criterion ] == min( metadata[ tmplog, sort.criterion ] ) ][ max( round( sum( metadata[ tmplog, sort.criterion ] == min( metadata[ tmplog, sort.criterion ] ) ) / 2 ), 1 ) ]
	# 			if ( mode == "stat" ) tmprepr <- corr.mrk.names[ abs( log( metadata[ tmplog, sort.criterion ] ) ) == max( abs( log( metadata[ tmplog, sort.criterion ] ) ) ) ][ max( round( sum( abs( log( metadata[ tmplog, sort.criterion ] ) ) == max( abs( log( metadata[ tmplog, sort.criterion ] ) ) ) ) / 2 ), 1 ) ]
				if ( verbose ) cat( "SNP block tagger:", tmprepr, "[", as.character( tmprepr ), "]\n" )
				if ( ! as.character( tmprepr ) %in% corr.list ) {
					repr.list <- unique( c( repr.list, as.character( tmprepr ) ) )
					if ( verbose ) cat( "added tag SNP", which( mrk.names == as.character( tmprepr ) ), "[", as.character( tmprepr ), "].\n" )
					corr.list <- unique( c( corr.list, as.character( mrk.names[ tmplog ] ) ) )
				}
			}
		}
	} else if ( N == 1 ) {
		repr.list <- c( as.character( mrk.names ) )
	}
	return( repr.list )
}

