allele_Ato1 <- function ( allele ) {
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

allele_1toA <- function ( allele ) {
	ifelse (
		nucleotide == 1, "A", ifelse (
			nucleotide == 2, "C", ifelse (
				nucleotide == 3, "G", ifelse (
					nucleotide == 4, "T", -1
				)
			)
		)
	)
}
