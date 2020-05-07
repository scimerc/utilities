#!/bin/bash
function job_monitor () {
    myflag=0
    goodstatus="CD CF CG PD R"
    tmpfile=''
    while [[ "${tmpfile}" == "" ]] ; do
        tmpfile=$( mktemp .tmpXXXXX 2> /dev/null )
    done
    for jobid in $* ; do
        mystatus=""
        declare squeue_status=1
        while [[ "${squeue_status}" != "0" ]] ; do
            sleep 1
            squeue > ${tmpfile}
            squeue_status=$?
            mystatus=$( cat ${tmpfile} | sed -r 's/[ \t]+/\t/g;' | sed -r 's/^[ \t]+//g;' \
                | awk -F $'\t' -v jobid=${jobid} '$1 == jobid' | cut -f 5 )
        done
        if [ "${mystatus}" != "" ] ; then
            for jobstatus in ${goodstatus} ; do
                if [ "${mystatus}" == "${jobstatus}" ] ; then
                    myflag=1
                fi
            done
            if [ "${myflag}" != "1" ] ; then
                myflag=2
            fi
        fi
    done
    rm -f ${tmpfile}
    echo ${myflag}
}

export job_monitor

