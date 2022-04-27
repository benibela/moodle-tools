#!/bin/bash
#Sets the grade of a list of students
#Input:
#  $course
#  $1       -> itemid from url
#  $2       -> grade
#  stdin    -> list of students (name or id=1234)

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$1" ]]; then echo need itemid as \$1; exit; fi
export defaultgrade="$2"

moodlewithcourse --variable defaultgrade \
   - -e 'allstudents := x:lines($raw)!normalize-space()[.], $affectedstudents := ()' \
   $baseurl'/grade/report/singleview/index.php?id='$course'&group&itemid='$1'&item=grade&page=0' \
   -f 'css(".pagination .page-item a")/@href => distinct-values()' \
   -e '
   <div class="reporttable"><div class="selectitems"></div>
     <form method="POST">
       <input type="submit" value="Speichern">{$params:=.}</input>
       <tbody>
         <tr>{
           let $grade := $defaultgrade
           let $name := th[1]!normalize-space()
           let $id := th[1]//a/@href => extract("user/view.*(id=[0-9]+)", 1)
           where ($name, $id) = $allstudents
           return (
             $params[] := {.//select/@name: .//select/option[. = $grade]/@value},
             $affectedstudents[] := $name
           )
         }</tr>+
       </tbody>
       {request := form(., $params)}
     </form>
   </div>
   ' \
   -f '$request' \
   -e '"Affected students: ",$affectedstudents'

exit
  
moodlewithcourse --variable defaultgrade \

   $baseurl'/grade/report/singleview/index.php?id='$course'&group&itemid='$1'&item=grade&page=0' \
   - \
   -e '
      let $allstudents := $allstudents
      return $allstudents ! x"{.}:{$defaultgrade}"
   '

