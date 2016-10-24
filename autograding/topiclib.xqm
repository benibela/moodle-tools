module namespace utils="studenttopics";
declare variable $utils:raw := file:read-text-lines("themenassigned.tex");
declare variable $utils:course := $utils:raw[contains(.,"Moodle course")]!extract(.,"[0-9]+");
declare variable $utils:topics := 
  let $tabstart := index-of($utils:raw, $utils:raw[contains(., "tabula")][1]) 
  return $utils:raw[position () > $tabstart];
declare variable $utils:multi-groups := exists($utils:topics[matches(., "Gruppe +[2B]")]);
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
  for $review-file in (1 to 2) ! x"review{.}"
  let $lines := file:read-text-lines($review-file)!normalize-space()
  let $line := $lines[ends-with(., $topictitle)]
  return extract($line, "^[0-9]+")
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

