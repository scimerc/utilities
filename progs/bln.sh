#!/bin/bash
libdir="/cluster/projects/p33/groups/biostat/software/lib"
opt_parser="${libdir}/sh/opt_parser.sh"
opt_list=("n=")
get_opt ()
{
    case $1 in
        "n" )
            myname=`echo "$2" | sed "s/^=\+//"` ;;
    esac
}
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
myfiles=$( cat ${tmpargs} )
rm -f ${tmpargs}

for myfile in ${myfiles} ; do
    ln -s $( readlink -f ${myfile}.bed ) ${myname}.bed
    ln -s $( readlink -f ${myfile}.bim ) ${myname}.bim
    ln -s $( readlink -f ${myfile}.fam ) ${myname}.fam
done

