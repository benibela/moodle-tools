#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

export from=$1
export to=$2

if [[ -z "$from" ]] || [[ -z "$to" ]]; then echo need two arguments: from to; exit; fi



moodlewithcourse --variable hidetext,from,to  "$baseurl/course/view.php?id={$course}" \
   -f 'form((//form)[1], "edit=on")' \
   -e  'sesskey:=(//input[@name="sesskey"]/@value)[1]' \
   -f ' ($from to $to) !  x"{$baseurl}/course/view.php?id={$course}&sesskey={$sesskey}&show={.}" ' \
   -e //title
 
 
