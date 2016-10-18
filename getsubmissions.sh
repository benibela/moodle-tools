#!/bin/bash
if [[ -z "$exercise" ]]; then echo "you need to set an exercise (id from exercise grading view)";exit;fi

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

mkdir -p submissions/files

touch submissions/old$exercise
~/xidel  --variable user,pass 'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   "https://moodle.uni-luebeck.de/mod/assign/view.php?id=$exercise&action=grading"  \
   -e 'let $table := css("table.generaltable"), $col := count(exactly-one($table/thead/tr/th[.//a[contains(@href, "timesubmitted")]])/preceding-sibling::th ) + 1 return $table/tbody/tr/td[$col][not(normalize-space(.) = ("", "-"))]!x"{..//a[contains(@href, "user/view")]} § {.} § {..//a/@href[contains(., "assignsubmission_file")]} "' > submissions/new$exercise

comm -23 submissions/new$exercise submissions/old$exercise > submissions/active$exercise
cp submissions/new$exercise submissions/old$exercise


~/xidel --variable user,pass -e "\$lines := unparsed-text-lines('submissions/active$exercise') ! extract(., '[^§]+\$') ! normalize-space()" \
        'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
        -f '$lines ' \
        --download  'submissions/files/{extract($url, "([0-9]+/[^/?]+)([?].*)?$", 1)}'

##   -e 'for $user in //a[contains(@href, "assignsubmission_file")] return $user/ancestor::tr[1]/((.//a[contains(@href, "user/view")])[last()])/
#x"{extract($user/@href, "(([0-9]+)/[^/]+[.][a-z]+)([?].*)?$", 2)} {extract(@href, "id=([0-9]+)", 1)} {.}"' \
#   -f '//a[matches(@href, "assignsubmission_file.*[0-9]+/[^/]+[.]c")]' --download  'submissions/{extract($url, "([0-9]+/[^/]+[.]c)([?].*)?$", 1)}' | tee -a usermap


