#!/bin/sh
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$course" ]]; then 
echo you need to set a course
exit
fi
if [[ -z "$section" ]]; then 
section=1
fi
export course
export user
export pass
export section
export title

while read -r title; do
  ~/xidel -s --variable course,user,pass,section,title \
  'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
  -f '//form[.//input[@name="edit" and @value="on"]]' \
  -f '(//a/@href[contains(., "editsection")])[$section + 1]' \
  -f 'form(//form, {"name": $title, "usedefaultname": ""})'  \
  -e 'css(".sectionname")[$section + 1]'
  ((section = $section + 1))
done;
