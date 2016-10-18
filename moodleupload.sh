#!/bin/bash

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$1" ]]; then texfile=$( (ls *.sheet; ls *.tex) | sort | tail -1)
else texfile="$1"
fi

~/xidel "$texfile" --variable 'course,user,pass'  --xquery '
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
    let $res := extract($sheet, "% *Moodle +"||$name||" *= *(.*)", 1) return
    if ($res) then $res 
    else ( $includes ! extract(., "% *Moodle +"||$name||" *= *(.*)", 1)[.], $default) [1]
  },
  $course := integer($option("course", $course)),
  $hour := integer($option("hour", 10)),
  $allow-file-upload := $option("allow-file-upload", false()) cast as xs:boolean, 
  $make-assignment := $option("make-assignment", contains($sheet, "\usepackage{tcs-exercise}") or contains($sheet, "\begin{homework}") or contains($sheet, "\begin{classroom exercises}")) cast as xs:boolean, 
  $uploadFilename := $option("file-to-upload", replace($url, "[.]tex", ".pdf")), 
  $slang := $option("lang", extract($sheet, "class\[(.*)\]\{article", 1)), 
  $snumber := extract($sheet, "insertsheetnumber\{(.*)\}", 1), 
  $texdeadline := local:tex-replace(  extract($sheet, "insertdeadline\{(.*)\}", 1 )  , $tex-defs, 100), 
  $sdeadline := if (not($make-assignment)) then "" 
                else if (contains($texdeadline, ",")) then tokenize($texdeadline, ",") ! extract(., "[0-9]*") 
                else reverse(tokenize(xs:string(parse-date(normalize-space(replace($texdeadline, "[^0-9a-zA-Z]", " ")), "d mmmm yyyy" )), "-") ! extract(., "[1-9][0-9]*")),  
  $title := $option("title", if ($slang eq "english") then x"Exercise sheet {$snumber}" else x"Übungsblatt {$snumber}"), 
  $description := $option("description", $title),
  $assignmenttitle := $title  || (if ($allow-file-upload) then "" else if ($slang eq "english") then " (results)" else " (Ergebnisse)"), 
  $spoints := sum(tokenize(if (contains($sheet, "begin{homework}")) then substring-after($sheet, "begin{homework}") 
                           else $sheet, $line-ending) 
                  !  extract(., "^[^%]*credits=([^\],%]*)", 1) ! tokenize(., "[a-zA-Z ]+") [.] ! number())  '  \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  [ 'https://moodle.uni-luebeck.de/course/view.php?id={$course}' --allow-repetitions \
    -e 'section := $option("section-index", (((//span[contains(@class, "accesshide") and contains(.,  "Aufgabe") and matches(.., "Übungsblatt|Exercise +sheet")])[last()]/following::li[contains(@class, "section")])[1]/extract(@id, "[0-9]+"), $snumber)[1])' \
    -f 'form((//form)[1], "edit=on")' \
    -f 'css("div.activityinstance")[contains(a/@href, "view.php") and .//text()/normalize-space() = $title]/..//a[matches(@href, "mod[.]php.*hide")]'\
    -e '()' \
  ]  \
  [ 'https://moodle.uni-luebeck.de/course/modedit.php?add=resource&type=&course={$course}&section={$section}&return=0&sr=0' -e 'infoForm := form(//form[contains(@action, "modedit")], {"name": $title, "introeditor[text]": $description})' -f '//noscript//object/@data[contains(., "env=filemanager")]' -f '//a/@href[contains(., "filepicker")]'  -f '//a[contains(., "hochladen")]'  -f 'form(//form, {"repo_upload_file": {"file": $uploadFilename}})' -f '//a/@href[not(starts-with(., "#"))]' -f '$infoForm' -e 'css("p.activity")[last()]' ] \
  [ 'https://moodle.uni-luebeck.de/course/modedit.php?add=assign&type=&course={$course}&section={$section}&return=0&sr=0' -f 'form((//form)[1], {"name": $assignmenttitle, "introeditor[text]": $assignmenttitle, "duedate[day]": $sdeadline[1], "duedate[month]": $sdeadline[2], "duedate[year]": $sdeadline[3], "duedate[hour]":  $hour, "grade[modgrade_point]": $spoints, "assignsubmission_file_enabled": if ($allow-file-upload) then "1" else ""})[$make-assignment]' -e 'css("span.instancename") [contains(., string($snumber))]' -e 'span.error' ]

 
