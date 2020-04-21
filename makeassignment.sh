#!/bin/bash
#Input:
#  environment variables:
#     course
#     section
#  stdin:
#     parameters
#     (see modifyassignment)

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$course" ]]; then echo need course; exit; fi

(cat; echo; echo "$baseurl/course/modedit.php?add=assign&type=&course=$course&section=$section&return=0&sr=0") | $DIR/modifyassignment.sh