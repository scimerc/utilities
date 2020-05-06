#!/bin/bash
# list the headers on a tab separated file

head -n1 $1 | sed 's/\t/\n/g' | cat -n

