#!/bin/bash
AWK_LOCAL_INCLUDE=$( printf -- '-f %s\n' $( echo ${AWK_INCLUDE} \
    /cluster/projects/p33/groups/biostat/software/lib/awk/abs.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/nucleocode.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/genotype.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/gflip.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/gflipper.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/gmatch.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/gmatcher.awk \
    /cluster/projects/p33/groups/biostat/software/lib/awk/round.awk \
) | sort -u )
chromosomes=$( seq 23 )
bdir="/cluster/projects/p33/groups/biostat/software"
hdir="imputation"
mrkfile="snps"
tagdir="tags"
pnfile=""
opt_parser="${bdir}/lib/sh/opt_parser.sh"
opt_list=("h=" "m=" "p=" "t=")
get_opt ()
{
	case $1 in
		"h" )
			hdir=`echo "$2" | sed "s/^=\+//"` ;;
		"m" )
			mrkfile=`echo "$2" | sed "s/^=\+//"` ;;
		"p" )
			pnfile=`echo "$2" | sed "s/^=\+//"` ;;
		"t" )
			tagdir=`echo "$2" | sed "s/^=\+//"` ;;
	esac
}
source ${opt_parser} > /dev/null
if [ "${pnfile}" != "" ]; then
	echo -en "ID\tChr\tPos\t"
	mycols 2 ${pnfile} | perl -p -i -e 's/\n/\t/g;'
	echo ""
	for chr in ${chromosomes} ; do
		hdf5_filter -f plain -m ${mrkfile} -p ${pnfile} ${hdir}/chr${chr}.hdf5 /dev/stdout | \
		gawk -f ${AWK_LOCAL_INCLUDE} --source '{ \
			printf("%s\t",$1); \
			for ( i = 2; i < NF; i += 2 ) { \
				gt = roundstd($(i)+$(i+1)); \
				if ( gt < 0 ) gt = -1; \
				printf("%d\t",gt); \
			} \
			print ""; \
		}' | \
		join.py ${tagdir}/chr${chr}.tags.info - | \
		mycols 1,2,3,5-
	done
else
	echo -e "\n  usage:"
	echo -e "    `basename $0` [options] -p <pheno file>"
	echo -e "\n    <pheno file> has two columns <PN> <case/control> (0=case, 1=control)"
	echo -e "\n  options:"
	echo -e "    -h[ |=]<hdf5 data directory>   hdf5 data directory"
	echo -e "    -m[ |=]<marker file>           set of target markers"
	echo -e "    -t[ |=]<tag directory>         tag marker directory"
	echo
fi

