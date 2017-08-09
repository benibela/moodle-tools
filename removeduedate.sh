#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"


if [[ -z "$exercise" ]]; then 
  echo No exercise given, use course
  if [[ -z "$course" ]]; then echo No course given; exit; fi
  exercise=$(moodle https://moodle.uni-luebeck.de/course/view.php?id={$course} -e 'join(//a[matches(@href, "assign/|vpl/")]/@href/extract(., "id=([0-9]+)", 1), ",")')
  echo Found exercises: $exercise
fi

export exercise

moodle --variable exercise "<x/>" -f 'tokenize($exercise, ",") ! x"https://moodle.uni-luebeck.de/course/modedit.php?update={.}"' -f 'form(//form, {"duedate[enabled]": "0"})' -e '()'

