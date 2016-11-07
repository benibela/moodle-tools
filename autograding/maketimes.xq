xquery version "3.0";
(: summary of files
     "times": list of times (2018-01-02)
     "themenassigned.tex": student <-> topic mapping table ("topic & name 1 & name 2")
     "delayed": list of names, moved to the end of their group
     "override": list of lines "name, time" (possible ", group") to override dates
    
   $students := list of ([name, group, topic] or [name, new group, topic, old group] )   
 :)
import module namespace utils="studenttopics" at "topiclib.xqm";


let $student-times := utils:get-student-times()
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
      for $student in $student-times[.(2) = $groups]
      order by $sortfunc($student)
      return if ($student(1)) then join(($student(1), utils:grouped-topic($student), "ca. "||$student(5), $student()[position() > 5]), "&amp;") || "\\"
             else if ($groupoverride) then "&amp;&amp;&amp;&amp;&amp;---\\"
             else ()
    return (
    x"\section*{{ {("Themenzuordnung", "Gruppe A", "Gruppe B")[($groupoverride + 1, 1)[1]]} {$addendum} ({count($student-times[.(1) and .(2) = $groups])}) }} ",
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
$table((), "{\small (Sortierung: Thema)}", function($s){$s(3)}),
$table(1, "{\small (Sortierung: Zeit)}", function($s){$s(5)}),
$table(2, "{\small (Sortierung: Zeit)}", function($s){$s(5)})
),


"\end{document}"
)
