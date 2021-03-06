#!/bin/bash
if [[ -z "$course" ]]; then echo need course; exit; fi
if [[ -z "$exercise" ]]; then echo need exercise; exit; fi
#if [[ -z "$assignmentfile" ]]; then echo "need assignmentfile (3 columns, date & name & termin\\\\)"; exit; fi

#basepath="$(dirname -- ${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]})"/../
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )/.."
source "$DIR/common.sh"


export course
export exercise
export assignmentfile
export titleprepend


$DIR/getsubmissions.sh 


if [ ! -e tmpsections$course ]; then
  ~/xidel --variable course,user,pass \
            'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
            'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
            -e 'css("h3.sectionname")' > tmpsections$course
fi

            

export DIR
~/xidel --variable course,user,pass,exercise,titleprepend,DIR \
          -e 'xquery version "3.0-xidel"; 
            import module namespace utils="studenttopics" at "topiclib.xqm", "'$DIR/autograding/'topiclib.xqm";
            declare function char-delta($s, $c, $i){
              if (substring($s, $i, 1) eq $c) then 0
              else min(  ( (1 to $i - 1)[ substring($s, ., 1) eq $c ] ! ($i - .), ($i + 1 to string-length($s))[ substring($s, ., 1) eq $c ] ! (. - $i ) , 2 * string-length($s))   )
            };
            declare function simple-str-sim($s, $t) {
              sum (( (1 to string-length($s)) ! char-delta($t, substring($s, ., 1), .),
                     (1 to string-length($t)) ! char-delta($s, substring($t, ., 1), .) )) div (string-length($s) + string-length($t))
            }; 
            declare function simple-name-sim($s, $t) {
              let $st := tokenize($s, " "), $tt := tokenize($t, " ")
              return simple-str-sim($st[1], $tt[1]) + simple-str-sim($st[count($st)], $tt[count($tt)])
            }; 
            declare function simple-section-sim($section, $name) {
              let $s := normalize-space(if (contains($section, ":")) then substring-before($section, ":") else $section)
              let $t := normalize-space($name)
              return simple-name-sim($s, $t)
            }; 
            let $sections := unparsed-text-lines("tmpsections" || $course)
            let $history := if (file:exists("submissions/history"||$exercise)) then file:read-text-lines("submissions/history"||$exercise)![tokenize(., "§")!normalize-space()] else ()
            for $submission in file:read-text-lines("submissions/active"||$exercise)
            let $cols := tokenize($submission, "§")
            where count($cols) ge 2
            let $name := normalize-space($cols[1])
            let $version := count($history[ .(1) = $name ])
            let $filename := "submissions/files/" || extract($submission,"([0-9]+/[^/?]+)([?].*)? *$", 1)
            let $student := exactly-one($utils:students-normal[.(1) = $name])
            let $assignment := $student(3)
            let $assignmenttitle := $titleprepend || " "|| utils:grouped-topic($student) || (if ($utils:multi-groups) then " von " || $name else "")
            let $uploadInfoFile := file:resolve-path(replace($filename, "[.][a-zA-Z]+$", "") || ".tex")
            return (
             file:write-text-lines($uploadInfoFile,
               ("%Moodle title="||$assignmenttitle, 
                "%Moodle file-to-upload="||file:resolve-path($filename), 
                "%Moodle make-assignment=false",
                "%Moodle section-index="||(for $id in (1 to count($sections)) order by simple-section-sim($sections[$id], $assignment) return $id)[1] - 1)),
             system(x"{$DIR}/moodleupload.sh ""{$uploadInfoFile}"""),
             let $reviewers := utils:get-reviewers-moodle-id($student)
             for $reviewer at $id in $reviewers return
             system(x"{$DIR}/message.sh {$reviewer} ""Das zum Reviewen {if (count($reviewers) ge 2) then x" (<b>für Review {$id}</b>)" else ()}  vorgesehene Thema {$assignmenttitle} { if ($version ge 2) then x" ({format-integer($version, "w;o", "de")} Fassung)" else ()} wurde am { $cols[2] } abgegeben.""")
                )' 
  
#  || " => " ||
#
#            ' 
#outputs section, upload file to section, hide old
#create tex file with options
#
