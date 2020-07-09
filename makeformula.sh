#!/bin/bash
# Create a grading formula for a course. Condition: pass if at most two exercise assignments were failed.
# Input as environment variable
#   course

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

#https://moodle.uni-luebeck.de/mod/assign/view.php?id=112210
#https://moodle.uni-luebeck.de/course/modedit.php?update=112210&return=1

moodlewithcourse 'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
  -f 'moodle:course-edit-follow(/)' \
  -f '//a[contains(@href, "mod/assign/view")]/replace(@href, "mod/assign/view.php[?]id=", "course/modedit.php?update=")'  \
   --xquery 'let $p := x:request-decode(form(//form[contains(@action, "modedit")])).params
             let $id := ($p("cmidnumber")[.], "MISSING ID")[1]
             where $p("visible") ne "0" and not(contains($id, "Klausur")) and not (matches($p("name"), "Klausurtermin|Einreichung Ihres Codes"))
             let $maxpoints := $p("grade[modgrade_point]")
             let $okpoints := $p("gradepass")
             return
               x" min(floor([[{$id}]] / {$okpoints}); 1) " 
' | $xidel - --xquery '
  let $lines := x:lines($raw)[contains(., "min")]   
  let $allowedtofail := 2
  return ( x"=min( {join($lines, "+")} - {count($lines) - $allowedtofail - 2} ; 2) ",
  x"
  
  Anzahl an relevanten Blättern: {count($lines)}
  Einfluss der Anzahl in der Formel: {count($lines)} - {$allowedtofail} - 2 ; 2))")
'

