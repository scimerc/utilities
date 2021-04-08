#!/bin/bash
# script for submitting a generic job to slurm
basedir="/cluster/projects/p33"
opt_parser="${basedir}/software/lib/sh/opt_parser.sh"
opt_list=("-name=" "-cmemo=" "-ctime=" "-sdep=" "-sdir=" "-skeep" "-smod=" "-sout=")
get_opt ()
{
  case $1 in
    "-name" )
      jobname=`echo "$2" | sed "s/^=\+//"` ;;
    "-cmemo" )
      cpumemo=`echo "$2" | sed "s/^=\+//"` ;;
    "-ctime" )
      cputime=`echo "$2" | sed "s/^=\+//"` ;;
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
  esac
}
cpumemo="8GB"
cputime="0-05:00:00"
jobname="slurmjob"
keeptmp=0
outprefix="out"
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
  echo -e "   --cmemo <memory>        memory requirement (use MB,GB,etc.) [default: 8GB]"
  echo -e "   --ctime <time>          time requirement (format [D-]HH:MM:SS) [default: 05:00:00]"
  echo -e "   --sdep <dependencies>   comma separated list of dependencies: files to be copied to"
  echo -e "                           the cluster. NOTE: all files mentioned in PROGRAM are copied"
  echo -e "                           by default; use this option only if your job implicitly"
  echo -e "                           requires other files that are not directly accessible from"
  echo -e "                           the cluster."
  echo -e "   --sdir <directory>      result directory; must be in '/cluster/projects/p33'"
  echo -e "                           [default: current directory]"
  echo -e "   --skeep                 keep temporary script [deleted by default]"
  echo -e "   --smod <modules>        comma separated list of modules to load [default: none]"
  echo -e "   --sout <output prefix>  output prefix [default: 'out']"
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

if [[ "${tmpdir}" != "$( readlink -f ${basedir} )"* ]] ; then

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
    escomm[$k]=${scomm[$k]#/}
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

echo "#SBATCH --account=p33" >> ${tmpscript}
echo "#SBATCH --job-name=${jobname}" >> ${tmpscript}
echo "#SBATCH --mem-per-cpu=${cpumemo}" >> ${tmpscript}
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
  escomm[0]="${SCRATCH}/${myprogname}"
fi

# copy everything that exists
for k in $( seq ${#slist[@]} ) ; do
  if [[ -f "${slist[$k]}" ]] ; then
    echo "copying '${slist[$k]}'.."
    slist[$k]=$( readlink -e ${slist[$k]} )
    sdir='${SCRATCH}'/$( dirname ${slist[$k]} )
    echo mkdir -v -p ${sdir} >> ${tmpscript}
    echo cp -v -r ${slist[$k]} ${sdir}/ >> ${tmpscript}
  fi
done

echo chkfile \"'${SCRATCH}'/${outprefix}*\" >> ${tmpscript}

echo cd '${SCRATCH}' >> ${tmpscript}
echo ls -la >> ${tmpscript}
echo ${escomm[@]} >> ${tmpscript}
echo >> ${tmpscript}

sbatch -D ${tmpdir} ${tmpscript}
if [ "${keeptmp}" -eq 0 ] ; then
  rm ${tmpscript}
fi

