#!/bin/bash
#Im Moodle muss die Zahl der angezeigten Abgaben auf 100 gesetzt werden (oder die Zahl der Studenten), da nur die erste Seite heruntergeladen wird.
if [[ -z "$exercise" ]]; then echo "you need to set an exercise (id from exercise grading view)";exit;fi

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

mkdir -p submissions/files


~/xidel --variable user,pass 'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' --save-cookies tmpsession

for exercise in $(~/xidel --variable exercise -e 'tokenize($exercise, ",")!normalize-space()'); do 

touch submissions/old$exercise
touch submissions/history$exercise

~/xidel --load-cookies tmpsession \
   "https://moodle.uni-luebeck.de/mod/assign/view.php?id=$exercise&action=grading"  \
   -e 'let $table := css("table.generaltable"), $col := count(exactly-one($table/thead/tr/th[.//a[contains(@href, "timesubmitted")]])/preceding-sibling::th ) + 1 return $table/tbody/tr/td[$col][not(normalize-space(.) = ("", "-"))]!x"{normalize-space(join(..//a[contains(@href, "user/view")]))} § {.} § {let $file := ..//a/@href[contains(., "assignsubmission_file")] return if ($file) then $file else ..//a/@href[contains(., "onlinetext")] } "' | sort > submissions/new$exercise

comm -23 submissions/new$exercise submissions/old$exercise > submissions/active$exercise

cat submissions/new$exercise >> submissions/history$exercise
sort -u submissions/history$exercise -o submissions/history$exercise

#cp submissions/new$exercise /tmp/new$exercise$(date +"%Y%mT%d%H%M%S")
#cp submissions/old$exercise /tmp/old$exercise$(date +"%Y%mT%d%H%M%S")
#cp submissions/active$exercise /tmp/active$exercise$(date +"%Y%mT%d%H%M%S")

cp submissions/new$exercise submissions/old$exercise



~/xidel -e 'declare function local:url2dir($u) { "submissions/files/" || extract($url, "([0-9]+/[^/?]+)([?].*)?$", 1)} ;
        $lines := unparsed-text-lines("submissions/active'$exercise'") ! extract(., "[^§]+$") ! normalize-space(),
        $lines ! ( try { file:delete(local:url2dir(.), true()) } catch * {()})' \
        --load-cookies tmpsession \
        [ -f '$lines[contains(., "assignsubmission_file")] ' \
        --download  '{local:url2dir($url)}' ]	 \
        [ -f '$lines[contains(., "plugin=onlinetext")] ' \
        -e '$path := x"submissions/files/{extract($url, "sid=(\d+)", 1)}", file:create-dir($path), file:write-text($path || "/onlinetext.html", outer-html(css(".submissionfull")))' ]

##   -e 'for $user in //a[contains(@href, "assignsubmission_file")] return $user/ancestor::tr[1]/((.//a[contains(@href, "user/view")])[last()])/
#x"{extract($user/@href, "(([0-9]+)/[^/]+[.][a-z]+)([?].*)?$", 2)} {extract(@href, "id=([0-9]+)", 1)} {.}"' \
#   -f '//a[matches(@href, "assignsubmission_file.*[0-9]+/[^/]+[.]c")]' --download  'submissions/{extract($url, "([0-9]+/[^/]+[.]c)([?].*)?$", 1)}' | tee -a usermap


done
