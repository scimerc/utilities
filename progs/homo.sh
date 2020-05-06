#!/bin/tcsh
set genfile = "gen.bin.four"
foreach pnid ( `cat $*` )
	set total = `grep "${pnid}" ${genfile} | wc | tab | cut -f 1`
	set homo = `grep "${pnid}" ${genfile} | tab | gawk '$3 == $4' | wc | tab | cut -f 1`
	set ratio = `echo "${homo} / ${total}" | bc -l`
	echo "${pnid}\t${ratio}"
end
