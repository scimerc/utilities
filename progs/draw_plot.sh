#!/usr/bin/tcsh
set SPARROW_DIR = /scratch/scratch/webprojects/sparrow/program
set missing = XXX
foreach arg ( $* )
	set argvar = `echo "${arg}" | grep "^\-"`
	if ( "${argvar}" == '' ) then
		set myfile = ${arg}
		set mycrmfile = ${arg}.crm
		sed "s/^#.*/${missing}\t${missing}\t${missing}/m" < ${myfile} > ${mycrmfile} # remove comment lines
	else
		set lineopt = `echo "${arg}" | grep "^\-width="`
		if ( "${lineopt}" != '' ) then
			set linewidth = `echo "$arg" | sed "s/-width=//"`
		endif
	endif
	if ( ${?myfile} && ${?linewidth} ) then
		set nlines = `grep "" -c ${mycrmfile}`
		@ rangeline = ( ${linewidth} - 1 )
		set plotsize = `echo "${linewidth} * 0.025" | bc -l`
		set lowerline = 1
		while ( ${lowerline} < ${nlines} )
			@ upperline = ${lowerline} + ${rangeline}
		#================= preparing the gnuplot input file =================
			set TEMP_FILE = ${mycrmfile}_${lowerline}-${upperline}.gnuplot
			set PNG_FILE = ${mycrmfile}_${lowerline}-${upperline}.png
			echo "set term png small xffffff x111111 xaaaaaa xff0000 x0000ff x00ff00" > ${TEMP_FILE}
			echo "set output '${PNG_FILE}'" >> ${TEMP_FILE}
			echo "set size ${plotsize},0.235" >> ${TEMP_FILE}
			echo "set datafile missing '${missing}'" >> ${TEMP_FILE}
			echo "set nokey" >> ${TEMP_FILE}
			echo "unset border" >> ${TEMP_FILE}
			echo "set rmargin 1" >> ${TEMP_FILE}
			echo "set lmargin 1" >> ${TEMP_FILE}
			echo "set tmargin 0" >> ${TEMP_FILE}
			echo "set bmargin 0" >> ${TEMP_FILE}
			echo "set xzeroaxis" >> ${TEMP_FILE}
			# echo "set yzeroaxis" >> ${TEMP_FILE}
			echo "set xrange [${lowerline}:${upperline}]" >> ${TEMP_FILE}
			echo "set yrange [-1.4:1.4]" >> ${TEMP_FILE}
			echo "set xtics 1" >> ${TEMP_FILE}
			echo "set ytics 0.5" >> ${TEMP_FILE}
			echo "unset xtics" >> ${TEMP_FILE}
			echo "unset x2tics" >> ${TEMP_FILE}
			echo "unset ytics" >> ${TEMP_FILE}
			echo "unset y2tics" >> ${TEMP_FILE}
		# 	echo "set xtics font 'Courier,36'" >> ${TEMP_FILE}
		# 	echo "set x2tics font 'Courier,36'" >> ${TEMP_FILE}
		# 	echo "set ytics font 'Times,48'" >> ${TEMP_FILE}
		# 	echo "set y2tics font 'Times,32'" >> ${TEMP_FILE}
			echo "set format x ''" >> ${TEMP_FILE}
# 			echo "set format y '%.1f'" >> ${TEMP_FILE}
			echo "set format y ''" >> ${TEMP_FILE}
		# 	echo "set xlabel 'secondary structure (DSSP)' -0.4,0 font 'Times,48'" >> ${TEMP_FILE}
		# 	echo "set x2label 'amino acid sequence' -0.4,0 font 'Times,48'" >> ${TEMP_FILE}
			echo "plot '${mycrmfile}' u 1 title 'helical' with lines lw 3, '${mycrmfile}' u 2 title 'extended' with lines lw 3, '${mycrmfile}' u 3 title 'coil' with lines lw 3" >> ${TEMP_FILE}
		#====================================================================
			@ lowerline = ${lowerline} + ${linewidth}
			/usr/bin/gnuplot ${TEMP_FILE}
			chmod a+r ${PNG_FILE}
		end
	endif
end
