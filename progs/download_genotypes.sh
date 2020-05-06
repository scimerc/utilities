#!/bin/tcsh
set snps_map = "snps.map"
set snps_list = ""
set drop_pns = ".drop.pns"
set drop_plates = ".drop.plates"
set flags = ( "drop=" "map=" "q" "v" "h" )
echo -n "" > ${drop_plates} # reset the list of plates to be dropped
while ( "${argv}" != "" )
  if ( ${?compositeflag} ) then
    set argcomp = `echo "$1" | sed "s/^-${compositeflag}//"`
    if ( "${argcomp}" != "" ) then
      set carg = ${argcomp}
    else
      shift
      set carg = $1
    endif
    set buffer = `echo "${carg}" | grep -e '^=\+$'`
    if ( "${buffer}" != "" ) then
      shift
      set carg = $1
    endif
    switch ( ${compositeflag} )
      case "drop":
        set badplate = `echo ${carg} | sed "s/^=\+//"`
        echo "^${badplate} " >> ${drop_plates}
        breaksw
      case "map":
        set snps_map = `echo ${carg} | sed "s/^=\+//"`
        breaksw
      default:
        echo "invalid option '-${compositeflag}'"
        breaksw
    endsw
    shift
    unset compositeflag
  else if ( ${?simpleflag} ) then
    switch ( ${simpleflag} )
      case "q":
        echo "howdy!"
        breaksw
      case "v":
        echo "verbose mode on"
        breaksw
      case "h":
        set helpme = 1
        breaksw
      default:
        echo "invalid option '-${simpleflag}'"
        breaksw
    endsw
    shift
    unset simpleflag
  else
    set argflag = `echo "${argv}" | grep -e "^-"`
    if ( "${argflag}" != "" ) then
      if ( ${?validflag} ) then
        unset validflag
      endif
      # found a flag argument
      foreach cflag ( ${flags} )
        # remove the '=' sign from the composite flags
        set eflag = `echo ${cflag} | sed "s/=//g"`
        # look for cflag at the beginning of the current argument list substring
        set fcheck = `echo "${argv}" | grep -e "^-${eflag}"`
        if ( "${fcheck}" != "" ) then
          set validflag = ${cflag}
          if ( "${eflag}" == "${cflag}" ) then
            # cflag is a simple flag
            set simpleflag = ${eflag}
          else
            # cflag is a composite flag
            set compositeflag = ${eflag}
          endif
        endif
      end
      if ( ! ${?validflag} ) then
        echo -n "invalid argument: "
        echo "${argflag}" | sed "s/\([^ ]\+\) .\+/\1/"
        shift
      endif
    else
      set snps_list = "${snps_list}$1 "
      shift
    endif
  endif
end
foreach myfile ( ${snps_list} )
  set pathless_myfile = `echo ${myfile} | sed "s/.\+\///g"`
  if ( -fr ${myfile} ) then
    gtget -Smf ${myfile} | tab > gen_${pathless_myfile}.all.six
  else
    gtget -Sm ${myfile} | tab > gen_${pathless_myfile}.all.six
  endif
  gtpreprocess -keep-foreign gen_${pathless_myfile}.all.six
  egrep -v -f ${drop_plates} gen_${pathless_myfile}.all.six > gen_${pathless_myfile}.six
  six2four < gen_${pathless_myfile}.six > gen_${pathless_myfile}.four
  endif    
  if ( -efr ${snps_map} ) then
    sreplace ${snps_map} gen_${pathless_myfile}.four > gen_${pathless_myfile}.rs.four
    cat mismatches.upd.* low_yield_person.upd.* | cut -f 5 | sort -u > ${drop_pns}
  else
    echo "warning: snps map file '${snps_map}' not found."
  endif
end
if ( "${snps_list}" == "" ) then
  set helpme = 1
endif
if ( ${?helpme} ) then
  echo "\n you may have neglected to provide some input."
  echo "\n  usage:"
  echo "\n    download_genotypes.sh [options] <snp sg-(file|name)(s)>"
  echo "\n  options:"
  echo "      -map <mapfile>           snp map file;"
  echo "      -drop[=| ]<badplate>     mark a plate to be discarded."
  echo ""
endif
