#!/bin/bash

BASEDIR="$( cd "$( dirname $0 )" && cd .. && pwd )"

AWK_LOCAL_INCLUDE=$( printf -- '-f %s\n' $( echo ${AWK_INCLUDE} \
    ${BASEDIR}/lib/awk/abs.awk \
    ${BASEDIR}/lib/awk/nucleocode.awk \
    ${BASEDIR}/lib/awk/genotype.awk \
    ${BASEDIR}/lib/awk/gflip.awk \
    ${BASEDIR}/lib/awk/gflipper.awk \
    ${BASEDIR}/lib/awk/gmatch.awk \
    ${BASEDIR}/lib/awk/gmatcher.awk \
    ${BASEDIR}/lib/awk/round.awk \
) | sort -u )

opt_parser="${BASEDIR}/lib/sh/opt_parser.sh"
opt_list=("a" "c=" "d=" "f=" "e=" "h" "i" "k" "m=" "n=" "o=" "p=" "r=" "smiss=" "vmiss=")
get_opt ()
{
    case $1 in
        "a" )
            head="no" ;;
        "c" )
            avcall=`echo "$2" | sed "s/^=\+//"` ;;
        "d" )
            delta=`echo "$2" | sed "s/^=\+//"` ;;
        "e" )
            hwe=`echo "$2" | sed "s/^=\+//"` ;;
        "f" )
            freq=`echo "$2" | sed "s/^=\+//"` ;;
        "h" )
            haplo="yes" ; imajor="yes" ;;
        "i" )
            imajor="yes" ;;
        "k" )
            keep="yes" ;;
        "m" )
            mapfile=`echo "$2" | sed "s/^=\+//"` ;;
        "n" )
            nfield=`echo "$2" | sed "s/^=\+//"` ;;
        "o" )
            outprefix=`echo "$2" | sed "s/^=\+//"` ;;
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
hwe_def=1.E-4
hwe=${hwe_def}
famfile=''
imajor='no'
keep='no'
mapfile=''
nfield=4
outprefix='plink'
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
tmpprefix=${outprefix}_tmp
mafqc="--maf ${freq}"
if [[ "${freq}" == "0" ]] ; then mafqc="" ; fi
qc="${mafqc} --geno ${vmiss} --mind ${smiss} --hwe ${hwe}"
sexup=""
if [[ "${famfile}" != "" ]] ; then
    sexup="--update-sex ${famfile} 3"
fi
mapper=''
if [[ "${mapfile}" != "" && -s "${mapfile}" ]] ; then
    mapper="--extract ${mapfile} --update-name ${mapfile}"
fi
if [[ "${dfiles[@]}" == "" ]] ; then
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) [OPTIONS] <pseudo dosage file(s)>\n"
    echo -e "   where\n"
    echo -e "     <pseudo dosage file(s)> are the imputation files containing pseudo counts (0..2)."
    echo -e "\n NOTE: the script expects there to be 'info.gz' files with the same root file name as the 'dose.gz' files."
    echo -e "\n OPTIONS:"
    echo -e "     -a                    no header present: anonymous sample information will be made up (only relevant for variant-major format)"
    echo -e "     -c <avcall>           average call threshold for inclusion [default: ${avcall_def}]"
    echo -e "     -d <delta>            max difference between hard-call (0,1,2) genotype and pseudo count [default: ${delta_def}]"
    echo -e "     -e <p-value>          p-value for Hardy-Weiberg equilibrium [default: ${hwe_def}]"
    echo -e "     -f <freq>             minor allele frequency threshold for inclusion [default: ${freq_def}]"
    echo -e "     -h                    phased haplotypes format (two lines per sample) [forces individual major mode]"
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
    exit 0
fi

count=1
outlist=${outprefix}.list
echo -n > ${outlist}
for dfile in "${dfiles[@]}" ; do
    tmp=${tmpprefix}_${count}
    echo -e "\n makebed.sh options in use:" > ${tmp}_makebed.log
    echo -e "     input file            '${dfile}'" >> ${tmp}_makebed.log
    echo -e "     avcall                ${avcall}" >> ${tmp}_makebed.log
    echo -e "     delta                 ${delta}" >> ${tmp}_makebed.log
    echo -e "     freq                  ${freq}" >> ${tmp}_makebed.log
    echo -e "     haplotypes            ${haplo}" >> ${tmp}_makebed.log
    echo -e "     header                ${head}" >> ${tmp}_makebed.log
    echo -e "     hwe-p                 ${hwe}" >> ${tmp}_makebed.log
    echo -e "     individual-major      ${imajor}" >> ${tmp}_makebed.log
    echo -e "     keep files            ${keep}" >> ${tmp}_makebed.log
    echo -e "     map file              '${mapfile}'" >> ${tmp}_makebed.log
    echo -e "     start field           $(( nfield ))($(( nfield - 1 )))" >> ${tmp}_makebed.log
    echo -e "     output prefix         ${outprefix}" >> ${tmp}_makebed.log
    echo -e "     fam file              '${famfile}'" >> ${tmp}_makebed.log
    echo -e "     rsq                   ${rsq}" >> ${tmp}_makebed.log
    echo -e "     smiss                 ${smiss}" >> ${tmp}_makebed.log
    echo -e "     vmiss                 ${vmiss}" >> ${tmp}_makebed.log
    echo >> ${tmp}_makebed.log
    if [[ ! -f "${tmp}.bed" ]] ; then
        if [[ "${imajor}" == "no" ]] ; then
            echo "expecting variant-major file.."
            ifile=$( echo ${dfile} | sed -r 's/(.dose.gz|.hapDose.gz)$//g;' ).info.gz
            echo "probing info file '${ifile}'.."
            if [[ -s "${dfile}" && -s "${ifile}" ]] ; then
                echo -n "extracting hard-call dosages.. "
                awk -F $'\t' $AWK_LOCAL_INCLUDE \
                -v avcall=${avcall} \
                -v delta=${delta} \
                -v freq=${freq} \
                -v rsq=${rsq} \
                -v n=${nfield} \
                -v out=${tmp} \
                -v head=${head} \
                --source '{
                    OFS = "\t";
                    if ( NR == FNR ) {
                        varmaf[NR] = $5
                        varcall[NR] = $6
                        varrsq[NR] = $7
                    }
                    else {
                        if ( FNR == 1 ) {
                            if ( head == "yes" ) {
                                for ( i = n; i <= NF; i++ ) {
                                    split( $i, idvec, " " );
                                    printf( "%s\t%s\t0\t0\t-9\t-9\n", idvec[1], idvec[2] ) > out".tfam";
                                }
                            }
                            else {
                                for ( i = n; i <= NF; i++ ) {
                                    pname = "P"( roundstd( ( $1 - n + 1 ) / 2 ) )
                                    printf( "%s\t%s\t0\t0\t-9\t-9\n", pname, pname ) > out".tfam";
                                }
                            }
                        }
                        if ( head != "yes" || FNR > 1 ) {
                            chrnum = $1;
                            chrpos = $1
                            gsub( "^(chr)?", "", chrnum );
                            gsub( "[_:].+$", "", chrnum );
                            gsub( "^[^_:]+[_:]", "", chrpos );
                            gsub( "[_:].+$",     "", chrpos );
                            printvar = 1
                            printvar = printvar && varmaf[FNR-1] >= freq
                            printvar = printvar && varcall[FNR-1] >= avcall
                            printvar = printvar && varrsq[FNR-1] >= rsq
                            if ( printvar ) {
                              printf( "%s\t%s\t%d\t%d", chrnum, $1, 0, chrpos );
                              for ( i = n; i <= NF; i++ ) {
                                  a = roundstd( $i - 1 );
                                  if ( a < 0 ) a = 0;
                                  b = roundstd( $i - a );
                                  mygenotype = a + b;
                                  printgeno = abs( $i - mygenotype ) < delta
                                  if ( printgeno ) {
                                      if ( mygenotype == 0 ) printf( "\t%s %s", $2, $2 );
                                      else if ( mygenotype == 1 ) printf( "\t%s %s", $2, $3 );
                                      else if ( mygenotype == 2 ) printf( "\t%s %s", $3, $3 );
                                  }
                                  else printf( "\t%s %s", 0, 0 );
                              }
                              printf( "\n" );
                            }
                        }
                    }
                }' <( zcat -f ${ifile} | tail -n +2 ) <( zcat -f ${dfile} ) > ${tmp}.tped
                echo "done."
                if [[ -s "${tmp}.tfam" && -s "${tmp}.tped" ]] ; then
                    echo "converting to binary genotypes.. "
                    plink --tfile ${tmp} ${qc} ${sexup} --make-bed --out ${tmp}
                    echo "done."
                    if [[ -s "${tmp}.bed" && -s "${tmp}.bim" && -s "${tmp}.fam" && "${mapper}" != "" ]] ; then
                        echo "re-mapping variants according to '${mapfile}'.. "
                        plink --bfile ${tmp} ${mapper} --make-bed --out ${tmp}
                        echo "done."
                    fi
                    if [[ "${keep}" == "no" ]] ; then
                        echo "removing temporary files.. "
                        rm -v ${tmp}.tfam ${tmp}.tped
                        echo "done."
                    fi
                fi
            fi
        else
            echo "expecting individual-major file.."
            ifile=$( echo ${dfile} | sed -r 's/(.dose.gz|.hapDose.gz)$//g;' ).info.gz
            if [[ -s "${dfile}" && -s "${ifile}" ]] ; then
              if [[ "${haplo}" == "no" ]] ; then
                  echo "extracting hard-call dosages.. "
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
                          pos[NR] = $1
                          gsub( "[_:].+$",       "", chr[NR] );
                          gsub( "^(chr)?",       "", chr[NR] );
                          gsub( "^(chr)?.+[_:]", "", pos[NR] );
                          var[NR] = $1
                          a0lab[NR] = $2
                          a1lab[NR] = $3
                          varmaf[NR] = $5
                          varcall[NR] = $6
                          varrsq[NR] = $7
                          printvar = 1
                          printvar = printvar && varmaf[NR] >= freq
                          printvar = printvar && varcall[NR] >= avcall
                          printvar = printvar && varrsq[NR] >= rsq
                          if ( printvar ) print( chr[NR], var[NR], 0, pos[NR] ) > out".map"
                      }
                      else {
                          split( $1, idvec, "->" );
                          printf( "%s\t%s\t0\t0\t-9\t-9", idvec[1], idvec[2] )
                          for ( i = n-1; i <= NF; i++ ) {
                              a = roundstd( $i - 1 );
                              if ( a < 0 ) a = 0;
                              b = roundstd( $i - a );
                              mygenotype = a + b;
                              printvar = 1
                              printvar = printvar && varmaf[i-(n-1)+1] >= freq
                              printvar = printvar && varcall[i-(n-1)+1] >= avcall
                              printvar = printvar && varrsq[i-(n-1)+1] >= rsq
                              if ( printvar ) {
                                printgeno = abs( $i - mygenotype ) < delta
                                if ( printgeno ) {
                                    if ( mygenotype == 0 ) printf( "\t%s %s", a0lab[i-(n-1)+1], a0lab[i-(n-1)+1] );
                                    else if ( mygenotype == 1 ) printf( "\t%s %s", a1lab[i-(n-1)+1], a0lab[i-(n-1)+1] );
                                    else if ( mygenotype == 2 ) printf( "\t%s %s", a1lab[i-(n-1)+1], a1lab[i-(n-1)+1] );
                                }
                                else printf( "\t%s %s", 0, 0 );
                              }
                          }
                          printf( "\n" );
                      }
                  }' <( zcat -f ${ifile} | tail -n +2 ) <( zcat -f ${dfile} ) > ${tmp}.ped
              else
                  echo "extracting phased haplotypes.. "
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
                          gsub( "[_:].+$", "", chr[NR] );
                          gsub( "^(chr)?", "", chr[NR] );
                          pos[NR] = $1
                          gsub( "^(chr)?.+[_:]", "", pos[NR] );
                          var[NR] = $1
                          a0lab[NR] = $2
                          a1lab[NR] = $3
                          varmaf[NR] = $5
                          varcall[NR] = $6
                          varrsq[NR] = $7
                          printvar = 1
                          printvar = printvar && varmaf[NR] >= freq
                          printvar = printvar && varcall[NR] >= avcall
                          printvar = printvar && varrsq[NR] >= rsq
                          if ( printvar ) print( chr[NR], var[NR], 0, pos[NR] ) > out".map"
                      }
                      else {
                        NG = NF;
                        split( $0, haploA );
                          split( haploA[1], idvecA, "->" );
                        getline;
                        split( $0, haploB );
                          split( haploB[1], idvecB, "->" );
                          if ( idvecA[1] != idvecB[1] || idvecA[2] != idvecB[2] ) {
                            print( "\nid mismatch: aborting..\n" );
                            exit;
                          }
                          printf( "%s\t%s\t0\t0\t-9\t-9", idvecA[1], idvecA[2] )
                          for ( i = n-1; i <= NG; i++ ) {
                              a = roundstd( haploA[i] );
                              b = roundstd( haploB[i] );
                              printvar = 1
                              printvar = printvar && varmaf[i-(n-1)+1] >= freq
                              printvar = printvar && varcall[i-(n-1)+1] >= avcall
                              printvar = printvar && varrsq[i-(n-1)+1] >= rsq
                              if ( printvar ) {
                                printgeno = abs(haploA[i] - a) + abs($haploB[i] - b) < delta
                                if ( printgeno ) {
                                  tmpna = 0;
                                  tmpnb = 0;
                                  if (a == 0) tmpna = a0lab[i-(n-1)+1];
                                  else if (a == 1) tmpna = a1lab[i-(n-1)+1];
                                  if (b == 0) tmpnb = a0lab[i-(n-1)+1];
                                  else if (b == 1) tmpnb = a1lab[i-(n-1)+1];
                                  printf( "\t%s %s", tmpna, tmpnb );
                                }
                                else printf( "\t%s %s", 0, 0 );
                              }
                          }
                          printf( "\n" );
                      }
                  }' <( zcat -f ${ifile} | tail -n +2 ) <( zcat -f ${dfile} ) > ${tmp}.ped
              fi
                echo "done."
                if [[ -s "${tmp}.map" && -s "${tmp}.ped" ]] ; then
                    echo "converting to binary genotypes.. "
                    plink --file ${tmp} ${qc} ${sexup} --make-bed --out ${tmp}
                    echo "done."
                    if [[ -s "${tmp}.bed" && -s "${tmp}.bim" && -s "${tmp}.fam" && "${mapper}" != "" ]] ; then
                        echo "re-mapping variants according to '${mapfile}'.. "
                        plink --bfile ${tmp} ${mapper} --make-bed --out ${tmp}
                        echo "done."
                    fi
                    if [[ "${keep}" == "no" ]] ; then
                        echo "removing temporary files.. "
                        rm -v ${tmp}.map ${tmp}.ped
                        echo "done."
                    fi
                fi
            fi
        fi
    else
        echo "bed file exists: skipping '${dfile}'.."
    fi
    if [[ -s "${tmp}.bed" && -s "${tmp}.bim" && -s "${tmp}.fam" ]] ; then
        echo "adding files '${tmp}*' to the list.."
        echo "${tmp}" >> ${outlist}
    fi
    count=$(( count + 1 ))
done
if [[ -s "${outlist}" ]] ; then
    if (( ${#dfiles[@]} == 1 )) ; then
        echo "renaming temporary files.."
        for tmpfile in "${tmp}"* ; do
            mv "${tmpfile}" "${tmpfile/${tmp}/${outprefix}}"
        done
    else
        echo "merging temporary files.."
        plink --merge-list ${outlist} --out ${outprefix}
        if [[ -s "${outprefix}-merge.missnp" ]] ; then
            tmpexcl=$( mktemp .tmpXXXXXX )
            sort -u ${outprefix}-merge.missnp > ${tmpexcl}
            if [[ -s "${outprefix}.missnp" ]] ; then
                sort -u ${outprefix}-merge.missnp ${outprefix}.missnp > ${tmpexcl}
            fi
            for bfile in $( cat ${outlist} ) ; do
                plink --bfile ${bfile} --exclude ${tmpexcl} --make-bed --out ${bfile}
            done
            plink --merge-list ${outlist} --out ${outprefix}
            rm -v ${tmpexcl}
        fi
    fi
    if [[ "${keep}" == "no" ]] ; then
        rm -fv ${tmpprefix}*
    fi
fi

