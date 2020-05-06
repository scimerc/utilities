#!/bin/bash
opt_parser="/cluster/projects/p33/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("lrp=" "b=" "d=" "s=" "g=" "m=" "cbatch=" "exclude=" "aff=" "con=" "v=")
get_opt ()
{
    case $1 in
        "aff" )
            affected=`echo "$2" | sed "s/^=\+//"` ;;
        "con" )
            controls=`echo "$2" | sed "s/^=\+//"` ;;
        "cbatch" )
            cbatch=`echo "$2" | sed "s/^=\+//"` ;;
        "exclude" )
            excludefile=`echo "$2" | sed "s/^=\+//"` ;;
        "lrp" )
            lrptag=`echo "$2" | sed "s/^=\+//"` ;;
        "b" )
            birthtag=`echo "$2" | sed "s/^=\+//"` ;;
        "d" )
            diagtag=`echo "$2" | sed "s/^=\+//"` ;;
        "s" )
            sextag=`echo "$2" | sed "s/^=\+//"` ;;
        "g" )
            genodir=`echo "$2" | sed "s/^=\+//"` ;;
        "m" )
            mapfile=`echo "$2" | sed "s/^=\+//"` ;;
        "v" )
            varfile=`echo "$2" | sed "s/^=\+//"` ;;
    esac
}
mapfile_def='/tsd/p33/data/durable/vault/genetics/All_ChipType_NO_samples_wAlias_Yield_IID_CLmapped.txt'
mapfile=${mapfile_def}
genodir_def='/tsd/p33/data/durable/vault/genetics/rawdata/genotypes/preQC/NORMENT'
genodir=${genodir_def}
affected_def=Affected
affected=${affected_def}
controls_def=Control
controls=${controls_def}
lrptag_def='LRPID'
lrptag=${lrptag_def}
birthtag_def='YEAR_BIRTH'
birthtag=${brithtag_def}
diagtag_def='DIAGNOSIS_MAIN'
diagtag=${diagtag_def}
sextag_def='GENDER'
sextag=${sextag_def}
excludefile=''
varfile=''
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
myfiles=$( cat ${tmpargs} )
rm -f ${tmpargs}
batches=$( ls ${genodir}/*.fam )
if [[ "${cbatch}" != "" ]] ; then
    batches=( ${cbatch//,/ } )
fi
vartag=""
if [[ "${varfile}" != "" ]] ; then
    vartag="--extract ${varfile}"
fi


if [[ "${myfiles}" != "" ]] ; then

    for myfile in ${myfiles} ; do

            pnfile=$( basename ${myfile} .csv ).pns
            famfile=$( basename ${myfile} .csv ).fam
            clinfile=$( basename $myfile )
            while [[ "${myfile}" == "${clinfile}" ]] ; do
                clinfile=$( basename ${clinfile} .csv )Z.csv
            done

            LRPID=$( head -n 1 ${myfile} | transpose.perl | grep -w -n -m1 "${lrptag}" | cut -d ":" -f 1 )
            birth=$( head -n 1 ${myfile} | transpose.perl | grep -w -n -m1 "${birthtag}" | cut -d ":" -f 1 )
            diag=$( head -n 1 ${myfile} | transpose.perl | grep -w -n -m1 "${diagtag}" | cut -d ":" -f 1 )
            sex=$( head -n 1 ${myfile} | transpose.perl | grep -w -n -m1 "${sextag}" | cut -d ":" -f 1 )

            if [[ "${birth}" == "" ]] ; then
                        echo "no birth year field specified: using default.."
                        birth=0
            fi
            if [[ "${diag}" == "" ]] ; then
                        echo "no diagnosis field specified: using default.."
                        diag=0
            fi
            if [[ "${sex}" == "" ]] ; then
                        echo "no sex field specified: using default.."
                        sex=0
            fi

            # make local csv file with essential information
            awk -F $'\t' -v affstr="${affected}" -v constr="${controls}" \
                -v LRPID=${LRPID} -v birth=${birth} -v diag=${diag} -v sex=${sex} 'BEGIN{
                        OFS = "\t"
                        if ( birth == 0 ) birth = NF + 1
                        if ( diag == 0 ) diag = NF + 2
                        if ( sex == 0 ) sex = NF + 3
                        fstr = sprintf( "%d\t%d\t%d\t%d", LRPID, birth, diag, sex )
                        split( fstr, myvalues )
                        for ( k in myvalues ) myfields[ myvalues[k] ] = 1
                        split( affstr, affvalues, "," )
                        for ( k in affvalues ) affarr[ affvalues[k] ] = 1
                        split( constr, convalues, "," )
                        for ( k in convalues ) conarr[ convalues[k] ] = 1
                } {
                        if ( $(diag) == "" ) $(diag) = "NA"
                        if ( $(birth) == "" || $(birth) < 1900 ) $(birth) = "NA"
                        if ( $(sex) == "" ) $(sex) = "NA"
                        if ( $(diag) in affarr || $(diag) in conarr ) {
                            printf( "%s\t%s\t%s\t%s", $(LRPID), $(diag), $(sex), $(birth) )
                            for ( k = 1; k <= NR; k++ ) if ( ! k in myfields ) printf( "\t%s", $k )
                            printf( "\n" );
                        }
                }' ${myfile} | sort -k 1,1 \
                > ${clinfile}

            # make pns file from map file joining LRP-IDs
            sort -t $'\t' -k 3,3 ${mapfile} \
                        | join -t $'\t' -2 3 ${clinfile} - | cut -f 5 \
                        | sort -u > ${pnfile}

            # make fam file from map file joining LRP-IDs
            sort -t $'\t' -k 3,3 ${mapfile} \
                        | join -t $'\t' -2 3 ${clinfile} - | \
                                    awk -v affstr="${affected}" -v constr="${controls}" '{
                                        diag = -9;
                                        split( affstr, affvalues, "," )
                                        for ( k in affvalues ) affarr[ affvalues[k] ] = 1
                                        split( constr, convalues, "," )
                                        for ( k in convalues ) conarr[ convalues[k] ] = 1
                                        if ( $2 in conarr ) diag = 1;
                                        if ( $2 in affarr ) diag = 2;
                                        sex = 0;
                                        if ( $3 == "male" ) sex = 1;
                                        if ( $3 == "female" ) sex = 2;
                                        print( $5, $1, 0, 0, sex, diag );
                                    }' | sort -k 1,1 > ${famfile}

            # make phenotype update file from the fam file
            sort -t " " -k 1,1 ${batches} | join ${famfile} - \
                        | awk '{ OFS = "\t";
                                    if ( $5 != $10 && $5 != 0 && $10 != 0  ) print( $1, $2, $7, $5, $10 );
                        }' > sex_mismatches.txt
            sort -t " " -k 1,1 ${batches} | join ${famfile} - \
                        | awk '{ OFS = "\t";
                                    if ( $5 == $10 || $5 == 0 || $10 == 0 ) print( $1, $7, $6 );
                        }' > update_pheno.txt

            # initialize remfile
            if [[ -f ${excludefile} ]] ; then
                        remfile=remove_these_and_their_relatives.txt
                        echo -n > ${remfile}
            fi

            # extract genotypes
            tmpdir=tmpdir
            while [[ -d ${tmpdir} ]] ; do
                tmpdir=${tmpdir}Z
            done
            mkdir -p ${tmpdir}
            for gfile in ${batches} ; do
                        plinktag=$( basename $gfile .fam )
                        plinkpnfile=${tmpdir}/${plinktag}.pns
                        sort -t " " -k 1,1 $gfile | tabspace | join -t $'\t' $pnfile - > $plinkpnfile
                        if [[ -f ${excludefile} ]] ; then
                                    sort -u $excludefile | join $plinkpnfile - >> $remfile
                        fi
                        plink --bfile ${genodir}/${plinktag} --allow-no-sex \
                                    --keep $plinkpnfile --make-bed --out ${tmpdir}/${plinktag}
                        hfile=${tmpdir}/${plinktag}.hh
                        newplinktag=${plinktag}
                        if [[ -f $hfile && -f ${tmpdir}/${plinktag}.bed ]] ; then
                                    newplinktag=${plinktag}_nohh
                                    cut -f 1 $hfile | sort -u > ${hfile}.pns
                                    cut -f 3 $hfile | sort -u > ${hfile}.mrk
                                    plink --bfile ${tmpdir}/${plinktag} --allow-no-sex \
                                                --exclude ${hfile}.mrk --make-bed --out ${tmpdir}/${newplinktag}
                        fi
                        if [[ -f ${tmpdir}/${newplinktag}.bed ]] ; then
                                    plink --bfile ${tmpdir}/${newplinktag} --allow-no-sex ${vartag} \
                                                --make-pheno update_pheno.txt 2 --make-bed --out ${plinktag}
                        fi
            done

    done

else
    echo -e "\n extract raw genotypes for the given clinical file.
     \nUSAGE:
         $( basename $0 ) OPTIONS -aff <tag> [-con <tag>] <clinical file>\n
         where <clinical file> is the required file with tab-separated clinical information.\n
         -aff <affected tag(s)>  comma-separated list of affected tags (e.g.: SZ,BD);
         -con <affected tag(s)>  comma-separated list of control tags (e.g.: control,blood_donor);
     \nOPTIONS:
         -cbatch <b1,b2,b3...>   comma-separated list of fam files [default=all];
         -exclude <pn file>      optional individual exclusion file;
         -lrp <LRPID tag>        LRPID field header tag [default=${lrptag_def}];
         -b <birth year tag>     year of birth field header tag [default=${birthtag_def}];
         -d <diagnosis tag>      diagnosis field header tag [default=${diagtag_def}];
         -s <sex tag>            sex field header tag [default=${sextag_def}];
         -g <dirname>            genotype directory [default='${genodir_def}'];
         -m <filename>           ID map file [default='${mapfile_def}'];
         -v <filename>           variants of interest [by default all variants are extracted];
    "
fi

