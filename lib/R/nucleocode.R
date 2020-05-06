nucleocode <- function ( nucleotide ) {
	ifelse (
		grepl ( "^[aA1]$", nucleotide ), 1, ifelse (
			grepl ( "^[cC2]$", nucleotide ), 2, ifelse (
				grepl ( "^[gG3]$", nucleotide ), 3, ifelse (
					grepl ( "^[tT4]$", nucleotide ), 4, -1
				)
			)
		)
	)
}

comp.nucleocode <- function ( nucleotide ) {
	ifelse (
		grepl ( "^[aA1]$", nucleotide ), 4, ifelse (
			grepl ( "^[cC2]$", nucleotide ), 3, ifelse (
				grepl ( "^[gG3]$", nucleotide ), 2, ifelse (
					grepl ( "^[tT4]$", nucleotide ), 1, -1
				)
			)
		)
	)
}
