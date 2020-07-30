#!/bin/bash
#Print the results of a choice activity, sorted by first name (results in the moodle are unsorted)
#Input:
#  $1       -> Id
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

moodle 'https://moodle.uni-luebeck.de/mod/choice/report.php?id='$1 --xquery '
  let $sort := sort#1
  let $table := css("table.results")  
  let $options := $table/thead//th => tail()
  let $answers := $table/css("tbody tr.lastrow")
  for $option at $i in $options
  let $a := $answers/td[$i]//a
  return ($option, "===============================================",$sort($a),"","","")
  '

