#!/bin/bash
# script for submitting a generic job to slurm
basedir="/cluster/projects/p33"
opt_parser="${basedir}/groups/biostat/software/lib/sh/opt_parser.sh"
opt_list=("-name=" "-cmemo=" "-ctime=" "-ncpus=" "-sdep=" "-sdir=" "-skeep" "-smod=" "-sout=" "-squeue=")
get_opt ()
{
  case $1 in
    "-name" )
      jobname=`echo "$2" | sed "s/^=\+//"` ;;
    "-ncpus" )
      ncpus=`echo "$2" | sed "s/^=\+//"` ;;
    "-cmemo" )
      cpumemo=`echo "$2" | sed "s/^=\+//"` ;;
    "-ctime" )
      cputime=`echo "$2" | sed "s/^=\+//"` ;;
    "-ncpus" )
      ncpus=`echo "$2" | sed "s/^=\+//"` ;;
    "-sdep" )
      sdepend=`echo "$2" | sed "s/^=\+//"` ;;
    "-sdir" )
      resultdir=`echo "$2" | sed "s/^=\+//"` ;;
    "-skeep" )
      keeptmp=1 ;;
    "-smod" )
      smodules=`echo "$2" | sed "s/^=\+//"` ;;
    "-sout" )
      outprefix=`echo "$2" | sed "s/^=\+//"` ;;
    "-squeue" )
      qname=`echo "$2" | sed "s/^=\+//"` ;;
  esac
}
cpumemo_def="100MB"
cpumemo="${cpumemo_def}"
cputime_def="00:15:00"
cputime="${cputime_def}"
ncpus_def=1
ncpus="${ncpus_def}"
jobname="slurmjob"
keeptmp=0
outprefix="out"
qname_def="p33"
qname="${qname_def}"
resultdir=""
sdepend=""
tmpargs=$( mktemp .tmpXXXXXXXX )
source ${opt_parser} > ${tmpargs}
scomm=( $( cat ${tmpargs} ) )
rm -f ${tmpargs}
n=${#scomm[@]}

if [ $n -eq 0 ] ; then

  echo "no program specified."

  echo -e "\n USAGE:"
  echo -e "   $(basename $0) [OPTIONS] PROGRAM"
  echo -e "\n OPTIONS:"
  echo -e "   --name <jobname>        name of the job [default: slurmjob]"
  echo -e "   --cmemo <memory>        ram (use MB,GB,etc.) [default: ${cpumemo_def}]"
  echo -e "   --ctime <time>          time (format [D-]HH:MM:SS) [default: ${cputime_def}]"
  echo -e "   --ncpus <n>             number of cpus to be used [default: ${ncpus_def}]"
  echo -e "   --sdep <dependencies>   comma separated list of dependencies: files to be copied to"
  echo -e "                           the cluster."
  echo -e "                           NOTE: all (existing) files entering the PROGRAM string are"
  echo -e "                                 copied by default; use this option only your job"
  echo -e "                                 implicitly requires other files that are not directly"
  echo -e "                                 accessible from the cluster; implicitly required"
  echo -e "                                 files, e.g. within a script, that *are* directly"
  echo -e "                                 accessible from the cluster must include the entire"
  echo -e "                                 path in their name."
  echo -e "   --sdir <directory>      result directory; must be in '/cluster/projects/p33'"
  echo -e "                           [default: current directory]"
  echo -e "   --skeep                 keep temporary script [deleted by default]"
  echo -e "   --smod <modules>        comma separated list of modules to load' [default: none]"
  echo -e "   --sout <output_prefix>  chkfile output prefix [default: 'out']"
  echo -e "                           NOTE: this option is currently disabled; use absolute paths"
  echo -e "                                 to ensure that the output files are written at the"
  echo -e "                                 right location"
  echo -e "   --squeue <queue_name>   submit job to the named queue [default: ${qname_def}]"
  echo -e "\n WARNING:"
  echo -e "   if the PROGRAM string contains command line options like the ones $(basename $0)"
  echo -e "   uses, they will interpreted by $(basename $0) and will not be available to PROGRAM."
  echo -e "   a work around in such cases is to wrap the original PROGRAM string into a script"
  echo -e "   and replace PROGRAM with a call to that script."
  echo

  exit 0

fi

currdir=$PWD
echo "current directory: '${currdir}'"
if [ -z "${resultdir}" ] ; then
  tmpdir=$( readlink -f ${currdir} )
elif [ -d "${resultdir}" ] ; then
  tmpdir=$( readlink -f ${resultdir} )
fi

if [[ "${tmpdir}" != "$( readlink -e ${basedir} )"* ]] ; then

  echo "invalid working directory '${tmpdir}'."
  echo "nothing done."
  exit 0

fi

mkdir -p ${tmpdir}

escomm=( ${scomm[@]} )
echo -e "parsed command:\n'${scomm[@]}'."
echo -e "submitting command:\n'${escomm[@]}'."
myprog=${scomm[0]} # the program name is first

# the program receives special treatment
myprogpath=$( which ${myprog} )
myprogname=$( basename ${myprog} )
if [ -z "${myprogpath}" ] ; then
  echo 'program not found.'
  exit 0
fi

# absolute paths for the rest
for k in $( seq $(( n - 1 )) ) ; do
  echo "parsing argument $k ['${scomm[$k]}'].."
  if [[ -f "${scomm[$k]}" ]] ; then
    echo -n "expanded '${scomm[$k]}' to "
    scomm[$k]=$( readlink -e ${scomm[$k]} )
    if [[ "$( readlink -e ${scomm[$k]} )" != "$( readlink -e ${basedir} )"* ]] ; then
      # remove eventual leading root '/' from path
      escomm[$k]=${scomm[$k]#/}
    else
      # use command word as is
      escomm[$k]=${scomm[$k]}
    fi
    echo "'${scomm[$k]}'."
  fi
done

slist=( ${scomm[@]} )
if [[ "${sdepend}" != "" ]] ; then
  k=0
  for dfile in $( echo ${sdepend} | tr ',' ' ' ) ; do
    if [[ -f "${dfile}" ]] ; then
      echo "parsing dependency '${dfile}'.."
      sdependarr[$k]=$( readlink -e ${dfile} )
      k=$(( k + 1 ))
    fi
  done
  # merge the rest with the non explicit dependencies
  slist=( $( printf "%s\n" ${scomm[@]} ${sdependarr[@]} | sort -u ) )
  echo -e "parsed dependencies:\n${slist[@]}"
fi

tmpscript=$( mktemp --tmpdir=${tmpdir} ".tmpsXXXXX.sh" )

echo "#!/bin/bash" > ${tmpscript}

echo "#SBATCH --account=${qname}" >> ${tmpscript}
echo "#SBATCH --job-name=${jobname}" >> ${tmpscript}
echo "#SBATCH --mem-per-cpu=${cpumemo}" >> ${tmpscript}
echo "#SBATCH --cpus-per-task=${ncpus}" >> ${tmpscript}
echo "#SBATCH --time=${cputime}" >> ${tmpscript}

echo "source /cluster/bin/jobsetup" >> ${tmpscript}
echo "set -o errexit # exit on errors" >> ${tmpscript}
echo "module purge # clear any inherited modules" >> ${tmpscript}
if [[ "${smodules}" != "" ]] ; then
  for module in $( echo ${smodules} | tr ',' ' ' ) ; do
    echo "module load ${module}" >> ${tmpscript}
  done
fi

escomm[0]=$( readlink -f ${myprogpath} )
if [[ "$( readlink -f ${myprogpath} )" != "$( readlink -f ${basedir} )"* ]] ; then
  cp -v $( readlink -f ${myprogpath} ) ${tmpdir}/
  echo cp -v ${myprogname} '${SCRATCH}'/ >> ${tmpscript}
  echo chmod u+x '${SCRATCH}'/${myprogname} >> ${tmpscript}
  escomm[0]='${SCRATCH}'/${myprogname}
fi

# copy everything that exists
for k in $( seq ${#slist[@]} ) ; do
  if [[ -f "${slist[$k]}" ]] ; then
    if [[ "$( readlink -f ${slist[$k]} )" != "$( readlink -f ${basedir} )"* ]] ; then
      echo "copying '${slist[$k]}'.."
      slist[$k]=$( readlink -e ${slist[$k]} )
      sdir='${SCRATCH}'/$( dirname ${slist[$k]} )
      echo mkdir -v -p ${sdir} >> ${tmpscript}
      echo cp -v -r ${slist[$k]} ${sdir}/ >> ${tmpscript}
    fi
  fi
done

# echo chkfile \"'${SCRATCH}'/${outprefix}*\" >> ${tmpscript}

echo cd '${SCRATCH}' >> ${tmpscript}
echo ls -la >> ${tmpscript}
echo ${escomm[@]} >> ${tmpscript}
echo >> ${tmpscript}

sbatch -D ${tmpdir} ${tmpscript}
if [ "${keeptmp}" -eq 0 ] ; then
  rm ${tmpscript}
fi

