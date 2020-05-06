#!/bin/tcsh
set all_pns = ".tmp$$.all.pns"
set all_info = ".tmp$$.all.info"
set pn_list = "pns"
set flags = ( "a=" "c=" "drop=" "pn=" "rnd=" )
while ( "${argv}" != "" )
	if ( ${?compositeflag} ) then
		set argcomp = `echo "$1" | sed "s/^-${compositeflag}//"`
		if ( "${argcomp}" != "" ) then
			set carg = ${argcomp}
		else
			shift
			set carg = $1
		endif
		set buffer = `echo "${carg}" | grep -e '^=\+$'`
		if ( "${buffer}" != "" ) then
			shift
			set carg = $1
		endif
		switch ( ${compositeflag} )
			case "a":
				set aff_file = `echo ${carg} | sed "s/^=\+//"`
				breaksw
			case "c":
				set con_file = `echo ${carg} | sed "s/^=\+//"`
				breaksw
			case "pn":
				set pn_list = `echo ${carg} | sed "s/^=\+//"`
				breaksw
			case "rnd":
				set rnd_seed = `echo ${carg} | sed "s/^=\+//"`
				breaksw
			default:
				echo "invalid option '-${compositeflag}'"
				breaksw
		endsw
		shift
		unset compositeflag
	else if ( ${?simpleflag} ) then
		switch ( ${simpleflag} )
			default:
				echo "invalid option '-${simpleflag}'"
				breaksw
		endsw
		shift
		unset simpleflag
	else
		set argflag = `echo "${argv}" | grep -e "^-"`
		if ( "${argflag}" != "" ) then
			if ( ${?validflag} ) then
				unset validflag
			endif
			# found a flag argument
			foreach cflag ( ${flags} )
				# remove the '=' sign from the composite flags
				set eflag = `echo ${cflag} | sed "s/=//g"`
				# look for cflag at the beginning of the current argument list substring
				set fcheck = `echo "${argv}" | grep -e "^-${eflag}"`
				if ( "${fcheck}" != "" ) then
					set validflag = ${cflag}
					if ( "${eflag}" == "${cflag}" ) then
						# cflag is a simple flag
						set simpleflag = ${eflag}
					else
						# cflag is a composite flag
						set compositeflag = ${eflag}
					endif
				endif
			end
			if ( ! ${?validflag} ) then
				echo "invalid argument:"
				echo "${argflag}" | sed "s/\([^ ]\+\) .\+/\1/"
				shift
			endif
		else
			shift
		endif
	endif
end
if ( ${?aff_file} && ${?con_file} ) then
	set tmpfile = `mktemp .tmp_XXXXXXX`
	set n_aff = `wc ${aff_file} | mycols 1`
	if ( ${?rnd_seed} ) then
		cat ${aff_file} ${con_file} | shuffle ${rnd_seed} > ${all_pns}
	else
		cat ${aff_file} ${con_file} > ${all_pns}
	endif
	gawk -v n_aff=${n_aff} '{ \
		if ( NR < n_aff ) print ( $1" "$1" "0" "1 ); \
		else print ( $1" "$1" "0" "0 ); \
	}' ${all_pns} | sort -u > ${all_info}
	join -a2 ${all_info} ${pn_list} | tab | cut -f 1-4 | gawk '{ \
		OFS = "\t"; \
		if ( $2 == "" ) $2 = $1; \
		if ( $3 == "" ) $3 = 0; \
		if ( $4 == "" ) $4 = -9; \
		print \
	}' > ${tmpfile}
    echo "ID_1 ID_2 missing bin1"
    echo "0 0 0 B"
    cat ${tmpfile}
	rm ${tmpfile}
	rm ${all_info}
	rm ${all_pns}
else
	echo "\n you may have neglected to provide some input."
	echo "\n usage:\n"
	echo "   make_snptest_sample.sh "
	echo "        -a <affected_list> -c <control_list>"
	echo "        [-pn <pn_list(='pns')>]"
	echo "        [-rnd <random_seed>]"
	echo "        [-sex]"
	echo ""
endif

