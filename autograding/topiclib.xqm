module namespace utils="studenttopics";
declare variable $utils:raw := file:read-text-lines("themenassigned.tex");
declare variable $utils:course := $utils:raw[contains(.,"Moodle course")]!extract(.,"[0-9]+");
declare variable $utils:topics := 
  let $tabstart := index-of($utils:raw, $utils:raw[contains(., "tabula")][1]) 
  return $utils:raw[position () > $tabstart];
declare variable $utils:multi-groups := exists($utils:topics[matches(., "Gruppe +[2B]")]);
declare variable $utils:review-file-names := ("review1", "review2");
declare function utils:group-name($i){ ("A", "B") [$i]   };
declare function utils:grouped-topic($topic){ 
  if ($topic instance of xs:string) then $topic
  else if ($utils:multi-groups) then utils:group-name(($topic(4),$topic(2))[1]) || ". "||$topic(3) 
  else  $topic(3)
};
declare variable $utils:students-normal :=  trace(
      for $topic  in tail($utils:topics)!replace(.,"(\\(endl|\\|&amp;)|%).*","")!translate(.,"\{}","")[contains(.,"&amp;")]!normalize-space()
      let $split := tokenize($topic,"[&amp;]")!normalize-space()
      for $name at $group in tail($split) where $name
      return [$name, $group, $split[1]], "students");
declare function utils:get-reviewers-moodle-id($topic){
  let $topictitle := "| "||normalize-space(utils:grouped-topic($topic))
  for $review-file in $utils:review-file-names
  let $lines := file:read-text-lines($review-file)!normalize-space()
  let $line := $lines[ends-with(., $topictitle)]
  return extract($line, "^[0-9]+")
};
declare function utils:get-review-name($review-line){
  normalize-space(substring-before(substring-after($review-line," "), "|"))
};
(: returns the student reviewed by $student :)
declare function utils:get-reviewed($file, $student){
  let $student := if ($student instance of xs:string) then $student else $student(1)
  let $reviews := if (count($file) = 1 and $file instance of xs:string) then file:read-text-lines($file) else $file
  let $topic := normalize-space(substring-after($reviews[utils:get-review-name(.) = $student], "|"))
  return $utils:students-normal[ utils:grouped-topic(.) = $topic ]
};
declare function utils:get-student-moodle-id($student){
  let $student := if ($student instance of xs:string) then $student else $student(1)
  let $mapping := file:read-text-lines("studentmapping")
  return substring-before($mapping[substring-after(.," ") = $student], " ")
};
declare function utils:prepare-message-to($student, $message){
  concat("./message.sh ",utils:get-student-moodle-id($student), " '", replace($message, "'", "''"), "' #", $student(1)   )
};
(: [name, new group, topic, old group, Ausarbeitung/Folien, Gutachten , VORTRAG , Korrekturen] + :)
declare function utils:get-grouped-student-times(){
  let $times := file:read-text-lines("times"), 
  $override-raw := (if (file:exists("override")) then file:read-text-lines("override") else ())!normalize-space()[.],
  $time := function($i){ 
    if ($i < 1) then xs:date($times[1]) + ($i - 1) * xs:dayTimeDuration("P7D") 
    else if ($i > count($times)) then xs:date($times[last()]) + ($i - count($times)) * xs:dayTimeDuration("P7D") 
    else $times[$i] },
  $override := $override-raw ! [
    let $row := tokenize(., ",")!normalize-space() where not($row[2] = ("dropped", "delayed"))
    return ($row[1], 
            fn:exactly-one((1 to 20)[$time(.) = $row[2]]), 
            if ($row[3]) then xs:integer($row[3]) else $utils:students-normal[.(1) = $row[1]](2) 
           )], 
  $dropped := $override-raw[ends-with(., "dropped")]!substring-before(.,",")!normalize-space(),
  $delayed := $override-raw[ends-with(., "delayed")]!substring-before(.,",")!normalize-space(),
  $overridenNames := $override(1),
  $notThereNames := ($dropped, $delayed, $overridenNames),
(:    $overridenToGroup := {| $override[.(3)] ! { .(1): .(3) } |},:)
 $students := (
   $utils:students-normal!(if (.(1) = $notThereNames) then ["",.(2),""] else .), 
   $utils:students-normal[$delayed = .(1)]),
 $groups := (1 to (if ($utils:multi-groups) then 2 else 1)),
 $students := trace(
    for $group in $groups
    return
      let $oldmax := max(for $student in $students where $student(2) = $group count $week return $week)
      let $overridemax := max(($override[.(3) = $group](2),0))
      for $student in ($students, (1 to ($overridemax - $oldmax)) ! ["", $group, ""] ) 
      where $student(2) = $group
      count $week
      let $over := $override[.(2) = $week and .(3) = $group ]
      return if ($over) then (
        if ($student(1) and not($student(1) = $overridenNames) ) then error(QName("x:x"), "Duplicate time" || $student(1) || " " || $over(1))
        else let $oldstudent := exactly-one($utils:students-normal[.(1) = $over(1)])
        return [$over(1), $group, $oldstudent(3), $oldstudent(2)]
      ) else if ($student(1) = $overridenNames) then ["",$group,""]
      else $student
  , "final students")
 for $group in $groups
 return [
   for $student in $students 
   where  $student(2) = $group
   count $week
   return [$student(1), $student(2), $student(3), ($student(4),$student(2))[1], $time($week - 4), $time($week - 2),  $time($week - 1), $time($week), $time($week + 2)]
 ] 
};
declare function utils:get-student-times(){
  utils:get-grouped-student-times()()
};

(:declare function utils:similarity-seq($s,$t){ 
  sum(for $i in 1 to count($s) return min(( 
    $i - (for $j in 1 to $i where $s[$i] = $t[$j] return $j)[last()], 
    (for $j in $i to count($t) where $s[$i] = $t[$j] return $j)[1] - $i )  ))
};
declare function utils:similarity($s,$t){ 
  let $ss := string-to-codepoints($s), $st := string-to-codepoints($t) 
  return utils:similarity-seq($ss, $st)  + utils:similarity-seq($st, $ss)
};:)
declare function utils:char-delta($s, $c, $i){
  if (substring($s, $i, 1) eq $c) then 0
  else min(  ( (1 to $i - 1)[ substring($s, ., 1) eq $c ] ! ($i - .), ($i + 1 to string-length($s))[ substring($s, ., 1) eq $c ] ! (. - $i ) , 2 * string-length($s))   )
};
declare function utils:simple-str-sim($s, $t) {
  sum (( (1 to string-length($s)) ! utils:char-delta($t, substring($s, ., 1), .),
         (1 to string-length($t)) ! utils:char-delta($s, substring($t, ., 1), .) )) div (string-length($s) + string-length($t))
}; 
(: returns the difference between two names (inverse of the similarity) :)
declare function utils:simple-name-sim($s, $t) {
  let $stp := tokenize($s, " "), $ttp := tokenize($t, " "),
      $st := if (contains($s,",")) then reverse($stp) else $stp, 
      $tt := if (contains($t,",")) then reverse($ttp) else $ttp
  return utils:simple-str-sim($st[1], $tt[1]) + utils:simple-str-sim($st[count($st)], $tt[count($tt)])
}; 

declare function utils:latex-wrap($texts){
 ("\documentclass[10pt,a4paper]{article}
  \usepackage[utf8]{inputenc}
  % Moodle course = " || $utils:course || "
  ",
  $texts,
  "\end{document}"
 )
};