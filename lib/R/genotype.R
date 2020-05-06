source ( "/tsd/p33/data/durable/inventory/lib/R/nucleocode.R" )
genotype <- function ( alleleA, alleleB ) {
	if ( length ( alleleA ) == length ( alleleB ) ) {
		codeA <- nucleocode ( alleleA )
		codeB <- nucleocode ( alleleB )
		ifelse ( codeA < 0 | codeB < 0, -1,
		 ifelse (
		  paste ( codeA, codeB, sep = "" ) == "11", 1,
		  ifelse (
		  paste ( codeA, codeB, sep = "" ) %in% c ( "12", "21" ), 2,
		   ifelse (
		   paste ( codeA, codeB, sep = "" ) %in% c ( "13", "31" ), 3,
		    ifelse (
		    paste ( codeA, codeB, sep = "" ) %in% c ( "14", "41" ), 4,
		     ifelse (
		     paste ( codeA, codeB, sep = "" ) == "22", 5,
		      ifelse (
		      paste ( codeA, codeB, sep = "" ) %in% c ( "23", "32" ), 6,
		       ifelse (
		       paste ( codeA, codeB, sep = "" ) %in% c ( "24", "42" ), 7,
		        ifelse (
		        paste ( codeA, codeB, sep = "" ) == "33", 8,
		         ifelse (
		         paste ( codeA, codeB, sep = "" ) %in% c ( "34", "43" ), 9,
		          ifelse (
		          paste ( codeA, codeB, sep = "" ) == "44", 10, -1
		         )
		        )
		       )
		      )
		     )
		    )
		   )
		  )
		 )
		)
	)
	} else {
		cat ( "error: vector length mismatch." )
	}
}

