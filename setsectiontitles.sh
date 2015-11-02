#!/bin/sh
if [[ -z "$course" ]]; then 
echo you need to set a course
exit
fi
if [[ -z "$user" ]]; then 
export user="benito.tcs"
fi
if [[ -z "$pass" ]]; then 
echo Enter password for $user
read -r pass
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
  ~/xidel -q --variable course,user,pass,section,title \
  'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
  -f '//form[.//input[@name="edit" and @value="on"]]' \
  -f '(//a/@href[contains(., "editsection")])[$section + 1]' \
  -f 'form(//form, {"name": $title, "usedefaultname": ""})'  \
  -e 'css(".sectionname")[$section + 1]'
  ((section = $section + 1))
done;
