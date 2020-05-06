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
opt_parser="/cluster/projects/p33/franbe/lib/sh/opt_parser.sh"
opt_list=("c=" "d=" "f=" "h" "i" "k" "m=" "n=" "o=" "p=" "r=" "smiss=" "vmiss=")
get_opt ()
{
    case $1 in
        "c" )
            avcall=`echo "$2" | sed "s/^=\+//"` ;;
        "d" )
            delta=`echo "$2" | sed "s/^=\+//"` ;;
        "f" )
            freq=`echo "$2" | sed "s/^=\+//"` ;;
        "h" )
            head="no" ;;
        "i" )
            imajor="yes" ;;
        "k" )
            keep="yes" ;;
        "m" )
            mapfile=`echo "$2" | sed "s/^=\+//"` ;;
        "n" )
            nfield=`echo "$2" | sed "s/^=\+//"` ;;
        "o" )
            out=`echo "$2" | sed "s/^=\+//"` ;;
        "p" )
            famfile=`echo "$2" | sed "s/^=\+//"` ;;
        "r" )
            rsq=`echo "$2" | sed "s/^=\+//"` ;;
        "smiss" )
            smiss=`echo "$2" | sed "s/^=\+//"` ;;
        "vmiss" )
            vmiss=`echo "$2" | sed "s/^=\+//"` ;;
    esac
}
avcall_def=0.99
avcall=${avcall_def}
delta_def=0.05
delta=${delta_def}
freq_def=0.01
freq=${freq_def}
head='yes'
famfile=''
imajor='no'
keep='no'
mapfile=''
nfield=4
out='plink'
rsq_def=0.9
rsq=${rsq_def}
smiss_def=1
smiss=${smiss_def}
vmiss_def=0.1
vmiss=${vmiss_def}
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
dfiles=( $( cat ${tmpargs} ) )
rm -f ${tmpargs}
module load plink2
mafqc="--maf ${freq}"
if [[ "${freq}" == "0" ]] ; then mafqc="" ; fi
qc="${mafqc} --geno ${vmiss} --mind ${smiss} --hwe 1.E-4"
sexup=""
if [[ "${famfile}" != "" ]] ; then
    sexup="--update-sex ${famfile} 3"
fi
mapper=''
if [[ "${mapfile}" != "" ]] ; then
    mapper="--extract ${mapfile} --update-name ${mapfile}"
fi
if [[ "${dfiles[@]}" == "" ]] ; then
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) [OPTIONS] <pseudo dosage file(s)>\n"
    echo -e "   where\n"
    echo -e "     <pseudo dosage file(s)> are the imputation files containing pseudo counts (0..2)."
    echo -e "\n OPTIONS:"
    echo -e "     -c <avcall>           average call threshold for inclusion [default: ${avcall_def}]"
    echo -e "     -d <delta>            max difference between hard-call (0,1,2) genotype and pseudo count [default: ${delta_def}]"
    echo -e "     -f <freq>             minor allele frequency threshold for inclusion [default: ${freq_def}]"
    echo -e "     -h                    pseudo dosage files contain a header (only relevant for variant-major format)"
    echo -e "     -i                    pseudo dosage files are in individual major format"
    echo -e "     -k                    keep intermediate ped files"
    echo -e "     -m <map file>         optional map file to rename variants"
    echo -e "     -n <n-field>          starting pseudo count field [default: 4 (variant-major), (4-1=3) (individual-major)]"
    echo -e "     -o <output prefix>    plink output (--out) prefix [default: plink]"
    echo -e "     -p <fam file>         fam file (used to update sex information)"
    echo -e "     -r <rsq>              imputation r-squared threshold for inclusion [default: ${rsq_def}]"
    echo -e "     -smiss <missing>      max fraction of sample missingness [default: ${smiss_def} (no exclusions)]"
    echo -e "     -vmiss <missing>      max fraction of variant missingness [default: ${vmiss_def}]"
    echo
else
    echo -n > ${out}.txt
    for dfile in "${dfiles[@]}" ; do
        tmp=${out}_$( basename $dfile .dose.gz )
        echo -e "\n makebed.sh options in use:" > ${tmp}_makebed.log
        echo -e "     input file            '${dfile}'" >> ${tmp}_makebed.log
        echo -e "     avcall                ${avcall}" >> ${tmp}_makebed.log
        echo -e "     delta                 ${delta}" >> ${tmp}_makebed.log
        echo -e "     freq                  ${freq}" >> ${tmp}_makebed.log
        echo -e "     header                ${head}" >> ${tmp}_makebed.log
        echo -e "     individual-major      ${imajor}" >> ${tmp}_makebed.log
        echo -e "     keep files            ${keep}" >> ${tmp}_makebed.log
        echo -e "     map file              ${mapfile}" >> ${tmp}_makebed.log
        echo -e "     start field           $(( nfield ))($(( nfield - 1 )))" >> ${tmp}_makebed.log
        echo -e "     output prefix         ${out}" >> ${tmp}_makebed.log
        echo -e "     fam file              ${famfile}" >> ${tmp}_makebed.log
        echo -e "     rsq                   ${rsq}" >> ${tmp}_makebed.log
        echo -e "     smiss                 ${smiss}" >> ${tmp}_makebed.log
        echo -e "     vmiss                 ${vmiss}" >> ${tmp}_makebed.log
        echo > ${tmp}_makebed.log >> ${tmp}_makebed.log
        if [[ ! -f "${tmp}.bed" ]] ; then
            mycat=zcat
            gzip -t ${dfile} 2> /dev/null
            if [[ "$?" == 1 ]] ; then
                echo "warning: unrecognized gzip archive format; assuming plain text.."
                mycat=cat
            fi
            if [[ "${imajor}" == "no" ]] ; then
                ${mycat} ${dfile} | awk -F $'\t' $AWK_LOCAL_INCLUDE \
                -v delta=${delta} \
                -v head=${head} \
                -v n=${nfield} \
                -v out=${tmp} \
                --source '{
                    OFS = "\t";
                    if ( NR == 1 ) {
                        if ( head == "yes" ) {
                            for ( i = n; i <= NF; i++ ) {
                                split( $i, idvec, " " );
                                printf( "%s\t%s\t0\t0\t-9\t-9\n", idvec[1], idvec[2] ) > out".tfam";
                            }
                        }
                        else {
                            for ( i = n; i <= NF; i += 2 ) {
                                pname = out( roundstd( ( $1 - n + 1 ) / 2 ) )
                                printf( "%s\t%s\t0\t0\t-9\t-9\n", pname, pname ) > out".tfam";
                            }
                        }
                    }
                    if ( head != "yes" || NR > 1 ) {
                        chr = $1;
                        gsub( "[:].+$", "", chr );
                        printf( "%s\t%s\t%d\t%d", chr, $1, 0, NR - 1 );
                        for ( i = n; i <= NF; i++ ) {
                            a1 = roundstd( $i - 1 );
                            if ( a1 < 0 ) a1 = 0;
                            a2 = roundstd( $i - a1 );
                            mygenotype = a1 + a2;
                            if ( abs( $i - mygenotype ) < delta ) {
                                if ( mygenotype == 0 ) printf( "\t%s %s", $3, $3 );
                                else if ( mygenotype == 1 ) printf( "\t%s %s", $2, $3 );
                                else if ( mygenotype == 2 ) printf( "\t%s %s", $2, $2 );
                            }
                            else printf( "\t%s %s", 0, 0 );
                        }
                    }
                    printf( "\n" );
                }' > ${tmp}.tped
                if [[ -s "${tmp}.tfam" && -s "${tmp}.tped" ]] ; then
                    plink --tfile ${tmp} ${mapper} ${qc} ${sexup} --make-bed --out ${tmp}
                    if [[ "${keep}" == "no" ]] ; then
                        rm ${tmp}.tfam ${tmp}.tped
                    fi
                fi
            else
                ifile=${dfile%.dose.gz}.info.gz
                if [[ -s "${dfile}" && -s "${ifile}" ]] ; then
                    awk -F $'\t' $AWK_LOCAL_INCLUDE \
                    -v avcall=${avcall} \
                    -v delta=${delta} \
                    -v freq=${freq} \
                    -v rsq=${rsq} \
                    -v n=${nfield} \
                    -v out=${tmp} \
                    --source '{
                        OFS = "\t";
                        if ( NR == FNR ) {
                            chr[NR] = $1
                            gsub( "[:].+$", "", chr[NR] );
                            pos[NR] = $1
                            gsub( "^.+[:]", "", pos[NR] );
                            var[NR] = $1
                            a1lab[NR] = $2
                            a2lab[NR] = $3
                            varmaf[NR] = $5
                            varcall[NR] = $6
                            varrsq[NR] = $7
                            print( chr[NR], var[NR], 0, pos[NR] ) > out".map"
                        }
                        else {
                            split( $1, idvec, "->" );
                            printf( "%s\t%s\t0\t0\t-9\t-9", idvec[1], idvec[2] )
                            for ( i = n-1; i <= NF; i++ ) {
                                a1 = roundstd( $i - 1 );
                                if ( a1 < 0 ) a1 = 0;
                                a2 = roundstd( $i - a1 );
                                mygenotype = a1 + a2;
                                printvar = abs( $i - mygenotype ) < delta
                                printvar = printvar && varmaf[i-(n-1)+1] > freq
                                printvar = printvar && varcall[i-(n-1)+1] > avcall
                                printvar = printvar && varrsq[i-(n-1)+1] > rsq
                                if ( printvar ) {
                                    if ( mygenotype == 0 ) printf( "\t%s %s", a2lab[i-(n-1)+1], a2lab[i-(n-1)+1] );
                                    else if ( mygenotype == 1 ) printf( "\t%s %s", a1lab[i-(n-1)+1], a2lab[i-(n-1)+1] );
                                    else if ( mygenotype == 2 ) printf( "\t%s %s", a1lab[i-(n-1)+1], a1lab[i-(n-1)+1] );
                                }
                                else printf( "\t%s %s", 0, 0 );
                            }
                            printf( "\n" );
                        }
                    }' <(  ${mycat} ${ifile} | tail -n +2 ) <( ${mycat} ${dfile} ) > ${tmp}.ped
                    if [[ -s "${tmp}.map" && -s "${tmp}.ped" ]] ; then
                        plink --file ${tmp} ${mapper} ${qc} ${sexup} --make-bed --out ${tmp}
                        if [[ "${keep}" == "no" ]] ; then
                            rm ${tmp}.map ${tmp}.ped
                        fi
                    fi
                fi
            fi
        else
            echo "bed file exists: skipping ${dfile}.."
        fi
        if [[ -s "${tmp}.bed" && -s "${tmp}.bim" && -s "${tmp}.fam" ]] ; then
            echo "${tmp}" >> ${out}.txt
        fi
    done
    if [[ -s "${out}.txt" ]] ; then
        if (( ${#dfiles[@]} > 1 )) ; then
            plink --merge-list ${out}.txt --out ${out}
            if [[ -s "${out}-merge.missnp" ]] ; then
                tmpexcl=$( mktemp .tmpXXXXXX )
                sort -u ${out}-merge.missnp > ${tmpexcl}
                if [[ -s "${out}.missnp" ]] ; then
                    sort -u ${out}-merge.missnp ${out}.missnp > ${tmpexcl}
                fi
                for bfile in $( cat ${out}.txt ) ; do
                    plink --bfile ${bfile} --exclude ${tmpexcl} --make-bed --out ${bfile}
                done
                plink --merge-list ${out}.txt --out ${out}
                rm ${tmpexcl}
            fi
        fi
    fi
fi
