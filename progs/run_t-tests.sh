#!/bin/tcsh
set gen_file = $1
set tmp_affected_file = ".gen-tmp.affected.multi"
set tmp_control_file = ".gen-tmp.control.multi"
set program = "run_t-test.Rscript"
shift
foreach arg ( $* )
	if ( -fr $arg ) then
		echo "T-test results for ${arg}"
        set oddsratio_file = "or_${arg}.dat"
		join ${gen_file} ${arg} > ${tmp_affected_file}
		join -v1 ${gen_file} ${arg} > ${tmp_control_file}
		$program -a ${tmp_affected_file} -c ${tmp_control_file} -o ${oddsratio_file}
		rm ${tmp_affected_file} ${tmp_control_file}
	else
		echo "file ${arg} not found."
	endif
end

