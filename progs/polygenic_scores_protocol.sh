#/bin/bash
droot="/home/checco/work/data/TOP/Dosages/TOP_Chrom"
mfile="/home/checco/work/data/GWAS_Stats/9m/PGC2_BIP_noTOP_metaz_pruned_01.txt"
tmpfile=$(mktemp .tmpXXXX)
for snplist in $* ; do
# 	echo "writing risk scores for list '${snplist}'.."
	loctmpmfile=$(mktemp .tmpXXXX)
	sort ${snplist} | join - ${mfile} > ${loctmpmfile}
	if [ -s ${loctmpmfile} ] ; then
		for chr in $( seq 22 ) ; do
	# 		echo "entering chromosome ${chr}.."
			loctmpfile=$(mktemp .tmpXXXX)
			cat -n ${droot}${chr}[^0-9]*.info | \
				sort -k 2,2 | join -2 2 ${loctmpmfile} - | \
				gawk -f '/home/checco/lib/awk/nucleocode.awk' --source '{ \
					if( $11 < 0.05 ) { p = $8; risk = $10; } \
					else { p = $7; risk = $9; } \
					if( \
						nucleocode( $4 ) == nucleocode( $14 ) && nucleocode( $5 ) == nucleocode( $15 ) || \
						comp_nucleocode( $4 ) == nucleocode( $14 ) && comp_nucleocode( $5 ) == nucleocode( $15 ) \
					) print( $13, p, log( risk ) ); \
					else if( \
						nucleocode( $4 ) == nucleocode( $15 ) && nucleocode( $5 ) == nucleocode( $14 ) || \
						comp_nucleocode( $4 ) == nucleocode( $15 ) && comp_nucleocode( $5 ) == nucleocode( $14 ) \
					) print( $13, p, -log( risk ) ); \
				}' | sort -k 1,1n > ${loctmpfile}
			if [ -s ${loctmpfile} ] ; then
				gawk '( NR == FNR ) { \
					logodds[ $1 ] = $3; \
					pval[ $1 ] = $2; \
					next; \
				} ( FNR in logodds ) { \
					printf( "%s\t%s\t%s\t%f\t", $1, $2, $3, pval[ FNR ] ); \
					for( i = 4; i <= NF; i++ ) { \
						printf( "%f\t", $i * logodds[ FNR ] ); \
					} \
					printf( "\n" ); \
				}' ${loctmpfile} ${droot}${chr}[^0-9]*.dose >> ${tmpfile}
			fi
			rm -rf ${loctmpfile}
		done
		rm -rf ${loctmpmfile}
	fi
# 	echo "computing polygenic risk scores.."
	gawk '{ \
		if ( NR == 1 ) { \
			N = NF; count = 0; \
			for ( i = 5; i <= N; i++ ) \
				sum[ i ] = 0; \
		} \
		count++; \
		for ( i = 5; i <= N; i++ ) \
			sum[ i ] += $i; \
	} END{ \
		for ( i = 5; i <= N; i++ ) \
			print( sum[ i ] / count ); \
	}' ${tmpfile}
done
rm -rf ${tmpfile}

