#!/bin/bash


~/xidel -e "name := '$1'" --xquery '
xquery version "3.0-xidel";
import module namespace utils="studenttopics" at "topiclib.xqm";
let $review-files := $utils:review-file-names ! [file:read-text-lines(.)]
let $student := exactly-one($utils:students-normal[.(1) = $name])
let $topic := normalize-space(utils:grouped-topic($student))
let $reviewer-lines := $review-files ! .()[ ends-with(normalize-space(.), $topic) ] (:review lines:)
let $reviewers := for $r in $reviewer-lines let $n := utils:get-review-name($r) return $utils:students-normal[.(1) = $n]
let $reviewed := $review-files ! utils:get-reviewed(.(), $name)    (: student arrays :)
let $replacement := for $r at $i in $reviewers return x"{utils:get-student-moodle-id($r)} {$r(1)} | {utils:grouped-topic($reviewed[$i])}"
return (
  "Changed: ",
  $replacement,
  
  "",

  for $fn at $reviewnr in $utils:review-file-names 
  let $reviews := $review-files[$reviewnr]()
  return (
    "","New file:", $utils:review-file-names[$reviewnr],
    let $newlines := (for $old in $reviews let $n := utils:get-review-name($old) return
      if ($n = $name) then ()
      else if ($n = $reviewers[$reviewnr](1)) then $replacement[$reviewnr]
      else $old)
    return (file:write-text-lines($utils:review-file-names[$reviewnr] || ".new", $newlines), $newlines)
  ),
  
  
  for $r at $i in $reviewers return (
    if (utils:grouped-topic($r) = utils:grouped-topic($reviewed[$i])) then ("Consistence check failed: ", $r, "cannot review his own topic") else (),
    if ($review-files[position() != $i]()[utils:get-review-name(.) = $r(1)]!normalize-space(substring-after(., "|")) = utils:grouped-topic($reviewed[$i])) then ("Consistence check failed: ", $r, "cannot review a topic twice") else ()
  ),
  
  "","Messages:",
  for $r at $i in $reviewers return (
  x"./message.sh {utils:get-student-moodle-id($r)} ""Das Thema {$topic} gibt es nicht mehr. Dein neues Reviewthema für Review {$i} ist {utils:grouped-topic($reviewed[$i])}."" # {$r(1)} "
  )
)
'