#!/bin/bash

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$1" ]]; then texfile=$( (ls *.sheet; ls *.tex) | sort | tail -1)
else texfile="$1"
fi

uploads=$($xidel "$texfile" --variable 'course,user,pass' --extract-include xxxxxnone --xquery '
  declare function local:tex-replace($s, $commands, $cutoff) {
    let $cmd := extract($s, "\\([a-zA-Z]+)", (0, 1))
    return if ($cmd[1] and $cutoff > 0) then local:tex-replace(replace($s, $cmd[1], $commands($cmd[2]), "q"), $commands, $cutoff - 1)
    else $s
  };()' --xquery '
  $sheet := $raw, 
  $includes := ( let $direct := extract($sheet ,"\\input\{(.*)\}", 1, "*") ! resolve-uri(., $url)
                 return ($direct, if (empty($direct[contains(., "lecture-config")])) then
                   ("../config", "../../config/", "../../../config", "../", "../../", "../../../")!resolve-uri(. || "lecture-config.tex", $url)[file:exists(.)][1]
                  else () )
                ) ! file:read-text(.),
  $tex-defs := {},  
  for tumbling window $cmd in ($includes, $sheet) ! extract ( .,  "\\def\\([^{]+)\{(.*)\}", (1,2) , "*") start at $i when true() end at $j when $j - $i > 0 return
    $tex-defs($cmd[1]) := local:tex-replace($cmd[2], $tex-defs, 100),
  $option := function($name, $default) {
    let $env := environment-variable("moodle_"||translate($name,"-","_"))
    return if ($env) then $env
    else let $res := extract($sheet, "% *Moodle +"||$name||" *= *(.*)", 1) return
    if ($res) then $res 
    else ( $includes ! extract(., "% *Moodle +"||$name||" *= *(.*)", 1)[.], $default) [1]
  },
  $course := integer($option("course", $course)),
  $hour := integer($option("hour", 10)),
  $allow-file-upload := $option("allow-file-upload", false()) cast as xs:boolean, 
  $make-assignment := $option("make-assignment", contains($sheet, "\usepackage{tcs-exercise}") or contains($sheet, "\begin{homework}") or contains($sheet, "\begin{classroom exercises}")) cast as xs:boolean, 
  $uploadFilename := $option("file-to-upload", replace($url, "[.]tex", ".pdf")), 
  $slang := $option("lang", extract($sheet, "class\[(.*)\]\{article", 1)), 
  $slang-is-english := tokenize($slang, ",") = "english",
  $snumber := extract($sheet, "insertsheetnumber\{(.*)\}", 1), 
  $texdeadline := local:tex-replace(  extract($sheet, "insertdeadline\{(.*)\}", 1 )  , $tex-defs, 100), 
  $sdeadline := if (not($make-assignment)) then "" 
                else if (contains($texdeadline, ",")) then tokenize($texdeadline, ",") ! extract(., "[0-9]*") 
                else reverse(tokenize(xs:string(parse-date(normalize-space(replace($texdeadline, "[^0-9a-zA-Z]", " ")), "d mmmm yyyy" )), "-") ! extract(., "[1-9][0-9]*")),  
  $title := $option("title", if ($slang-is-english) then x"Exercise sheet {$snumber}" else x"Übungsblatt {$snumber}"), 
  $description := $option("description", $title),
  $assignmenttitle := $title  || (if ($allow-file-upload) then "" else if ($slang-is-english) then " (results)" else " (Ergebnisse)"), 
  $sheetlines := tokenize(if (contains($sheet, "begin{homework}")) then substring-after($sheet, "begin{homework}") 
                             else $sheet, $line-ending),
  $creditlines := $sheetlines ! extract(., "^[^%]*credits=([^\],%]*)", 1)[.],
  $sumpoints := sum( $creditlines ! tokenize(., "[a-zA-Z ]+") [.] ! number()),
  $minpoints := sum( $creditlines ! (tokenize(., "[a-zA-Z ]+") [.] [1]) ! number()) idiv 2,
  $additionalUploads := extract($sheet, "% *Moodle upload (.*)", 1, "*"),
  $team-submission := $option("team-submission", ())[. = ("true", "1")]!"1",
  $vpls := extract($sheet, "% *Moodle vpl (.*)", 1, "*")
  '  \
   'https://moodle.uni-luebeck.de/' -f 'form((//form)[1], {"username": $user, "password": $pass})' \
  [ 'https://moodle.uni-luebeck.de/course/view.php?id={$course}' --allow-repetitions \
    -e 'section := $option("section-index", (((//span[contains(@class, "accesshide") and contains(.,  "Aufgabe") and matches(.., "Übungsblatt|Exercise +sheet")])[last()]/following::li[contains(@class, "section")])[1]/extract(@id, "[0-9]+"), $snumber)[1])' \
    -e '()' \
  ]  -e 'map:merge((
   {"section": $section, 
    "section-assignment": $section + xs:integer($option("section-index-assignment-delta", 0)),
    "title": $title, 
    "course": $course},
   {"uploads": array{
      {"name": $title, "description": $description, "filename": $uploadFilename },
      $additionalUploads ! {"name": ., "filename": file:resolve-path(.) }
      }
   },
   {"assignment": {
     "name": $assignmenttitle,
     "introeditor[text]": $assignmenttitle, 
     "duedate[day]": $sdeadline[1], 
     "duedate[month]": $sdeadline[2], 
     "duedate[year]": $sdeadline[3], 
     "duedate[hour]":  $hour, 

     "grade[modgrade_point]" ?: $sumpoints[. > 0],
     "gradepass" ?: $minpoints[. > 0],

     "grade[modgrade_type]" ?: "scale"[$sumpoints = 0],
     "grade[modgrade_scale]" ?: "8"[$sumpoints = 0],
     
     "gradingduedate[enabled]": "",
     "allowsubmissionsfromdate[enabled]": "", (:either set a date or disable it, otherwise there are problems with duedate < default allowsubmissionfromdate:)
     "assignsubmission_file_enabled": if ($allow-file-upload) then "1" else "",
     "assignfeedback_file_enabled" ?: if ($allow-file-upload) then "1" else (),
     "teamsubmission" ?: $team-submission
     }
   }[$make-assignment],
   {"vpls": array{$vpls!{
     "filename": file:resolve-path(.),
     "assignment-options": {
       "worktype" ?: $team-submission
     }
   }}}
   ), {"duplicates": "combine"})
  ')

echo "Upload parameters: (start)" 
  
echo "$uploads"

echo "parameters end"



#exit

export course=$($xidel - -e '?course' <<<"$uploads")
export section=$($xidel - -e '?section' <<<"$uploads")
export DIR
export folderid=""
eval "$($xidel - --variable DIR -e '?uploads?*!x"'"name='{?name}' description='{?description}' {\$DIR}/upload.sh '{?filename}'"'"' <<<"$uploads")"

export section=$($xidel - -e '?section-assignment' <<<"$uploads")
export id=""
eval "$($xidel - --variable DIR -e 'let $title := ?title return ?vpls?*!x"'"name='{\$title}' {\$DIR}/setupvpl.sh '{?filename}'  '{serialize-json(?assignment-options)}' "'"' <<<"$uploads")"
$xidel - -e '?assignment' <<<"$uploads" | $DIR/makeassignment.sh


