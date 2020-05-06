#!/bin/bash
# this assumes the known relations are stored in a file that can be given as option:
# the 'relations' file is expected to have two columns with the names of the two related PNs.
# it also assumes you have '.sample' files with informative missing field (given as arguments).
BASE_DIR="/cluster/projects/p33/groups/biostat/software"
opt_parser="${BASE_DIR}/lib/sh/opt_parser.sh"
opt_list=( "h" "r=" )
helpme=""
relations_file=""
tmpfileA=$(mktemp .tmp_XXXXXXXX)
tmpfileB=$(mktemp .tmp_XXXXXXXX)
get_opt ()
{
  case $1 in
    "h" )
        helpme=1 ;;
    "r" )
        relations_file=$(echo "$2" | sed "s/^=\+//") ;;
  esac
}
tmpargfile=$(mktemp .tmp-XXXXXXXX)
source ${opt_parser} > ${tmpargfile}
sample_files=$(cat ${tmpargfile})
if [[ "${helpme}" == "" && "${relations_file}" != "" ]] ; then
    tail -n +2 ${relations_file} | \
        perl -p -e 's/[[:space:]]+/\n/g;' | \
        sort -u > ${tmpfileA}
    for sample_file in ${sample_files} ; do
        tab ${sample_file} | \
            join.py ${tmpfileA} - | \
            mycols 1 > ${tmpfileB}
        mv ${tmpfileB} ${tmpfileA}
    done
    join.py ${tmpfileA} ${relations_file} | \
    join.py -2 3 ${tmpfileA} - | mycols 3,4 > ${tmpargfile}
    if [[ "${sample_files}" != "" ]] ; then
        while [[ -s ${tmpargfile} ]] ; do
            mycols 1 ${tmpargfile} > ${tmpargfile}.ids
            mycols 2 ${tmpargfile} >> ${tmpargfile}.ids
            table < ${tmpargfile}.ids | sort -k 2,2nr -k 1,1 > ${tmpargfile}.table
            for n in $(mycols 2 ${tmpargfile}.table | sort -unr) ; do
                gawk -v n=${n} '$2 == n' ${tmpargfile}.table > ${tmpfileA}
                count=1
                for sample_file in ${sample_files} ; do
                    tab ${sample_file} | \
                        join.py ${tmpfileA} - | \
                        mycols 1-$(( count + 1 )),$(( count + 4 )) > ${tmpfileB}
                    mv ${tmpfileB} ${tmpfileA}
                    let count++
                done
                PN_to_be_discarded=$(\
                    gawk 'BEGIN { \
                        max_missing = -1; \
                        max_missing_PN = ""; \
                    } \
                    { \
                        sum = 0; \
                        for ( i = 3; i <= NF; i++ ) sum += $i; \
                        missing = sum / ( NF - 2 ); \
                        if ( missing > max_missing ) { \
                            max_missing = missing; \
                            max_missing_PN = $1; \
                        }; \
                    } \
                    END { print max_missing_PN }' \
                    ${tmpfileA} \
                )
                echo ${PN_to_be_discarded}
                grep -vw "${PN_to_be_discarded}" ${tmpargfile} > ${tmpargfile}.new
                mv ${tmpargfile}.new ${tmpargfile}
            done
        done
    fi
else
	echo -e "\n  usage:"
	echo -e "    `basename $0` [-r <relations file='relations'>] <sample files>"
	echo
fi
rm -f ${tmpfileA} ${tmpfileB}
rm -f ${tmpargfile}*

