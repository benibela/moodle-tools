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
   -e 'xquery version "3.0-xidel";
       import module namespace utils="studenttopics" at "topiclib.xqm", "'$DIR/autograding/'topiclib.xqm";
      
      let $students-expected := $utils:students-normal(1),
          $students-missing := (for $s in $students-expected[not(. = $students)] order by $s return $s),
          $students-additional := $students[not(. = $students-expected)]
      return (
      "Missing students:",
      $students-missing,
      if (exists($students-missing)) then (
      " ",
      "Additional students:",
      $students-additional,
      "","",
      "Closest matches (list<->moodle):",
      $students-missing!(. || "<->"||(for $s in $students-additional order by utils:simple-name-sim($s,.) ascending return $s)[1])
      )else(),
      file:write-text-lines("studentmapping", for $i in 1 to count($studentids) return x"{$studentids[$i]} {$students[$i]}")
      )
   ' 