#!/bin/sh
export course=894
export user="benito.tcs"
echo Enter password for $user
read -r pass
export pass

~/xidel  $( (ls *.sheet; ls *.tex) | sort | tail -1) --variable 'course,user,pass' -e 'sheet := $raw, 
  $hour := 10, 
  $allow-file-upload := false(), 
  $uploadFilename := replace($url, "[.]tex", ".pdf"), 
  $slang := extract($sheet, "class\[(.*)\]\{article", 1), 
  $snumber := extract($sheet, "insertsheetnumber\{(.*)\}", 1), 
  $texdeadline := extract($sheet, "insertdeadline\{(.*)\}", 1 ), 
  $sdeadline := if (contains($texdeadline, ",")) then tokenize($texdeadline, ",") ! extract(., "[0-9]*") else reverse(tokenize(xs:string(parse-date(normalize-space(replace($texdeadline, "[^0-9a-zA-Z]", " ", "g")), "d mmmm yyyy" )), "-") ! extract(., "[1-9][0-9]*")),  
  $description := $title := if ($slang eq "english") then x"Exercise sheet {$snumber}" else x"Übungsblatt {$snumber}", 
  $assignmenttitle := $title  || if ($allow-file-upload) then "" else if ($slang eq "english") then " (results)" else " (Ergebnisse)", 
  $spoints := sum(tokenize(if (contains($sheet, "begin{homework}")) then substring-after($sheet, "begin{homework}") else $sheet, $line-ending) !  extract(., "^[^%]*credits=([^\],%]*)", 1) ! tokenize(., "[a-zA-Z ]+") [.] ! number())  '  \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  [ 'https://moodle.uni-luebeck.de/course/view.php?id={$course}' -e 'section := (((//span[contains(@class, "accesshide") and contains(.,  "Aufgabe")])[last()]/following::li[contains(@class, "section")])[1]/extract(@id, "[0-9]+"), $snumber)[1]' ]  \
  [ 'https://moodle.uni-luebeck.de/course/modedit.php?add=resource&type=&course={$course}&section={$section}&return=0&sr=0' -e 'infoForm := form(//form[contains(@action, "modedit")], {"name": $title, "introeditor[text]": $description})' -f '//noscript//object/@data[contains(., "env=filemanager")]' -f '//a/@href[contains(., "filepicker")]'  -f '//a[contains(., "hochladen")]'  -f 'form(//form, {"repo_upload_file": {"file": $uploadFilename}})' -f '//a/@href[not(starts-with(., "#"))]' -f '$infoForm' -e 'css("p.activity")[last()]' ] \
  [ 'https://moodle.uni-luebeck.de/course/modedit.php?add=assign&type=&course={$course}&section={$section}&return=0&sr=0' -f 'form((//form)[1], {"name": $assignmenttitle, "introeditor[text]": $assignmenttitle, "duedate[day]": $sdeadline[1], "duedate[month]": $sdeadline[2], "duedate[year]": $sdeadline[3], "duedate[hour]":  $hour, "grade[modgrade_point]": $spoints, "assignsubmission_file_enabled": if ($allow-file-upload) then "1" else ""})' -e 'css("span.instancename") [contains(., string($snumber))]' -e 'span.error' ]

 
