myfile="$1" ; shift
allfile=$( mktemp .tmpXXXXXXX )
tmpfileA=$( mktemp .tmpXXXXXXX )
tmpfileB=$( mktemp .tmpXXXXXXX )
for pfile in $* ; do
    echo -n "${pfile}   "
    sort -u -k 1,1 "${pfile}" | join - "${myfile}" > ${tmpfileA}
    sort -u -k 1,1 "${allfile}" | join -v1 ${tmpfileA} - | tee ${tmpfileB} | wc -l | tabspace
    cat ${tmpfileB} >> "${allfile}"
done
rm $allfile
rm $tmpfileA
rm $tmpfileB
