#!/bin/tcsh
@ i = 0
@ n = 1
set bgen_data = ""
set hdf5_data = ""
set bgenprog = gwsp
set hdf5prog = hdf5_assoc
set gentree = 'genealogy'
set method = ""
set prefix = ""
set region = ""
set opt_parser = "/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.csh"
set opt_list = ( "a=" "c=" "bgen=" "hdf5=" "help" "i=" "n=" "o=" "r=" )
alias get_opt 'eval " \\
	switch ( \!:1 ) \\
		case "a": \\
			set aff_file = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "c": \\
			set con_file = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "bgen": \\
			set bgen_data = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "hdf5": \\
			set hdf5_data = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "help": \\
			set helpme = 1 \\
			breaksw \\
		case "i": \\
			@ i = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "n": \\
			@ n = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "o": \\
			set prefix = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "r": \\
			set region = -i `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		default: \\
			echo "invalid option -\!:1" \\
			breaksw \\
	endsw \\
"'
set tmpfile = `mktemp .tmp-XXXXXXXX`
source ${opt_parser} > ${tmpfile}
set resarg = `cat ${tmpfile}`
if ( "${bgen_data}" != "" ) then
	if ( -f ${bgen_data} ) then
		set method = "gwsp"
	endif
endif
if ( "${hdf5_data}" != "" ) then
	set method = "hdf5"
	if ( -f ${hdf5_data} ) then
		set hdf5_dir = ""
		set hdf5_list = ${hdf5_data}
	else if ( -d ${hdf5_data} ) then
		set hdf5_dir = ${hdf5_data}
		set hdf5_list = `ls ${hdf5_data}`
		if ( ${region} != "" ) then
			set chr = `echo "${region}" | cut -d ":" -f 1`
			@ start_pos = `echo "${region}" | cut -d ":" -f 2 | cut -d "-" -f 1`
			@ stop_pos = `echo "${region}" | cut -d ":" -f 2 | cut -d "-" -f 2`
			if ( ${start_pos} > ${stop_pos} ) then
				@ tmp_pos = ${start_pos}
				@ start_pos = ${stop_pos}
				@ stop_pos = ${tmp_pos}
			endif
			echo "start position: ${start_pos}"
			echo "stop position: ${stop_pos}"
			set hdf5_list = `ls ${hdf5_data} | \
				grep "^chr${chr}" | \
				gawk -F "[.:-_]" -v start_pos=${start_pos} -v stop_pos=${stop_pos} \
					'! ( stop_pos < $2 || start_pos > $3 ) { print $0 }'`
		endif
	else
		set method = ""
	endif
	echo "hdf5 files set to: ${hdf5_list}"
endif
if ( ${?aff_file} && ${?con_file} && ! ${?helpme} ) then
	if ( -f ${aff_file} && -f ${con_file} ) then
		if ( "${method}" == "gwsp" || "${method}" == "hdf5" ) then
			@ imax = $i + $n - 1
			set n_aff = `wc -l ${aff_file} | mycols 1`
			set n_con = `wc -l ${con_file} | mycols 1`
			set larger_size = `echo "if ( ${n_aff} > ${n_con} ) ${n_aff} else ${n_con}" | bc -l`
			if ( ${n_aff} == ${larger_size} ) then
				cat -n ${aff_file} ${con_file} | sort -u -k 2,2 | sort -k 1,1n | mycols 2 > ${tmpfile}
			else
				cat -n ${con_file} ${aff_file} | sort -u -k 2,2 | sort -k 1,1n | mycols 2 > ${tmpfile}
			endif
			join.py ${tmpfile} ${gentree} | mycols 1,7 > ${tmpfile}.sex
			if ( $i != 0 ) then
				echo "performing ${n} permutations."
				set outfile = "${prefix}.perm_${i}_${imax}.out"
			else
				set outfile = "${prefix}.out"
			endif
			echo -n > ${tmpfile}.out
			while ( $i <= $imax )
				if ( $i == 0 ) then
					cp ${tmpfile} ${tmpfile}.${i}
				else
					shuffle ${i} < ${tmpfile} > ${tmpfile}.${i}
					echo "permutation ${i}"
				endif
				echo "splitting pns.."
				split --lines=${larger_size} ${tmpfile}.${i} ${tmpfile}.${i}_
				# ${tmpfile}.${i}_aa contains now the larger set
				# ${tmpfile}.${i}_ab contains now the smaller set
				if ( ${n_aff} == ${larger_size} ) then
					set aff_perm_file = ${tmpfile}.${i}_aa
					set con_perm_file = ${tmpfile}.${i}_ab
				else
					set aff_perm_file = ${tmpfile}.${i}_ab
					set con_perm_file = ${tmpfile}.${i}_aa
				endif
				echo -n > ${tmpfile}.${i}.out
				switch ( ${method} )
					case "gwsp":
						set cmd = "${bgenprog} ${aff_perm_file} ${con_perm_file} ${tmpfile}.sex ${bingen}"
						${cmd} | mycols 10,8 | tab > ${tmpfile}.${i}.out
						breaksw
					case "hdf5":
						echo "CaseControl /dev/stdout ${aff_perm_file} ${con_perm_file}" > ${tmpfile}.cmd
						foreach hdf5_file ( ${hdf5_list} )
							set cmd = "${hdf5prog} ${region} ${tmpfile}.cmd ${hdf5_dir}/${hdf5_file}"
							${cmd} | gawk '{ print ( $1 ":" $2 "\t" $6 ) }' | tab >> ${tmpfile}.${i}.out
						end
						breaksw
					default:
						echo "\nunknown method: ${method}"
						breaksw
				endsw
				echo "extracting chi2.."
				mycols 1 ${tmpfile}.${i}.out > ${tmpfile}.snps
				mycols 2 ${tmpfile}.${i}.out > ${tmpfile}.${i}.chi2
				echo "pasting files.."
				paste ${tmpfile}.${i}.chi2 ${tmpfile}.out > ${tmpfile}.${i}.out
				mv ${tmpfile}.${i}.out ${tmpfile}.out
				set new_snp_count = `wc ${tmpfile}.snps | mycols 1`
				if ( ${?current_snp_count} ) then
					if ( ${new_snp_count} != ${current_snp_count} ) then
						echo "error: snp count mismatch."
						echo "exiting script."
						exit
					endif
				endif
				set current_snp_count = ${new_snp_count}
				rm ${tmpfile}.${i}*
				@ i = $i + 1
			end
			echo "Marker	CHI2_PERM" > ${outfile}
			paste ${tmpfile}.snps ${tmpfile}.out | tr -s "\t" >> ${outfile}
			perl -pi -w -e 's/\t/,/g;' ${outfile}
			perl -pi -w -e 's/^([^,]+),(.+)$/$1\t,$2/g;' ${outfile}
			perl -pi -w -e 's/,CHI2_PERM/CHI2_PERM/g;' ${outfile}
		else
			echo "information missing."
		endif
	else
		echo "files not found."
	endif
else
	if ( ! ${?helpme} ) then
		echo "\n you may have neglected to provide some input."
	endif
	echo "\n  usage:"
	echo "    perm_assoc.sh [options] -a <affected_list> -c <control_list>"
	echo "\n  options:"
	echo "    -bgen|hdf5[ |=]<data file>   sets method and genotype data"
	echo "    -help                        displays this help message"
	echo "    -i[ |=]<start seed>          first seed of the permutation [default = 0, no permutation]"
	echo "    -n[ |=]<n. of perms>         number of permutations to be performed [default = 100]"
	echo "    -r[ |=]<region>              chromosomal region [e.g. '-r 11:11111100-11211100]'"
	echo "\n  [Note: in case of multiple method arguments 'hdf5' overrides 'bgen']"
	echo
endif
rm ${tmpfile}*
