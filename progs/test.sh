#!/usr/bin/env bash

Rscript

{ R --version 2> /dev/null || { echo 'R is not installed. aborting..'; exit 1; }; }

R --slave --file=/cluster/projects/p33/groups/biostat/software/progs/test.Rscript

