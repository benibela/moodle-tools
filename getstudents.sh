#!/bin/bash
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR=~/moodle
source $DIR/common.sh

if [[ -z "$course" ]]; then echo need course; exit; fi
export course


~/xidel --variable user,pass,course --extract-exclude=students,studentids \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   'https://moodle.uni-luebeck.de/user/index.php?id={$course}&perpage=5000' \
   -e 'students := (), studentids := ()' \
   -e '<table id="participants"><tr><td><strong>{$studentids[] := extract(a/@href,"id=([0-9]+)",1), $students[] := normalize-space(.)}</strong></td></tr>+</table>'\
   --xquery 'for $s at $i in $studentids return $s|| " "||$students[$i]'
