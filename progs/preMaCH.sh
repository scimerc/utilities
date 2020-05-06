#!/bin/bash
basedir="/cluster/projects/p33/groups/biostat/software"
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
hvmscript="${basedir}/progs/het_vs_miss.Rscript"
opt_parser="${basedir}/lib/sh/opt_parser.sh"
opt_list=("b=" "dups" "g=" "i=" "maf=" "nohvm" "o=" "p=" "r=" "s=" "v=" "h")
get_opt ()
{
    case $1 in
        "b" )
            blacklist=`echo "$2" | sed "s/^=\+//"` ;;
        "dups" )
            keepdups='on' ;;
        "g" )
            genome=`echo "$2" | sed "s/^=\+//"` ;;
        "i" )
            samplefile=`echo "$2" | sed "s/^=\+//"` ;;
        "maf" )
            myfreq_std=`echo "$2" | sed "s/^=\+//"` ;;
        "nohvm" )
            hvm='off' ;;
        "o" )
            myprefix=`echo "$2" | sed "s/^=\+//"` ;;
        "p" )
            phenotypes=`echo "$2" | sed "s/^=\+//"` ;;
        "r" )
            refalleles=`echo "$2" | sed "s/^=\+//"` ;;
        "s" )
            samplemiss=`echo "$2" | sed "s/^=\+//"` ;;
        "v" )
            varmiss=`echo "$2" | sed "s/^=\+//"` ;;
        "h" )
            helpme='yes' ;;
    esac
}
helpme=''
blacklist=''
genome='hg19'
hvm='on'
hweneglogp=12
hweneglogp_ctrl=4
keepdups='off'
myfreq_hq=0.2
myfreq_std=0.05
myprefix='plink'
phenotypes=''
pihat=0.9
refalleles=''
samplefile=''
samplemiss=0.05
varmiss=0.05
tmpargs=''
while [[ "${tmpargs}" == "" ]] ; do
    tmpargs=$( mktemp .tmpXXXXXXXX )
done
source ${opt_parser} > ${tmpargs}
mybatches=$( cat ${tmpargs} )
rm -f ${tmpargs}

if [[ "${mybatches}" == "" || "${helpme}" != "" ]] ; then

    if [[ "${helpme}" == "" ]] ; then echo "missing input."; fi

    echo -e "\n USAGE:"
    echo -e "     $( basename $0 ) [OPTIONS] <bed file(s)>\n"
    echo -e "   where\n"
    echo -e "     <bed file(s)> are the binary plink files to be merged."
    echo -e "\n OPTIONS:"
    echo -e "     -b <black list>             recommended list of bad (high LD) regions (bed format)"
    echo -e "     -dups                       keep duplicate individuals [default: off]"
    echo -e "     -g <genome version>         genome version [default: hg19]"
    echo -e "     -i <sample file>            optional sample selection file"
    echo -e "     -maf <freq>                 minor allele frequency filter"
    echo -e "     -nohvm                      turns off heterozygosity VS missingness tests"
    echo -e "     -o <output prefix>          optional output prefix [default: 'plink']"
    echo -e "     -p <phenotype file>         optional file with 'affected'/'control' status tags"
    echo -e "     -r <reference alleles>      tab separated reference alleles [format: <SNP> <A1> <A2>]"
    echo -e "     -s <sample missingness>     maximum fraction of variants missing in an individual genotype"
    echo -e "     -v <variant missingness>    maximum fraction of genotypes missing for an individual variant"
    echo -e "     -h                          print help\n"

else

    echo -e "==== preMaCH.sh -- $(date)\n"
    echo -e "==== options in effect:\n"
    echo "     blacklist=${blacklist}"
    echo "     keepdups=${keepdups}"
    echo "     genome=${genome}"
    echo "     samplefile=${samplefile}"
    echo "     hvm=${hvm}"
    echo "     myprefix=${myprefix}"
    echo "     phenotypes=${phenotypes}"
    echo "     refalleles=${refalleles}"
    echo "     samplemiss=${samplemiss}"
    echo "     varmiss=${varmiss}"
    echo -e "\n==================================\n"
    echo -e "batch files:\n$( ls ${mybatches} )"
    echo -e "\n==================================\n"

    mydir=$( dirname ${myprefix} )
    mkdir -p ${mydir}

    mybatchfile=${myprefix}_batches
    ls ${mybatches} | sed -r 's/[.]bed$//g;' > ${mybatchfile}
    mybatchvec=( $mybatches )
    outprefix=${myprefix}
    if (( ${#mybatchvec[*]} > 1 )) ; then
        outprefix=${myprefix}_merged
    fi

    if [[ "${phenotypes}" == "" || ! -f "${phenotypes}" ]] ; then
        hweneglogp=${hweneglogp_ctrl}
    fi

    plinkflagsdef=""
    if [[ "${samplefile}" != "" && -f "${samplefile}" ]] ; then
        plinkflagsdef="--keep ${samplefile}"
    fi

    if [[ ! -f ${outprefix}.bed || ! -f ${outprefix}.bim || ! -f ${outprefix}.fam ]] ; then
        excludefile=${outprefix}.exclude
        echo -n > ${excludefile}
        procdir=${myprefix}_qc.proc
        mkdir -p ${procdir}
        goflag=""
        while [[ "${goflag}" == "" ]] ; do
            goflag="go"
            tmpbatchfile=$( mktemp .tmpbatch.XXXXXX )
            echo "created temporary batch file ${tmpbatchfile}."
            echo -n > ${tmpbatchfile}
            for batch in $( cat ${mybatchfile} ) ; do
                echo "processing batch ${batch}.."
                tmpfile=$( mktemp .tmpctrl.XXXXXX )
                echo "created temporary variant control file ${tmpfile}."
                batchctrl=${procdir}/$( basename ${batch} ).fatto
                batchexcludefile=${procdir}/$( basename ${batch} ).exclude
                batchflipfile=${procdir}/$( basename ${batch} ).flip
                if [[ -f ${excludefile} ]] ; then
                    sort -u ${excludefile} >> ${batchexcludefile}
                fi
                tmpbatch=${batch}
                if [[ ! -f ${batchctrl} ]] ; then
                    if [[ -s ${tmpbatch}.bim ]] ; then
                        for chr in $( cut -f 1 ${tmpbatch}.bim | sort -u ) ; do
                            tmpvardups=$( mktemp .tmpchr${chr}.XXXXXX )
                            chrbatchprefix=${procdir}/$( basename ${tmpbatch} )_chr${chr}
                            while [[ ! -f ${chrbatchprefix}.tped ]] ; do
                                plink --bfile ${tmpbatch} --chr ${chr} --recode transpose --out ${chrbatchprefix}
                            done
                            # extract marker information corresponding to unique position-specific genotype series:
                            # identical position-specific genotype series will thereby be ignored as harmless here.
                            sort -t ' ' -u -k 4 ${chrbatchprefix}.tped | cut -d ' ' -f 1-4 | sort -t ' ' -k 4,4 \
                                > ${chrbatchprefix}.gp
                            echo "extracting marker information for unique position-specific genotype series.."
                            cut -d ' ' -f 3,4 ${chrbatchprefix}.gp | sort -t ' ' | uniq -d | sort -t ' ' -k 2,2 \
                            | join -t ' ' -1 4 -2 2 ${chrbatchprefix}.gp - | cut -d ' ' -f 3 | sort -u \
                                > ${tmpvardups}
                            echo -n "$( wc -l ${tmpvardups} | cut -d ' ' -f 1 ) "
                            echo "non-coherent duplicate variants marked for deletion in chromosome ${chr}."
                            cat ${tmpvardups} >> ${batchexcludefile}
                            cut -d ' ' -f 2,3,4 ${chrbatchprefix}.tped | sort -t ' ' -k 1,1 \
                            | join -t ' ' -v1 - ${tmpvardups} | sort -t ' ' -k 3,3 > ${chrbatchprefix}.gp
                            echo "extracting coherent variants from the set of duplicate variants.."
                            cut -d ' ' -f 3 ${chrbatchprefix}.gp | uniq -d \
                            | join -t ' ' -2 3 - ${chrbatchprefix}.gp | sort -t ' ' -k 3,3r \
                            | sort -t ' ' -u -k 1,1 | cut -d ' ' -f 2 | sort -u > ${tmpvardups}
                            echo -n "$( wc -l ${tmpvardups} | cut -d ' ' -f 1 ) "
                            echo "unique coherent duplicate variants retained in chromosome ${chr}."
                            cut -d ' ' -f 3 ${chrbatchprefix}.gp | uniq -d \
                            | join -t ' ' -2 3 - ${chrbatchprefix}.gp | cut -d ' ' -f 2 | sort \
                            | join -t ' ' -v1 - ${tmpvardups} >> ${batchexcludefile}
                            rm ${tmpvardups}
                        done
                    fi
                    touch ${batchflipfile} ${batchexcludefile}
                    if [[ "${refalleles}" != "" && -s ${tmpbatch}.bim ]] ; then
                        echo "matching variants to reference.."
                        awk -F $'\t' '{ OFS="\t"; $7 = $1":"$4; print; }' ${tmpbatch}.bim | sort -t $'\t' -k 7,7 \
                        | join -t $'\t' -a2 -2 7 ${refalleles} - | awk -F $'\t' $AWK_LOCAL_INCLUDE \
                        -v batchexcludefile=${batchexcludefile} -v batchflipfile=${batchflipfile} \
                        --source 'BEGIN{
                            total_miss = 0
                            total_mism = 0
                            total_flip = 0
                        } {
                            if ( NF < 9 ) {
                                print( $2 ) >>batchexcludefile
                                total_miss++
                            }
                            else {
                                if ( !gmatch( $2, $3, $8, $9 ) ) {
                                    print( $5 ) >>batchexcludefile
                                    total_mism++
                                }
                                else if ( gflip( $2, $3, $8, $9 ) ) {
                                    print( $5 ) >>batchflipfile
                                    total_flip++
                                }
                            }
                        } END{
                            print( "total missing: ", total_miss )
                            print( "total mismatch: ", total_mism )
                            print( "total flipped: ", total_flip )
                        }'
                    fi
                    touch ${batchctrl}
                fi
                plinkflags=${plinkflagsdef}
                sort -u ${batchexcludefile} > $tmpfile
                mv $tmpfile ${batchexcludefile}
                sort -u ${batchflipfile} > $tmpfile
                mv $tmpfile ${batchflipfile}
                echo "$( wc -l ${batchexcludefile} ) variants to be excluded."
                echo "$( wc -l ${batchflipfile} ) variants to be flipped."
                if [[ -s ${batchexcludefile} ]] ; then
                    plinkflags="${plinkflags} --exclude ${batchexcludefile}"
                fi
                if [[ -s ${batchflipfile} ]] ; then
                    plinkflags="${plinkflags} --flip ${batchflipfile}"
                fi
                if [[ "${plinkflags}" != "" ]] ; then
                    mytag=""
                    echo "polishing batch ${batch}.."
                    while [[ -f ${tmpbatch}.bed ]] ; do
                        tmpbatch=${procdir}/$( basename ${batch} )${mytag}
                        mytag="${mytag}Z"
                    done
                    plink --bfile ${batch} ${plinkflags} --make-bed --out ${tmpbatch}
                    if [[ -f ${tmpbatch}.bim ]] ; then
                        perl -p -i -e 's/[ \t]+/\t/g' ${tmpbatch}.bim
                    fi
                    if [[ -f ${tmpbatch}.fam ]] ; then
                        perl -p -i -e 's/[ \t]+/\t/g' ${tmpbatch}.fam
                    fi
                    if [[ -s ${tmpbatch}.bim && -s ${batchexcludefile} ]] ; then
                        awk -F $'\t' '{ OFS="\t"; $2 = $1":"$4; print; }' ${tmpbatch}.bim > ${tmpfile}
                        mv ${tmpfile} ${tmpbatch}.bim
                    fi
                    tmpbatchctrl=${procdir}/$( basename ${tmpbatch} ).fatto
                    if [[ -f ${batchctrl} && "${batchctrl}" != "${tmpbatchctrl}" ]] ; then
                        cp ${batchctrl} ${tmpbatchctrl}
                    fi
                fi
                if [[ -f ${tmpbatch}.bed ]] ; then
                    echo "${tmpbatch}" >> ${tmpbatchfile}
                fi
            done
            if [[ -s ${tmpbatchfile} ]] ; then
                mv ${tmpbatchfile} ${mybatchfile}
            elif [[ -f ${tmpbatchfile} ]] ; then
                rm ${tmpbatchfile}
            fi
            if (( ${#mybatchvec[*]} > 1 )) ; then
                misfile=${outprefix}.missnp
                mischrfile=${outprefix}.mischr
                plink --merge-list ${mybatchfile} --out ${outprefix}
                if [[ -f ${outprefix}.bim ]] ; then
                    perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
                fi
                if [[ -f ${outprefix}.fam ]] ; then
                    perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
                fi
                grep "^Warning: Multiple chromosomes seen for variant" ${outprefix}.log | cut -d ' ' -f 7 \
                | sed -r 's/['\''.]//g;' | sort -u >> ${mischrfile}
                if [[ -s ${mischrfile} ]] ; then
                    sort -u ${mischrfile} >> ${misfile}
                fi
                if [[ -f ${misfile} ]] ; then
                    mv ${misfile} ${excludefile}
                    goflag=""
                fi
            else
                plink --bfile $( cat ${mybatchfile} ) --make-bed --out ${outprefix}
                if [[ -f ${outprefix}.bim ]] ; then
                    perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
                fi
                if [[ -f ${outprefix}.fam ]] ; then
                    perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
                fi
            fi
        done
    fi
    myprefix=${outprefix}

    excludeopt=""
    if [[ "${blacklist}" != "" ]] ; then
        excludeopt="--exclude range ${blacklist}"
    fi
    hqprefix=${myprefix}_hq
    hqprefixunique=${hqprefix}_unique
    cleanfile=${hqprefix}.clean.id
    uniquefile=${hqprefixunique}.rel.id
    pruneprefix=${hqprefix}_LDpruned
    if [[ ! -f ${pruneprefix}.bed || ! -f ${pruneprefix}.bim || ! -f ${pruneprefix}.fam ]] ; then
        plink --bfile ${myprefix} ${excludeopt} --geno ${varmiss} --maf ${myfreq_hq} \
            --hwe 1.E-${hweneglogp} midp include-nonctrl --make-bed --out ${hqprefix}
        plink --bfile ${hqprefix} --indep-pairphase 500 5 0.2 --out ${hqprefix}_LD
        plink --bfile ${hqprefix} --extract ${hqprefix}_LD.prune.in --make-bed --out ${pruneprefix}
    fi
    usex=''
    checkprefix=${pruneprefix}
    parcount=$( awk '$1 == 25' ${checkprefix}.bim | wc -l )
    if (( parcount == 0 )) ; then
        plink --bfile ${pruneprefix} --split-x ${genome} no-fail --make-bed --out ${pruneprefix}_splitx
        checkprefix=${pruneprefix}_splitx
    fi
    xcount=$( awk '$1 == 23' ${checkprefix}.bim | wc -l )
    if (( xcount > 100 )) ; then
        plink --bfile ${checkprefix} --impute-sex --make-bed --out ${pruneprefix}_isex
        if [[ -s ${pruneprefix}_isex.fam ]] ; then usex="--update-sex ${pruneprefix}_isex.fam 3" ; fi
    fi
    echo "checking sample quality.."
    if [[ ! -s "${uniquefile}" ]] ; then
        cp ${pruneprefix}.fam ${cleanfile}
        if [[ "${hvm}" == "on" ]] ; then
            echo "computing individual heterozygosity and missing rates.."
            plink --bfile ${pruneprefix} --het --out ${hqprefix}_sq
            plink --bfile ${pruneprefix} --missing --out ${hqprefix}_sq
            ${hvmscript} -m ${hqprefix}_sq.imiss -h ${hqprefix}_sq.het -o ${hqprefix}
        fi
        if [[ -s "${cleanfile}" ]] ; then
            echo "identifying duplicate individuals.."
            if [[ "${keepdups}" == "on" ]] ; then pihat=1 ; fi
            plink --bfile ${pruneprefix} --keep ${cleanfile} --genome gz --out ${myprefix}
            plink --bfile ${pruneprefix} --keep ${cleanfile} --cluster --read-genome ${myprefix}.genome.gz \
                --rel-cutoff ${pihat} --out ${hqprefixunique}
        fi
    fi
    if [[ -s "${uniquefile}" ]] ; then
        outprefix=${myprefix}_clean
        if [[ ! -f ${outprefix}.bed || ! -f ${outprefix}.bim || ! -f ${outprefix}.fam ]] ; then
            plink --bfile ${myprefix} --keep ${uniquefile} --make-bed --out ${outprefix}
            if [[ -f ${outprefix}.bim ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
            fi
            if [[ -f ${outprefix}.fam ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
            fi
        fi
        myprefix=${outprefix}
    fi

    outprefix=${myprefix}_varQC
    if [[ ! -f ${outprefix}.bed || ! -f ${outprefix}.bim || ! -f ${outprefix}.fam ]] ; then
        plinkcmd='plink'
        tmpvarmiss=${varmiss}
        N=$( wc -l ${myprefix}.fam | cut -d ' ' -f 1 )
        if (( N < 100 )) ; then tmpvarmiss=0.1 ; fi
        hweneglogp_sex=$(( hweneglogp*2 ))
        if (( hweneglogp_sex > 12 )) ; then hweneglogp_sex=12 ; fi
        plink --bfile ${myprefix} --not-chr 23,24 --geno ${tmpvarmiss} --maf ${myfreq_std} \
            --hwe 1.E-${hweneglogp} midp include-nonctrl --make-bed --out ${outprefix}_nonsex
        if [[ -s ${outprefix}_nonsex.bed && -s ${outprefix}_nonsex.bim && -s ${outprefix}_nonsex.fam ]] ; then
            plinkcmd="${plinkcmd} --bfile ${outprefix}_nonsex"
        fi
        plink --bfile ${myprefix} --chr 23,24 --geno ${tmpvarmiss} --maf ${myfreq_std} \
            --hwe 1.E-${hweneglogp_sex} midp include-nonctrl --make-bed --out ${outprefix}_sex
        if [[ -s ${outprefix}_sex.bed && -s ${outprefix}_sex.bim && -s ${outprefix}_sex.fam ]] ; then
            plinkcmd="${plinkcmd} --bmerge ${outprefix}_sex"
        fi
        ${plinkcmd} --make-bed --out ${outprefix}
        if [[ -f ${outprefix}.bim ]] ; then
            perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
        fi
        if [[ -f ${outprefix}.fam ]] ; then
            perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
        fi
    fi
    myprefix=${outprefix}

    outprefix=${myprefix}_sampleQC
    if [[ ! -f ${outprefix}.bed || ! -f ${outprefix}.bim || ! -f ${outprefix}.fam ]] ; then
        tmpsamplemiss=${samplemiss}
        N=$( wc -l ${myprefix}.bim | cut -d ' ' -f 1 )
        if (( N < 100 )) ; then tmpsamplemiss=0.1 ; fi
        plink --bfile ${myprefix} --mind ${tmpsamplemiss} ${usex} --make-bed --out ${outprefix}
        if [[ -f ${outprefix}.bim ]] ; then
            perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
        fi
        if [[ -f ${outprefix}.fam ]] ; then
            perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
        fi
    fi
    myprefix=${outprefix}

    if [[ "${phenotypes}" != "" && -f "${phenotypes}" ]] ; then
        outprefix=${myprefix}_pheno
        if [[ ! -f ${outprefix}.bed || ! -f ${outprefix}.bim || ! -f ${outprefix}.fam ]] ; then
            plink --bfile ${myprefix} --make-pheno ${phenotypes} affected --make-bed \
                --out ${outprefix}
            if [[ -f ${outprefix}.bim ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
            fi
            if [[ -f ${outprefix}.fam ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
            fi
        fi
        myprefix=${outprefix}
        outprefix=${myprefix}_hwe_ctrl
        if [[ ! -f ${outprefix}.bed || ! -f ${outprefix}.bim || ! -f ${outprefix}.fam ]] ; then
            hweneglogp_ctrl_sex=$(( hweneglogp_ctrl/2 ))
            if (( hweneglogp_ctrl_sex < 12 )) ; then hweneglogp_ctrl_sex=12 ; fi
            plink --bfile ${myprefix} --not-chr 23,24 --hwe 1.E-${hweneglogp_ctrl} --make-bed \
                --out ${outprefix}_nonsex
            plink --bfile ${myprefix} --chr 23,24 --hwe 1.E-${hweneglogp_ctrl_sex} --make-bed \
                --out ${outprefix}_sex
            plink --bfile ${outprefix}_nonsex --bmerge ${outprefix}_sex --out ${outprefix}
            if [[ -f ${outprefix}.bim ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
            fi
            if [[ -f ${outprefix}.fam ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
            fi
        fi
        myprefix=${outprefix}
        mycontrols=${mydir}/$( basename ${phenotypes} .txt )_ctrl.txt
        mycontrols_with_batch=${mydir}/$( basename ${phenotypes} .txt )_ctrl.batch
        awk -F $'\t' '{ if ( tolower($3) == "control" ) print; }' ${phenotypes} > ${mycontrols}
    else
        mycontrols=${myprefix}_ctrl.txt
        mycontrols_with_batch=${myprefix}_ctrl.batch
        cut -f 1,2,6 ${myprefix}.fam | tabspace > ${mycontrols}
    fi

    if (( ${#mybatchvec[*]} > 1 )) ; then
        tmpfile=$( mktemp .tmpbcXXXXX )
        echo "created temporary batch control file ${tmpfile}."
        echo -n > ${mycontrols_with_batch}
        for batch in $( cat ${mybatchfile} ) ; do
            tmpbatch=${mydir}/$( basename ${batch} )_ctrl
            plink --bfile ${batch} --keep ${mycontrols} --make-bed --out ${tmpbatch}
            if [[ -f ${tmpbatch}.bim && -f ${tmpbatch}.fam ]] ; then
                perl -p -i -e 's/[ \t]+/\t/g' ${tmpbatch}.bim ${tmpbatch}.fam
                awk -F $'\t' -v batch=$( basename ${batch} ) '{ OFS="\t"; print( $1, $2, batch ) }' \
                    ${tmpbatch}.fam >> ${mycontrols_with_batch}
            fi
        done
        sort -u -k 1,2 ${mycontrols_with_batch} > ${tmpfile}
        mv ${tmpfile} ${mycontrols_with_batch}
        tmpfile=$( mktemp .tmpmodXXXXX )
        echo "created temporary model file ${tmpfile}."
        bevarfile=${myprefix}.exclude
        echo -n > ${bevarfile}
        for bbatch in $( cat ${mybatchfile} ) ; do
            batch=$( basename ${bbatch} )
            echo "assessing batch effects for '${batch}'.."
            plinkfile=${mydir}/plink_${batch}
            plink --bfile ${myprefix} --make-pheno ${mycontrols_with_batch} ${batch} --model \
                --out ${plinkfile}
            if [[ -f "${plinkfile}.model" ]] ; then
                perl -p -e 's/^[ \t]+//g;' ${plinkfile}.model | tabspace > ${tmpfile}
                mv ${tmpfile} ${plinkfile}.model
                for atest in $( cut -f 5 ${plinkfile}.model | tail -n +2 | sort -u ) ; do
                    echo "summarizing ${atest} tests.."
                    awk -F $'\t' -v atest=${atest} '$5 == atest' ${plinkfile}.model | cut -f 2,10 \
                    | fdr.Rscript > ${tmpfile}
                    awk -F $'\t' '{ if ( $2 < 0.9 ) print( $1 ); }' ${tmpfile} >> ${bevarfile}
                done
            fi
        done
        sort -u ${bevarfile} > ${tmpfile}
        mv ${tmpfile} ${bevarfile}
        outprefix=${myprefix}_nbe
        plink --bfile ${myprefix} --exclude ${bevarfile} --make-bed --out ${outprefix}
        if [[ -f ${outprefix}.bim ]] ; then
            perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.bim
        fi
        if [[ -f ${outprefix}.fam ]] ; then
            perl -p -i -e 's/[ \t]+/\t/g' ${outprefix}.fam
        fi
    fi

    if [[ -f ${outprefix}.fam ]] ; then
        cp ${outprefix}.fam ${outprefix}.fam.org
        awk '{ OFS="\t"; for ( k = 1; k < 5; k++ ) gsub( "[/+-]", "_", $k ); print; }' ${outprefix}.fam.org \
        > ${outprefix}.fam
    fi

    hqprefix=${outprefix}_hq
    plink --bfile ${outprefix} ${excludeopt} --maf ${myfreq_hq} --make-bed --out ${hqprefix}
    plink --bfile ${hqprefix} --indep-pairphase 500 5 0.2 --out ${hqprefix}_LD
    plink --bfile ${hqprefix} --extract ${hqprefix}_LD.prune.in --make-bed --out ${hqprefix}_LDpruned
    plink --bfile ${hqprefix}_LDpruned --genome gz --out ${hqprefix}
    plink --bfile ${hqprefix}_LDpruned --cluster --read-genome ${hqprefix}.genome.gz --pca header tabs var-wts \
        --out ${hqprefix}

    echo -e "\nall done. check your output files out."
    echo -e "\n================================================================================\n"

fi
