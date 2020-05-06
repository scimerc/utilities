dosecorr <- function ( mydata ) {
	N <- length( mydata$V1 )
	corr.mat <- matrix( NA, N, N )
	for( i in 1 : (N-1) ) {
	# for( i in 2 ) {
		vector_i <- as.numeric( mydata[ i, 4 : length( mydata[ i, ] ) ] )
		for( j in (i+1) : N ) {
	# 	for( j in 3 ) {
			vector_j <- as.numeric( mydata[ j, 4 : length( mydata[ j, ] ) ] )
			corr.mat[ i, j ] <- cor( vector_i, vector_j )
		}
	}
	return( corr.mat )
}
