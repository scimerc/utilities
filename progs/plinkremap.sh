#!/usr/bin/env bash
# convert plink files to a new build

# exit on error
set -Eeou pipefail

declare opt_outprefix_def='plinkremap'
declare opt_outprefix=${opt_outprefix_def}
declare opt_refmap=''
usage() {
cat << EOF
USAGE: $( basename $0 ) -r <refmap> [-o <output(="${opt_outprefix_def}")>] <plink bed file>
EOF
}
while getopts "r:o:" opt; do
case "${opt}" in
  o)
    opt_outprefix="${OPTARG}"
    ;;
  r)
    opt_refmap="${OPTARG}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
done
shift $((OPTIND-1))
if [ "${opt_refmap}" == "" ] ; then
  echo 'no map specified.'
  usage
  exit 0
fi
if [ -z "${1+x}" -o ! -s "$1" ] ; then
  echo 'no valid input specified.'
  usage
  exit 1
fi
declare bfile="$1"
tmpprefix=${opt_outprefix}_tmp
liftOver <( awk '{ OFS="\t"; print( $1, $4-1, $4, $2 ); }' ${bfile%.bed}.bim ) \
  ${opt_refmap} \
  ${tmpprefix}.remap \
  /dev/stdout \
  | grep -v '^#' \
  | cut -f 4 \
  | sort -u \
  > ${tmpprefix}.unmapped
plink --allow-extra-chr --bfile ${bfile%.bed} \
      --exclude ${tmpprefix}.unmapped \
      --update-chr ${tmpprefix}.remap 1 4 \
      --update-map ${tmpprefix}.remap 3 4 \
      --make-bed --out ${tmpprefix}.remap
mv ${tmpprefix}.remap.bed ${opt_outprefix}.bed
mv ${tmpprefix}.remap.bim ${opt_outprefix}.bim
mv ${tmpprefix}.remap.fam ${opt_outprefix}.fam
rm ${tmpprefix}*

