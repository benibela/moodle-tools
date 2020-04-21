#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

export hidetext=$1
if [[ -z "$hidetext" ]]; then echo need activity name to hide as argument; exit; fi

moodlewithcourse --variable hidetext  "https://moodle.uni-luebeck.de/course/view.php?id={$course}" \
   -f 'form((//form)[1], "edit=on")' \
   -f  'css("div.activityinstance")[contains((span,.)/a/@href, "view.php") and exists(.//text()/normalize-space()[contains(., $hidetext)]) ]/..//a[matches(@href, "mod[.]php.*hide")]' \
   -e //title
#   -e  'css("div.activityinstance")[contains(a/@href, "view.php") and .//text()/normalize-space()[contains(., $hidetext)]]/..//a[matches(@href, "mod[.]php.*hide")]'
 
 
