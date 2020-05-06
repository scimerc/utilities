#!/usr/bin/env bash

# Find all files with suffix ".ln.txt" and convert them to links.
# This way, any links to external files will be documented in git. 
# Also generate "*.ln.info" linked file conainting so any changes
# in size, permission, modification time,.. are also visible in git.

trap 'exit' ERR

# [ ! -z "$NDROOT" ] || { printf "error at %d\n" $LINENO >&2; exit 1; }

# allow path as arg
if [ ! -z "$1" ]; then
  cd "$1"
fi

#------------------------------------------------------------------------------

getStats() {
  local -r path="$1"
  printf        "file type:     %s\n" "$(file -b "$path")"
  stat --printf="size:          %s\n" "$path"
  stat --printf="user:          %U\n" "$path"
  stat --printf="group:         %G\n" "$path"
  stat --printf="changed:       %z\n" "$path"
  stat --printf="modified:      %y\n" "$path"
  stat --printf="access_rights: %A (%a)\n" "$path"
  if [ -f "$path" ]; then
    printf "md5sum: %s \n" $(md5sum "$path" | awk '{print $1}')
    local -r num_bytes=256
    printf "\nfirst %d bytes:\n" $num_bytes
    head -c $num_bytes "$path" | xxd
    printf "\nlast %d bytes:\n" $num_bytes
    tail -c $num_bytes "$path" | xxd
  fi
}

#------------------------------------------------------------------------------

printf "searching for link-files...\n"
# array with all "*.ln.txt" files
declare -ra LINKS=($(find -P . -name "*.ln.txt"))
printf "... found %s link-files\n" ${#LINKS[@]}

ERRCOUNT=0
for l in ${LINKS[@]}; do
  LINKFN=$(basename $l)
  LINKDIR=${l%/*}
  LINKBASE="${LINKFN%%.ln.txt}"
  echo "clearing tree.."
  rm -vrf "${LINKBASE}"
  pushd "$LINKDIR" > /dev/null
  LSRC="$(head -n 1 $LINKFN)"
  if [ ! -e "$LSRC" ];then
    printf "error: %s does not exist\n" "$LSRC" >&2
    ERRCOUNT=$((ERRCOUNT+1))
  fi
  LSRCW=${LSRC}
  if [ -d "${LSRC}" ] ; then
    LSRCW="$(cd ${LSRC} && find . -type f)"
    echo "${LSRCW}" | while read LSRCWI ; do
        mkdir -p "${LINKBASE}/${LSRCWI%/*}"
        # write ".info" file from src
        echo "$LSRCWI" '>' "${LINKBASE}/${LSRCWI}.ln.info"
        getStats "${LSRC}/$LSRCWI" > "${LINKBASE}/${LSRCWI}.ln.info"
    done 
  else
      # write ".info" file from src
      echo "$LSRCW" '>' ${LINKFN%%.ln.txt}.ln.info
      getStats "$LSRCW" > ${LINKFN%%.ln.txt}.ln.info
  fi
  popd > /dev/null
done

if [ $ERRCOUNT -gt 0 ]; then
  printf "found %d errors\n" $ERRCOUNT
fi
printf "ok\n"

