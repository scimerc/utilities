#!/usr/bin/env bash

# exit on error
set -ETeuo pipefail

declare -a joinfiles
joinfiles=( $( ls $@ 2>/dev/null ) )

print_awk_join_fields() {
  for k in ${!joinfiles[@]} ; do
    printf '{jf%d=%s}\n' ${k} 1
  done
}

[ ${#joinfiles[@]} -eq 0 ] && exit 0

awk -f <( print_awk_join_fields ) --source '
  BEGIN{
    FS=OFS="\t"
    findex=0
  } {
    if ( FNR == NR ) {
      joinfield = "jf"findex
      gcount[ $(joinfield) ] = 1
      if ( $(joinfield) in fcount ) {
        fcount[ $(joinfield) ]++
        catalog[ $(joinfield) ] = catalog[ $(joinfield) ] ORS $0
      }
      else {
        fcount[ $(joinfield) ] = 1
        catalog[ $(joinfield) ] = $0
      }
    }
    else {
      if ( FNR == 1 ) {
        findex++
        joinfield = "jf"findex
        delete fcount[ $(joinfield) ]
      }
      if ( $(joinfield) in catalog ) {
        mysep = OFS
        myrecord = ""
        if ( $(joinfield) in fcount ) mysep = ORS
        else gcount[ $(joinfield) ]++
        split( catalog[ $(joinfield) ], carr, ORS )
        for ( item in carr ) {
          if ( myrecord == "" ) myrecord = carr[item] mysep $0
          else myrecord = myrecord ORS carr[item] mysep $0
        }
        fcount[ $(joinfield) ] = 1
      }
    }
  } END{
    for ( item in catalog ) {
      if ( gcount[ item ] == findex+1 ) print( catalog[item] )
    }
  }
' ${joinfiles[@]}

