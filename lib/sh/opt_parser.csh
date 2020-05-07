#!/bin/tcsh
# parses the argument list according to the options in the variable $opt_list
# [e.g.:
# 	alias get_opt 'eval " \\
# 		switch ( \!:1 ) \\
# 			case "a": \\
# 				set file = \`
# 				breaksw \\
# 			case "verbose": \\
# 				set verbose = 1 \\
# 				breaksw \\
# 			default: \\
# 				echo "invalid option -\!:1\" \\
# 				breaksw \\
# 		endsw \\
# 	"'
# ]
set arg_list = ""
set arg_logfile = "/dev/null"
# set arg_logfile = "opt_parser.log"
echo -n > ${arg_logfile}
if ( ${?opt_list} ) then
	set get_opt_check = `alias | tab | cut -f 1 | grep '^get_opt$'`
	if ( "${get_opt_check}" != "" ) then
        set count = 0
		while ( "${argv}" != "" )
            echo "${count} ==> parsing argument list: '${argv}'.." >> ${arg_logfile}
			if ( ${?composite_opt} ) then
                echo "    parsing composite option '${composite_opt}'.." >> ${arg_logfile}
				set argcomp = `echo "$1" | sed "s/^-${composite_opt}//"`
				# if argcomp isn't empty, what's left can be either garbage or the option's value
				# possibly including a leading '=' sign to be dealt with later (see below)
				if ( "${argcomp}" != "" ) then
					set carg = ${argcomp}
				else
					shift
					set carg = $1
				endif
				# match the '=' sign; if that's all there is the value must be the next word
                # otherwise the extra '=' sign should be removed in the get_opt subroutine
				set buffer = `echo "${carg}" | grep -e '^=\+$'`
				if ( "${buffer}" != "" ) then
					shift
					set carg = $1
				endif
				get_opt ${composite_opt} ${carg}
				unset composite_opt
				unset simple_opt
				shift
			else if ( ${?simple_opt} ) then
                echo "    parsing simple option '${simple_opt}'.." >> ${arg_logfile}
				set dummyarg = "dummy"
				get_opt ${simple_opt} ${dummyarg}
				unset composite_opt
				unset simple_opt
				shift
			else
				set argopt = `echo "${argv}" | grep -e "^-"`
				if ( "${argopt}" != "" ) then
					if ( ${?validopt} ) then
						unset validopt
					endif
					# found a flag argument (option)
					foreach copt ( ${opt_list} )
						# remove the '=' sign from the composite flags
						set eopt = `echo ${copt} | sed "s/=//g"`
						# look for copt at the beginning of the current argument list substring
						set fcheck = `echo "${argv}" | grep -e "^-${eopt}"`
						if ( "${fcheck}" != "" ) then
							set validopt = ${copt}
							if ( "${eopt}" == "${copt}" ) then
								# copt is a simple flag
								set simple_opt = ${eopt}
							else
								# copt is a composite flag
								set composite_opt = ${eopt}
							endif
						endif
					end
					if ( ! ${?validopt} ) then
						echo -n "invalid option: " > /dev/stderr
						echo "${argopt}" | sed "s/\([^ ]\+\) .\+/\1/" > /dev/stderr
						shift
					endif
				else
					set arg_list = "${arg_list}$1 "
					shift
				endif
			endif
            @ count = ${count} + 1
		end
	else
		echo " opt_parser.sh: module 'get_opt' not defined: can't parse command line options."
		echo "              please define the 'get_opt' alias parse instructions command."
		exit
	endif
else
	echo " optparse: no option list found."
	echo "           please provide it by defining the variable opt_list;"
	echo "           list simple options are listed as such, composite options with a trailing '=';"
	echo "           all options should be double quoted and stripped of the leading '-' sign."
	echo "           [e.g.: set opt_list = ( \"h\" \"verbose\" \"a=\" \"booby_trap=\" .... )]"
	exit
endif
echo -n "${arg_list}"
