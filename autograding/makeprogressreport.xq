xquery version "3.0-xidel";
import module namespace utils="studenttopics" at "topiclib.xqm";
declare variable $today := current-date();
declare variable $tasks := jn:parse-json(file:read-text("tasks.json"));
declare variable $tasks-done := for $r in ("paper", "presentation", $utils:review-file-names) return {$r: {| 
  for $line in file:read-text-lines("submissions/history" || $tasks($r))  
  let $split := tokenize($line, "§") 
  let $date := parse-date(tokenize($split[2], ",")[2], "d. mmmm yyyy")
  group by $name := normalize-space($split[1])
  return {$name: for $d in $date order by $d ascending return $d}
|}};
(: name, date :)
declare variable $tasks-done-met := {| for $l in file:read-text-lines("met")[.] let $x := tokenize($l, ",")!normalize-space() return {$x[1]: xs:date($x[2])} |};

declare function local:times($time){
  $time(1)
};
declare function local:timesFA($timeF,$timeA){
  let $colorF := extract($timeF(1), "cellcolor\{(.*)\}", 1)
  let $colorA := extract($timeA(1), "cellcolor\{(.*)\}", 1)
  return if ($colorF = $colorA) then $timeF(1)
  else if ($colorF = "red") then "Fol. " || replace( $timeF(1), "\{red\}", "{orange}")
  else if ($colorA = "red") then "Aus. " || replace( $timeA(1), "\{red\}", "{orange}")
  else $timeF(1)
};
declare function local:topic($topic){
  if (string-length($topic) < 27) then $topic
  else substring($topic, 1, 25) || ".."
};
declare function local:maketime($expected, $actual){
  if (exists($actual)) then 
    $expected || ": " || $actual || (if ($actual <= $expected) then "\cellcolor{green}" else "\cellcolor{yellow}")
  else $expected || (if ($expected < $today) then "\cellcolor{red}" else "")
};
declare function local:overdue-message($student, $timecol){
  if (exists($student($timecol)) and contains($student($timecol)(1), "{red}")) then 
    let $expected := substring-before($student($timecol)(1), "\") return
    utils:prepare-message-to($student,
      if ($timecol = 6) then x"Die Abgabe der Vortragsfolien ist überfällig (seit {$expected})."
      else if ($timecol = 7) then x"Die Abgabe der Ausarbeitung ist überfällig (seit {$expected})."
      else x"Die Abgabe des Reviews zum Thema {$student($timecol)(2)} ist überfällig (seit {$expected})."
    )
  else ()
};
let $student-times := utils:get-student-times()
let $dropped := file:read-text-lines("override")[contains(., "dropped")]!substring-before(.,",")
let $review-files := $utils:review-file-names ! [file:read-text-lines(.) ] 
let $mapping := file:read-text-lines("studentmapping")
(: [name, group, topic, old group, [appointment5], [upload6], [final9], [reviewtopic, review time]+ ] :)
let $student-progress := $student-times[.(1)] ! [ 
  .(1), .(2), .(3), .(4), 
  [local:maketime(.(5), $tasks-done-met(.(1)))], [local:maketime(.(6), $tasks-done("presentation")(.(1))[1])], [local:maketime(.(6), $tasks-done("paper")(.(1))[1])], [local:maketime(.(9), $tasks-done("paper")(.(1))[position()>1][last()])], .(8),
  for $fn at $f in $utils:review-file-names
  let $reviewed := utils:get-reviewed($review-files[$f](), .)
  return [local:maketime($student-times[.(1) = $reviewed(1)](7), $tasks-done($fn)(.(1))), utils:grouped-topic($reviewed)]
]
return (file:write("overdue.out", join(($student-progress!( local:overdue-message(., 6), local:overdue-message(., 7), local:overdue-message(., 10), local:overdue-message(., 11) ),""), $line-ending)) ,
utils:latex-wrap((
"
% Moodle title = Vorläufige Terminzuordnung

\usepackage[left=3cm,top=3cm,landscape]{geometry}
\usepackage[inline]{enumitem}
\usepackage{xcolor,colortbl}
\usepackage{longtable}

\newcommand{\xitem}[1][t]{\item {\bf #1}: }

\begin{document}",
  let $table := function($groupoverride, $addendum, $sortfunc) {
    let $groups := if ($groupoverride) then $groupoverride else (1 to (if ($utils:multi-groups) then 2 else 1))
    let $result := 
      for $student in $student-progress[.(2) = $groups]
      order by $sortfunc($student)
      return (
        join(($student(1), local:times($student(5)), local:timesFA($student(6),$student(7)), local:times($student(8)),local:times($student(10)), local:times($student(11)) ) , "&amp;") || "\\", 
        join((local:topic(utils:grouped-topic($student)), "\multicolumn{3}{c}{\small  Vortrag: "||$student(9)||"}",local:topic($student(10)(2)), local:topic($student(11)(2)) ) , "&amp;") || "\\\hline\\"
      )
    return (
    x"\section*{{ {("Themenzuordnung", "Gruppe A", "Gruppe B")[($groupoverride + 1, 1)[1]]} {$addendum} ({count($student-times[.(1) and .(2) = $groups])}) }} ",
    "\begin{longtable}{llccccc}
    \bf Name &amp; \bf Vorbesprechung &amp; \bf Ausarbeitung/Folien &amp; \bf Endfassung &amp; \bf Review 1 &amp; \bf Review 2\\ ",
    $result,
    "\end{longtable} \textbf{Verschwunden: }" ||(if (not($groupoverride)) then join($dropped, ",  ") else ())|| " \pagebreak"
    )
  }

return (
$table((), "{\small (Sortierung: Zeit)}", function($s){$s(5)(1)}),
$table((), "{\small (Sortierung: Name)}", function($s){$s(1)}),
$table((), "{\small (Sortierung: Thema)}", function($s){$s(3)}),
$table(1, "{\small (Sortierung: Zeit)}", function($s){$s(5)(1)}),
$table(2, "{\small (Sortierung: Zeit)}", function($s){$s(5)(1)})
)



))
)