#!/bin/bash
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR=~/moodle
source $DIR/common.sh

if [[ -z "$course" ]]; then echo need course; exit; fi
export course

if [[ ! -f studentmapping ]]; then echo call checkstudents to create studentmapping file; exit; fi

~/xidel --variable user,pass,course --extract-include=result \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   [ 'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
   -e 'import module namespace utils="studenttopics" at "topiclib.xqm";
       student-ids := {| file:read-text-lines("studentmapping")!{substring-after(.," "):substring-before(.," ")} |},
       reviewsg := (), choserg := (), assigned-topics := {},
       assigned-topics-for-presentation := {| for $s in $utils:students-normal return { ("A. ","B. ")[$s(2)]||$s(3): $s(1)  } |}
   ' \
   -f '//a[contains(., "Review-Auswahl")]/resolve-html(.)!replace(.,"view","report")' \
   -e '<table class="results">
     {$reviewsg[] := [./thead/(tr[1]/th except tr[1]/(th[1],th[2]))],
      $choserg[] := [./tbody/(tr[2]/td except tr[2]/(td[1],td[2]))!((css("a.username")/normalize-space(),"")[1])]}
   </table>' ]  \
   '<final/>' -e 'xquery version "3.0-xidel";
   (:declare function utils:shuffle($seq) {
     if (empty($seq)) then () else
     let $p := x:random(count($seq))+1 
     return ($seq[$p], utils:shuffle((subsequence($seq, 1, $p - 1), subsequence($seq, $p + 1, count($seq)))))
   };:)
     declare function local:shuffle-topics($topics, $students) {
       if (empty($topics)) then () else
       let $p := x:random(count($topics))+1,
           $topic := $topics[$p],
           $group := normalize-space(substring-before($topic, ".")),
           $text := normalize-space(substring-after($topic, ".")),
           $stud := head($students)
       return if ($assigned-topics($topics[$p]) = $stud or exists($utils:students-normal[.(1) = $stud and .(3) = $text])) then local:shuffle-topics($topics, $students)       
       else ($topic, local:shuffle-topics((subsequence($topics, 1, $p - 1), subsequence($topics, $p + 1, count($topics))), tail($students)))
     };
   
     for $rid in 1 to count($reviewsg) 
     let $reviews := $reviewsg[$rid]()
     let $choser := $choserg[$rid]()
     return (
      for $i in 1 to count($reviews) where $choser[$i] return $assigned-topics($reviews[$i]) := ($assigned-topics($reviews[$i]), $choser[$i]),
      unassigned := for $i in 1 to count($reviews) where not($choser[$i]) return $reviews[$i],
      students-without-review := $utils:students-normal(1)[not(. = $choser)],
      unassigned-shuffled := local:shuffle-topics($unassigned,$students-without-review),
      for $s at $i in $students-without-review return 
        $assigned-topics($unassigned-shuffled[$i]) := ($assigned-topics($unassigned-shuffled[$i]), $s),
      title := "Review "||$rid,
      result := (
      "-------------Review "|| $title||"------------",
      "Assigned reviews: ",
      for $i in 1 to count($reviews) where $choser[$i] let $s := $choser[$i] return x"{$student-ids($s)} {$s} | {$reviews[$i]}",
      "","Unassigned reviews: " ,
        $unassigned,
      "","Students without review: " || count($unassigned),
      $students-without-review,
      "","Random assignment:"|| count($students-without-review),
      for $s at $i in $students-without-review return x"{$student-ids($s)} {$s} | {$unassigned-shuffled[$i]}",
      "","Message script:",
      for $s at $i in $students-without-review return x"./message.sh {$student-ids($s)} ""Als Thema für {$title} wurde dir zufällig {$unassigned-shuffled[$i]} ausgearbeitet von { $assigned-topics-for-presentation($unassigned-shuffled[$i]) } zugewiesen."" #{$s}",
      "","","")
      )
   '   
