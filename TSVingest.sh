#!/bin/bash

line_1=$(head -n 1 $1)

#Modifies tsv in place to include SRA wih 'Run" as header
if [[ "$line_1" != *"Run"* ]]
then 
    file_prefix=${1%%.*}
    sed -i '1s/$/\tRun/; 2,$s/$/\t'"$file_prefix"'/' $1
fi
