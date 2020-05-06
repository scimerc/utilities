#!/bin/tcsh
set pn_file = ""
set plate_file = ""
set geno_file = ""
set opt_parser = "/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.csh"
set opt_list = ( "pns=" "plates=" "geno=" )
alias get_opt 'eval " \\
	switch ( \!:1 ) \\
		case "geno": \\
			set geno_file = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "plates": \\
			set plate_file = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "pns": \\
			set pn_file = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		default: \\
			echo "invalid option -\!:1" \\
			breaksw \\
	endsw \\
"'
set tmpargfile = `mktemp .tmp-XXXXXXXX`
source ${opt_parser} > ${tmpargfile}
set snp_files_list = `cat ${tmpargfile}`
if ( ${snp_files_list} == "" ) then
	echo "no snps?"
endif
rm ${tmpargfile}
if ( "${geno_file}" != "" && ${pn_file} != "" ) then
	set tmpfile = `mktemp .tmp-XXXXXXXX`
	set tmpfile_pn = `mktemp .tmp-pn-XXXXXXXX`
	set N = `wc -l ${pn_file} | tab | cut -f 1`
	sort -k 4 ${geno_file} | tab > ${tmpfile}
	join.py -2 4 ${pn_file} ${tmpfile} | tab > ${tmpfile_pn}
	foreach snp_file ( $snp_files_list )
		if ( "${plate_file}" != "" ) then
			echo -n "plate\tN\t\t"
			foreach mysnp ( `cat ${snp_file}` )
				echo -n "${mysnp}\t"
			end
			echo -n "\nall\t--\t\t"
			foreach mysnp ( `cat ${snp_file}` )
				set n = `grep "${mysnp}" ${geno_file} | join.py -2 4 ${pn_file} - | sort -u -k 1,1 | wc | mycols 1`
				if ( "${n}" == "" ) then
					set n = 0
				endif
				echo "${n} / ${N}" | bc -l | perl -pe 's/\n/\t/g'
			end
			echo
			foreach plate ( `cat ${plate_file}` )
				echo -n "${plate}\t"
				pn_on_plate ${plate} | sort > ${tmpfile}
				set pn_total = `join.py ${tmpfile} ${pn_file} | wc -l | tab | cut -f 1`
				echo -n "${pn_total}\t\t"
				if ( -f ${snp_file} ) then
					foreach mysnp ( `cat ${snp_file}` )
						set pn_count = `gawk -v plateID=${plate} '$2 == plateID' ${tmpfile_pn} | grep ${mysnp} | mycols 1 | sort -u | wc | mycols 1`
						echo "${pn_count} / ( ${pn_total} + 0.01 )" | bc -l | perl -pe 's/\n/\t/g'
					end
				endif
				echo ""
			end
		else
			echo "no plates specified."
		endif
	end
	rm ${tmpfile}
	rm ${tmpfile_pn}
else
	echo "\n you may have neglected to provide some input."
	echo "\n  usage:"
	echo "    check_genoyield.sh -geno <genotype file> -plates <plate list> -pns <PN list> <SNP sgfile(s)>"
	echo "\n  where:"
	echo "    -geno <genotype file>  (six column) genotype file to use;"
	echo "    -plates <plate list>   plates to be searched;"
	echo "    -pns <PN list>         list of PNs."
	echo ""
endif

