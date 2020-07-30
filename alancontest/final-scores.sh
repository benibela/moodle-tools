#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

moodlewithcourse 'https://moodle.uni-luebeck.de/course/view.php?id={$course}' -f 'moodle:course-edit-follow(/)' --xquery '
  let $winning-ranks := 2, 
      $scores := //p[starts-with(normalize-space(), "Die jeweils besten")]/../ ( 
        let $problem := h3[1], 
            $count := count(table//tr[1]/td), 
            $rows := table//tr[position()>1 and count(td) = $count] 
        for $row at $rank in $rows 
        let $speedup := $row/td[$count] 
        return {"problem": $problem, 
                "name": $row/td[1], 
                "speedup": $speedup, 
                "points": 1 + (if ($speedup >= 1) then 1 else 0) + (if ($rank <= $winning-ranks) then 1 else 0)} ) 
  return ($scores, 
          for $s in $scores group by $t:=$s/name order by $t 
          return $t || ":" || x:cps(9)  || sum($s/points) 
         ) '

