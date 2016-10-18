xquery version "3.0";
(: summary of files
     "times": list of times (2018-01-02)
     "themenassigned.tex": student <-> topic mapping table ("topic & name 1 & name 2")
     "delayed": list of names, moved to the end of their group
     "override": list of lines "name, time" (possible ", group") to override dates
    
   $students := list of ([name, group, topic] or [name, new group, topic, old group] )   
 :)
import module namespace utils="studenttopics" at "topiclib.xqm";


let $times := file:read-text-lines("times"), 
    $delayed := if (file:exists("delayed")) then file:read-text-lines("delayed") else (), 
    $override := (if (file:exists("override")) then file:read-text-lines("override") else ()),
    $time := function($i){ 
      if ($i < 1) then xs:date($times[1]) + ($i - 1) * xs:dayTimeDuration("P7D") 
      else if ($i > count($times)) then xs:date($times[last()]) + ($i - count($times)) * xs:dayTimeDuration("P7D") 
      else $times[$i] },
    $override := trace($override!normalize-space()[.] ! [let $row := tokenize(., ",")!normalize-space() return ($row[1], fn:exactly-one((1 to 20)[$time(.) = $row[2]]), if ($row[3]) then xs:integer($row[3]) else $utils:students-normal[.(1) = $row[1]](2) )], "override"), 
    $overridenNames := $override(1),
(:    $overridenToGroup := {| $override[.(3)] ! { .(1): .(3) } |},:)
   $students := (
     $utils:students-normal!(if ($delayed = .(1) or $overridenNames = .(1)) then ["",.(2)] else .), 
     $utils:students-normal[$delayed = .(1)]),
   $groups := (1 to (if ($utils:multi-groups) then 2 else 1)),
   $students := trace(
      for $group in $groups
      return
        let $oldmax := max(for $student in $students where $student(2) = $group count $week return $week)
        let $overridemax := max(($override[.(3) = $group](2),0))
        for $student in ($students, (1 to ($overridemax - $oldmax)) ! ["", $group] ) 
        where $student(2) = $group
        count $week
        let $over := $override[.(2) = $week and .(3) = $group ]
        return if ($over) then (
          if ($student(1) and not($student(1) = $overridenNames) ) then error(QName("x:x"), "Duplicate time" || $student(1) || " " || $over(1))
          else let $oldstudent := exactly-one($utils:students-normal[.(1) = $over(1)])
          return [$over(1), $group, $oldstudent(3), $oldstudent(2)]
        ) else if ($student(1) = $overridenNames) then [""]
        else $student
    , "final students")
return (
"\documentclass[10pt,a4paper]{article}
\usepackage[left=3cm,top=3cm,landscape]{geometry}
\usepackage[utf8]{inputenc}
\usepackage[inline]{enumitem}
% Moodle course = "||$utils:course||"
% Moodle title = Vorläufige Terminzuordnung

\newcommand{\xitem}[1][t]{\item {\bf #1}: }

\begin{document}",
  let $table := function($groupoverride, $addendum, $sortfunc) {
    let $groups := if ($groupoverride) then $groupoverride else (1 to (if ($utils:multi-groups) then 2 else 1))
    let $result := 
      for $sort in (
        for $group in $groups
        return
          for $student in $students 
          where  $student(2) = $group
          count $week
          return [$student(1), x"{("A","B")[($student(4), $student(2))[1]]||"."} {$student(3)}", x"ca. {$time($week - 4)}", $time($week - 2),  $time($week - 1), $time($week), $time($week + 2)] )      
      order by $sortfunc($sort)
      return if ($sort(1)) then join($sort(), "&amp;") || "\\"
             else if ($groupoverride) then "&amp;&amp;&amp;&amp;&amp;---\\"
             else ()
    return (
    x"\section*{{ {("Themenzuordnung", "Gruppe A", "Gruppe B")[($groupoverride + 1, 1)[1]]} {$addendum} ({count($students[.(1) and .(2) = $groups])}) }} ",
    "\begin{tabular}{llccccc}
    \bf Name &amp; \bf Thema &amp; \bf Vorbesprechung &amp; \bf Ausarbeitung/Folien &amp; \bf Gutachten &amp; \bf VORTRAG &amp; \bf Korrekturen\\ ",
    $result,
    "\end{tabular}
    
    \vspace{1cm}
    
    \begin{enumerate*}
    \xitem[Vorbesprechung] Ein Termin mit uns zur Besprechung der Ausarbeitung/Vortragsplanung
    \xitem[Ausarbeitung/Folien] Hochladen der Ausarbeitung und des Vortrags im Moodle
    \xitem[Gutachten] Abgabe der Gutachten durch die beiden Reviewer
    \xitem[Vortrag] Der eigentliche Vortrag im Seminar
    \xitem[Korrekturen] Abgabe eventueller Korrekturen
    \end{enumerate*}")
  }

return (
$table((), "{\small (Sortierung: Name)}", function($s){$s(1)}),
$table((), "{\small (Sortierung: Thema)}", function($s){substring-after($s(2), " ")}),
$table(1, "{\small (Sortierung: Zeit)}", function($s){$s(3)}),
$table(2, "{\small (Sortierung: Zeit)}", function($s){$s(3)})
),


"\end{document}"
)
