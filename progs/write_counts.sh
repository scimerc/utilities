#!/bin/bash
# this is really thought for use within the imputation scripts.
# it finds the number of snps in each chromosome interval.
cyto_intervals="intervals"
opt_parser="/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("i=")
get_opt()
{
  case $1 in
    "i" )
      cyto_intervals=$(echo "$2" | sed "s/^=\+//") ;;
  esac
}
tmpargfile=$(mktemp .tmp-XXXXXXXX)
source ${opt_parser} > ${tmpargfile}
mydata_list=$(cat ${tmpargfile})
rm ${tmpargfile}
if [ "${mydata_list}" != "" ] ; then
	for mydata in ${mydata_list} ; do
		echo -n > ${mydata}.counts
		for interval in $(cat ${cyto_intervals}) ; do
			arm=$(echo "${interval}" | cut -d "_" -f 1)
			if [ -r ${mydata}.chr${arm}.map ] ; then
				echo -e -n "${interval}\t" >> ${mydata}.counts
				gawk \
					-v s0=$(echo "${interval}" | cut -d "_" -f 2) \
					-v s1=$(echo "${interval}" | cut -d "_" -f 3) \
					'$4 > s0 && $4 < s1' ${mydata}.chr${arm}.map \
				| wc -l >> ${mydata}.counts
			fi
		done
	done
else
	echo "no data."
	echo -e "correct usage:\n $(basename $0) [-i <intervals file>] <data identifier(s)>"
	echo "  where <data identifier(s)> are plink map file names stripped of '.chrXXx.map' extensions."
	echo "  and <intervals file> is a file with intervals in the format <carm>_<start>_<end>."
fi

