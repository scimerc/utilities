#!/bin/tcsh
set carrier_file = ".carrier.pns"
set noncarrier_file = ".non-carrier.pns"
set selection_criterion = "affected_carrier"
set min_allele = 0
set opt_parser = "/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.csh"
set opt_list = ( "g=" "a1" "a0" "keep" )
alias get_opt 'eval " \\
	switch ( \!:1 ) \\
		case "g": \\
			set gen_file = `echo "\!:2" | sed "s/^=\+//"` \\
			breaksw \\
		case "a0": \\
			set min_allele = 0 \\
			breaksw \\
		case "a1": \\
			set min_allele = 1 \\
			breaksw \\
		case "keep": \\
			set keep_files = 1 \\
			breaksw \\
		default: \\
			echo "invalid option -\!:1" \\
			breaksw \\
	endsw \\
"'
set gen_file = "gen.four"
set tmpfile = `mktemp .tmp-XXXXXXXX`
set temporary_files = "${tmpfile}"
source ${opt_parser} > ${tmpfile}
set argcheck = `grep "[^ ]" ${tmpfile}`
if ( "${argcheck}" != "" ) then
        set arg_list = `cat ${tmpfile}`
	if ( -rf ${gen_file} ) then
		set carrier_file = ${gen_file}.carrier.pns
		set noncarrier_file = ${gen_file}.non-carrier.pns
		if ( ${min_allele} == 0 ) then
			gawk '$3 >= 0 && $4 >= 0 && ($3 < 0.1 || $4 < 0.1)' ${gen_file} | tab | cut -f 1 | sort -u > ${carrier_file}
			gawk '$3 >= 0 && $4 >= 0 && !($3 < 0.1 || $4 < 0.1)' ${gen_file} | tab | cut -f 1 | sort -u > ${noncarrier_file}
		else
			gawk '$3 >= 0 && $4 >= 0 && ($3 > 0.9 || $4 > 0.9)' ${gen_file} | tab | cut -f 1 | sort -u > ${carrier_file}
			gawk '$3 >= 0 && $4 >= 0 && !($3 > 0.9 || $4 > 0.9)' ${gen_file} | tab | cut -f 1 | sort -u > ${noncarrier_file}
		endif
		set label_file = .label.${gen_file}
		gawk '{print $1 "\tcarrier"}' ${carrier_file} > ${label_file}
		gawk '{print $1 "\tnon-carrier"}' ${noncarrier_file} >> ${label_file}
		set temporary_files = "${temporary_files} ${carrier_file} ${noncarrier_file}"
		foreach aff_file ( $arg_list )
			set pathless_aff_file = `echo ${aff_file} | sed "s/.\+\///g"`
			set template_file = ${pathless_aff_file}.${carrier_file}
			sort ${aff_file} > ${tmpfile}
			mv ${tmpfile} ${pathless_aff_file}
			cat ${carrier_file} ${pathless_aff_file} | sort -u > ${tmpfile}
			jspec -a ${tmpfile} | sort -k 2 > ${template_file}.pre
			join ${carrier_file} ${pathless_aff_file} > ${template_file}
			switch ( ${selection_criterion} )
				case "affected_carrier":
					join -2 2 ${template_file} ${template_file}.pre | tab | cut -f 2 | sort -u > ${template_file}.sel.fam
					breaksw
				default:
					tab ${template_file}.pre | cut -f 2 | sort -u > ${template_file}.sel.fam
					echo "warning: unrecognized selection criterion '${selection_criterion}'."
					echo "taking all family clusters."
					breaksw
			endsw
			join -2 2 ${pathless_aff_file} ${template_file}.pre | gawk '{$6 = 2; print $0}' | cols 2,1,3-6 | tab > ${template_file}.affected.pre
			join -v2 -2 2 ${pathless_aff_file} ${template_file}.pre | gawk '{$6 = 0; print $0}' | tab > ${template_file}.non-affected.pre
			cat ${template_file}.affected.pre ${template_file}.non-affected.pre | sort > ${template_file}.pre
			echo -n "writing pre-pedigree file '${template_file}.select.pre'...."
			join ${template_file}.sel.fam ${template_file}.pre | sort > ${template_file}.select.pre
			echo " done."
			set temporary_files = "${temporary_files} ${template_file}.affected.pre ${template_file}.non-affected.pre"
			set temporary_files = "${temporary_files} ${template_file}.pre ${template_file}.sel.fam"
			set temporary_files = "${temporary_files} ${template_file}"
		end
		set _exec_program = 1
	else
		echo "no genotype file found."
	endif
endif
if ( ! ${?_exec_program} ) then
	set progname = `echo "$0" | sed "s/.\+\///g"`
	echo "\n you may have neglected to provide some input."
	echo "\n  usage:"
	echo "    ${progname} [options] <affected_list1> [<affected_list2> <affected_list3> ...]"
	echo "\n  options:"
	echo "    -g <genotype_file>               four column probability genotype file;"
	echo "    -a0|a1                           allele to be considered [mnemonic rule: number~probability]."
	echo ""
endif
if ( ! ${?keep_files} ) then
	rm -f ${temporary_files}
endif

