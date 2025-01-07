#!/bin/bash
# script for submitting a generic job to slurm
declare -r basedir="$( cd "$( dirname $0 )" && cd .. && pwd )"
opt_parser="${basedir}/lib/sh/opt_parser.sh"
opt_list=( \
  "-help" \
  "-name=" \
  "-cmemo=" \
  "-ctime=" \
  "-ncpus=" \
  "-sdep=" \
  "-sdir=" \
  "-skeep" \
  "-smod=" \
  "-sout=" \
  "-spart=" \
  "-squeue="
)
get_opt ()
{
  case $1 in
    "-help" )
      help=true ;;
    "-name" )
      jobname=`echo "$2" | sed "s/^=\+//"` ;;
    "-cmemo" )
      cpumemo=`echo "$2" | sed "s/^=\+//"` ;;
    "-ctime" )
      cputime=`echo "$2" | sed "s/^=\+//"` ;;
    "-ncpus" )
      ncpus=`echo "$2" | sed "s/^=\+//"` ;;
    "-sdep" )
      depend=`echo "$2" | sed "s/^=\+//"` ;;
    "-sdir" )
      resultdir=`echo "$2" | sed "s/^=\+//"` ;;
    "-skeep" )
      keeptmp=1 ;;
    "-smod" )
      smodules=`echo "$2" | sed "s/^=\+//"` ;;
    "-sout" )
      outprefix=`echo "$2" | sed "s/^=\+//"` ;;
    "-spart" )
      partitions=`echo "$2" | sed "s/^=\+//"` ;;
    "-squeue" )
      qname=`echo "$2" | sed "s/^=\+//"` ;;
  esac
}
cpumemo=""
cputime_def="00:15:00"
cputime="${cputime_def}"
depend=""
help=false
ncpus_def=1
ncpus="${ncpus_def}"
jobname="slurmjob"
keeptmp=0
outprefix="out"
partitions=""
qname_def="p22_tsd"
qname="${qname_def}"
resultdir=""
tmpargs=$( mktemp )
source ${opt_parser} > ${tmpargs}
scomm=( $( cat ${tmpargs} ) )
rm -f ${tmpargs}
n=${#scomm[@]}

if ${help} || [[ $n -eq 0 ]] ; then

  ${help} || echo "no program specified."

  echo -e "\n USAGE:"
  echo -e "   $(basename $0) [OPTIONS] PROGRAM"
  echo -e "\n OPTIONS:"
  echo -e "   --name <jobname>        name of the job [default: slurmjob]"
  echo -e "   --cmemo <memory>        ram (use MB,GB,etc.) per cpu [default: ${cpumemo_def}]"
  echo -e "   --ctime <time>          time (format [D-]HH:MM:SS) [default: ${cputime_def}]"
  echo -e "   --ncpus <n>             number of cpus to be used [default: ${ncpus_def}]"
  echo -e "   --sdep <dependencies>   comma-separated list of dependencies: files to be copied to"
  echo -e "                           the cluster."
  echo -e "                           NOTE: use this option only if your job implicitly requires"
  echo -e "                                 files that are not directly accessible from the"
  echo -e "                                 cluster; implicitly required files, e.g. within a"
  echo -e "                                 script, that *are* directly accessible from the cluster"
  echo -e "                                 must include the entire path in their name."
  echo -e "   --sdir <directory>      result directory [default: current directory]"
  echo -e "   --skeep                 keep temporary script [deleted by default]"
  echo -e "   --smod <modules>        comma-separated list of modules to load [default: none]"
  echo -e "   --sout <output prefix>  chkfile output prefix [default: 'out']"
  echo -e "   --spart <p0>,<p1>...    comma-separated list of viable partitions [default: none]"
  echo -e "   --squeue <name>         submit job for this account [default: ${qname_def}]"
  echo -e "                           NOTE: this option is currently disabled; use absolute paths"
  echo -e "                                 to ensure that the output files are written at the"
  echo -e "                                 right location"
  echo -e "\n WARNING:"
  echo -e "   if the PROGRAM string contains command line options like the ones $(basename $0)"
  echo -e "   uses, they will be interpreted by $(basename $0) and won't be available to PROGRAM."
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
    escomm[$k]=${scomm[$k]}
    echo "'${scomm[$k]}'."
  fi
done

slist=( ${scomm[@]} )
if [[ "${depend}" != "" ]] ; then
  k=0
  for dfile in $( echo ${depend} | tr ',' ' ' ) ; do
    if [[ -f "${dfile}" ]] ; then
      echo "parsing dependency '${dfile}'.."
      dependarr[$k]=$( readlink -e ${dfile} )
      k=$(( k + 1 ))
    fi
  done
  # merge the rest with the non explicit dependencies
  slist=( $( printf "%s\n" ${scomm[@]} ${dependarr[@]} | sort -u ) )
  echo -e "parsed dependencies:\n  ${slist[@]}"
fi

tmpscript=$( mktemp --tmpdir=${tmpdir} ".tmpsXXXXX.sh" )

echo "#!/bin/bash" > ${tmpscript}

echo "#SBATCH --account=${qname}" >> ${tmpscript}
echo "#SBATCH --job-name=${jobname}" >> ${tmpscript}
echo "#SBATCH --cpus-per-task=${ncpus}" >> ${tmpscript}
echo "#SBATCH --time=${cputime}" >> ${tmpscript}
if [[ "${cpumemo}" != "" ]] ; then
  echo "#SBATCH --mem-per-cpu=${cpumemo}" >> ${tmpscript}
fi
if [[ "${partitions}" != "" ]] ; then
  echo "#SBATCH --partition=${partitions}" >> ${tmpscript}
fi

echo "set -o errexit  # exit on errors" >> ${tmpscript}
echo "module --quiet purge  # clear any inherited modules" >> ${tmpscript}
if [[ "${smodules}" != "" ]] ; then
  for module in $( echo ${smodules} | tr ',' ' ' ) ; do
    echo "module load ${module}" >> ${tmpscript}
  done
fi
echo "module list  # list loaded modules" >> ${tmpscript}
echo echo >> ${tmpscript}

escomm[0]=$( readlink -f ${myprogpath} )

echo echo -e Job ID: '${SLURM_JOB_ID}'\n >> ${tmpscript}
echo cd '${SCRATCH}' >> ${tmpscript}
echo ls -la >> ${tmpscript}
echo echo >> ${tmpscript}
echo ${escomm[@]} >> ${tmpscript}
echo >> ${tmpscript}

sbatch -D ${tmpdir} ${tmpscript}
if [ "${keeptmp}" -eq 0 ] ; then
  rm ${tmpscript}
fi

