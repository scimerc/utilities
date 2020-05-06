#!/bin/bash

trap 'exit' ERR

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

get_col_index() {
  local table="$1"
  local field="$2"
  cindex=$(
    zcat -f "${table}" \
    | head -n 1 \
    | tr "\t" "\n" \
    | grep -m1 -nx "${field}" \
    | cut -d ":" -f 1 || true
  )
  [ -z ${cindex} ] && cindex=-1
  printf '%d' ${cindex}
}

opt_parser="${BASEDIR}/lib/sh/opt_parser.sh"
opt_list=("h" "a=" "b=" "c=" "d=" "e=" "f=" "i=" "l=" "m=" "n=" "p=" "r=" "t=" "o=")
get_opt ()
{
    case $1 in
        "h" )
            helpme="yes" ;;
        "a" )
            rstart=`echo "$2" | sed "s/^=\+//"` ;;
        "b" )
            rstop=`echo "$2" | sed "s/^=\+//"` ;;
        "c" )
            rchr=`echo "$2" | sed "s/^=\+//"` ;;
        "d" )
            rdes=`echo "$2" | sed "s/^=\+//"` ;;
        "e" )
            eatag=`echo "$2" | sed "s/^=\+//"` ;;
        "f" )
            neatag=`echo "$2" | sed "s/^=\+//"` ;;
        "i" )
            infotag=`echo "$2" | sed "s/^=\+//"` ;;
        "l" )
            labtag=`echo "$2" | sed "s/^=\+//"` ;;
        "m" )
            maftag=`echo "$2" | sed "s/^=\+//"` ;;
        "n" )
            nametag=`echo "$2" | sed "s/^=\+//"` ;;
        "p" )
            ptag=`echo "$2" | sed "s/^=\+//"` ;;
        "r" )
            reflist=`echo "$2" | sed "s/^=\+//"` ;;
        "t" )
            pthresh=`echo "$2" | sed "s/^=\+//"` ;;
        "o" )
            outfile=`echo "$2" | sed "s/^=\+//"` ;;
    esac
}
helpme=""
eatag_def="A1"
eatag=${eatag_def}
neatag_def="A2"
neatag=${neatag_def}
nametag_def="SNP"
nametag=${nametag_def}
pthresh_def="5.E-8"
pthresh=${pthresh_def}
pvaltag_def="PVAL"
ptag=${pvaltag_def}
infotag_def="RSQ"
infotag=${infotag_def}
labtag_def="HET"
labtag=${labtag_def}
maftag_def="FRQ"
maftag=${maftag_def}
infothresh=0.8
labthresh=0.05
mafthresh=0.01
outfile_def=out
outfile=${outfile_def}
reflist=''
rchr=6
rstart=25392021
rstop=33392022
rdes='mhc'
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
mystats=$( cat ${tmpargs} )
rm -f ${tmpargs}
nameflag="--clump-snp-field ${nametag}"
refarr=( ${reflist//,/ } )
if [[ "${helpme}" != "" || "${reflist}" == "" || "${mystats}" == "" ]] ; then

    if [[ "${helpme}" == "" ]] ; then
        echo "you may have neglected to provide input.";
    else
        echo "$( basename $0 ) plink-clumps summary statistics based on the correlation structure in the reference"
        echo "genotypes provided: the output is tab-separated in the format '<core> <tag> <p>', where <core> is the"
        echo "clump core variant name as it appears in the original summary statistics, <tag> is the variant in the"
        echo "reference (in format <chr:bp>) that best tags it, and <p> is the clump's summary p-value statistic."
        echo "a special region can be specified for which a single variant representative will be selected."
        #TODO: implement multiple special regions
    fi
    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) [OPTIONS] -r <reference(s)> <summary stats file(s)>"
    echo -e "\n OPTIONS:"
    echo -e "     -a <start>       special region start position [default: MHC GRCh37 start]"
    echo -e "     -b <stop>        special region stop position [default: MHC GRCh37 stop]"
    echo -e "     -c <chromosome>  special region chromosome [default: chr 6]"
    echo -e "     -d <name>        special region designation [default: 'mhc']"
    echo -e "     -e <field name>  header field marking the effect allele [default: ${eatag_def}]"
    echo -e "     -f <field name>  header field marking the non-effect allele [default: ${neatag_def}]"
    echo -e "     -i <field name>  header field marking the information r-squared [default: ${infotag_def}]"
    echo -e "     -l <field name>  header field marking the cross-study effect lability [default: ${labtag_def}]"
    echo -e "     -m <field name>  header field marking the allelic frequency [default: ${maftag_def}]"
    echo -e "     -n <field name>  header field marking the variable name [default: ${nametag_def}]"
    echo -e "     -p <field name>  header field marking the association p-value [default: ${pvaltag_def}]"
    echo -e "     -r <reference>   comma-separated list of plink binary file set identifier(s) [must be specified]:"
    echo -e "                      the idea is to do sample-specific LD-structure clumping while reducing the loss of"
    echo -e "                      information that may arise from the use of an incomplete reference. the order the"
    echo -e "                      reference sets are presented matters: the first one should be as complete as"
    echo -e "                      possible (e.g. 1KG) to ensure comprehensive clumps; any additional ones are"
    echo -e "                      expected to be representative of the sample of interest."
    echo -e "     -t <threshold>   p-value threshold for cross-referencing [default: ${pthresh_def}]:"
    echo -e "                      the script will find the best available LD-proxy for any missing variants below"
    echo -e "                      this threshold."
    echo -e "     -o <prefix>      output prefix [default: ${outfile_def}]"
    echo -e "     -h               print this help and exit"
    echo

else

    echo -e "clump.sh options in use:" > ${outfile}.log
    echo -e "     input files           '${mystats}'" >> ${outfile}.log
    echo -e "     special region chrom  ${rchr}" >> ${outfile}.log
    echo -e "     special region start  ${rstart}" >> ${outfile}.log
    echo -e "     special region end    ${rstop}" >> ${outfile}.log
    echo -e "     effect variant field  ${eatag}" >> ${outfile}.log
    echo -e "     other variant field   ${neatag}" >> ${outfile}.log
    echo -e "     variant name field    ${nametag}" >> ${outfile}.log
    echo -e "     info-rsq name field   ${infotag}" >> ${outfile}.log
    echo -e "     info-rsq threshold    ${infothresh}" >> ${outfile}.log
    echo -e "     lability name field   ${labtag}" >> ${outfile}.log
    echo -e "     lability threshold    ${labthresh}" >> ${outfile}.log
    echo -e "     frequency name field  ${maftag}" >> ${outfile}.log
    echo -e "     frequency threshold   ${mafthresh}" >> ${outfile}.log
    echo -e "     p-value field         ${ptag}" >> ${outfile}.log
    echo -e "     reference             ${reflist}" >> ${outfile}.log
    echo -e "     cross-ref threshold   ${pthresh}" >> ${outfile}.log
    echo -e "     output prefix         ${outfile}" >> ${outfile}.log
    echo >> ${outfile}.log

    for sfile in ${mystats} ; do
        echo "processing '${sfile}'.."
        awkvars="
          -v infothresh=${infothresh}
          -v labthresh=${labthresh}
          -v mafthresh=${mafthresh}
        "
        sortcmd=sort
        for htag in eatag neatag nametag ; do
            hfield=${htag%tag}field
            eval ${hfield}=$( get_col_index ${sfile} ${!htag} )
            awkvars="${awkvars} $( printf '%cv %s=%s\n' '-' ${hfield} ${!hfield} )"
        done
        for htag in infotag labtag maftag ; do
            hfield=${htag%tag}field
            eval ${hfield}=$( get_col_index ${sfile} ${!htag} )
            awkvars="${awkvars} $( printf '%cv %s=%s\n' '-' ${hfield} ${!hfield} )"
            [ ${!hfield} -gt 0 ] && sortcmd="${sortcmd} -k ${!hfield},${!hfield}gr"
        done
        [ "${sortcmd}" == "sort" ] && sortcmd=cat
        for k in $( seq 1 ${#refarr[@]} ) ; do
            tmpfile=$( mktemp -u .tmpXXXXXX )
            while [[ -f ${tmpfile}.clumped ]] ; do
                tmpfile=$( mktemp -u .tmpXXXXXX )
            done
            echo "projecting onto '${refarr[$((k-1))]}'.."
            {
              zcat -f ${sfile} | head -n 1
              zcat -f ${sfile} | tail -n +2 \
              | ${sortcmd} \
              | sort -u -k ${namefield},${namefield} \
              | awk -F $'\t' $AWK_LOCAL_INCLUDE \
                -v logfile=${outfile}.log ${awkvars} --source '{
                if ( NR == FNR ) {
                  OFS=FS
                  if ( NR == 1 ) {
                    ambcount = 0
                    flipcount = 0
                  }
                  if ( nucleocode($5) != comp_nucleocode($6) ) {
                    vcatalog[ $2 ] = $5"/"$6
                  }
                  else ambcount++
                }
                else if ( $(namefield) in vcatalog ) {
                  printvar = 1
                  if ( infofield > 0 ) printvar = printvar && $(infofield) > infothresh
                  if ( labfield > 0 ) printvar = printvar && $(labfield) > labthresh
                  if ( maffield > 0 ) printvar = printvar && 1.-$(maffield) > mafthresh
                  if ( maffield > 0 ) printvar = printvar && $(maffield) > mafthresh
                  if ( printvar ) {
                    split( vcatalog[ $(namefield) ], avec, "/" )
                    if ( neafield < 0 ) {
                      if ( nucleocode( $(eafield) ) == comp_nucleocode( avec[1] ) || \
                           nucleocode( $(eafield) ) == comp_nucleocode( avec[2] ) ) {
                        $(eafield) = i_to_A( comp_nucleocode(nucleocode($(eafield))) )
                        flipcount++
                      }
                    }
                    else if ( gflip( avec[1], avec[2], $(eafield), $(neafield) ) ) {
                      $(eafield) = i_to_A( comp_nucleocode(nucleocode($(eafield))) )
                      $(neafield) = i_to_A( comp_nucleocode(nucleocode($(neafield))) )
                      flipcount++
                    }
                    print
                  }
                }
              } END {
                print( ambcount " ambiguous variants removed." ) >> logfile
                print( flipcount " flipped strands." ) >> logfile
              }' ${refarr[$((k-1))]}.bim /dev/stdin
            } | gzip -c > ${outfile}.prep.gz
            plink --bfile ${refarr[$((k-1))]} --clump ${outfile}.prep.gz ${nameflag} \
                --clump-field ${ptag} --clump-p1 1 --clump-kb 500 --clump-r2 0.25 --out ${tmpfile}
            if (( k > 1 )) ; then
                tmpstack=$( mktemp .tmpXXXX )
                awk -F $'\t' -v p=${pthresh} '{
                    if ( FNR == NR && NR > 1 ) {
                        # the first file is the current (typically the reference) clump file
                        # if the index has p-value below the chosen threshold, annotate the block
                        if ( $5 < p ) {
                            clump[$3] = $3  # index name
                            pval[$3] = $5   # index p-value
                            split( $12, blockarr, "," )
                            for ( k in blockarr ) {
                                gsub( "[(][.0-9]+[)]", "", blockarr[k] )
                                clump[blockarr[k]] = $3
                                pval[blockarr[k]] = $5
                            }
                        }
                    }
                    else {
                        OFS="\t"
                        delete clump["NONE"]
                        delete pval["NONE"]
                        # the second file is the new clump file
                        if ( FNR > 1 ) {
                            printflag = 1
                            split( $12, blockarr, "," )
                            # add index name to block before the first entry so it is processed
                            # first in the blockarr for clause
                            blockarr[0] = $3
                            # search block for existing (usually reference) indexes
                            for ( k in blockarr ) {
                                if ( blockarr[k] in pval ) {
                                    gsub( "[(][.0-9]+[)]", "", blockarr[k] )
                                    # rename variant with index name
                                    $5 = pval[blockarr[k]]
                                    # assign variant index p-value
                                    $3 = clump[blockarr[k]]
                                    # suppress printing if variant already there
                                    if ( clump[blockarr[k]] in catalog ) printflag = 0
                                    else catalog[clump[blockarr[k]]] = 1
                                    # should we break the for loop here?
                                }
                            }
                            if ( printflag == 1 ) print
                        }
                    }
                }' \
                <( tab < ${outfile}.clumped | trim ) \
                <( tab < ${tmpfile}.clumped | trim ) \
                > ${tmpstack}
                mv ${tmpstack} ${tmpfile}.clumped
            fi
            tab < ${tmpfile}.clumped | trim | awk -F $'\t' '{
                if ( NF > 1 ) {
                    OFS="\t"
                    $4=$1":"$4
                    print
                }
            }' > ${outfile}.clumped
            rm -f ${tmpfile}*
        done
        cut -f 3-5 ${outfile}.clumped > ${outfile}.clumpcores.tsv
        regbest=$(
            awk -F $'\t' -v rchr=${rchr} -v rstart=${rstart} -v rstop=${rstop} '{
                OFS="\t"
                split( $2, vararr, ":" )
                if ( vararr[1] == rchr && vararr[2] >= rstart && vararr[2] <= rstop ) print
            }' ${outfile}.clumpcores.tsv | sort -k 3,3g | head -n 1 | cut -f 1 )
        awk -F $'\t' -v mb=${regbest} -v rchr=${rchr} -v rstart=${rstart} -v rstop=${rstop} '{
            OFS="\t"
            split( $2, vararr, ":" )
            if ( $1 == mb || vararr[1] != rchr || vararr[2] < rstart || vararr[2] > rstop ) print
        }' ${outfile}.clumpcores.tsv > ${outfile}.clumpcores.mhcbest.tsv
    done

fi

