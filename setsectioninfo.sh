#!/bin/bash
# Sets text of section $section
# Input as environment variables and parameters
#   course
#   section
#   name
#   description
#   descriptionformat
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$course" ]]; then 
echo you need to set a course
exit
fi
if [[ -z "$section" ]]; then 
echo you need to set a section
exit
fi


export course
export section
export name
export description
export descriptionformat
export options=""

moodle  --verbose --variable section,name,description,descriptionformat,options                                    \
      'https://moodle.uni-luebeck.de/course/view.php?id='$course                                        \
      -f 'moodle:course-edit-follow(/)'                                                                 \
      -f '(//a/@href[contains(., "editsection") and not(contains(., "delete=1"))])[$section + 1]'       \
      -f 'moodle:modedit-form(/, $name, $description, $descriptionformat, $options)'                    \
      -e 'css(".sectionname")[$section + 1]' \
      --download /tmp/view.html

      #-f 'form(//form, {"name": $title, "usedefaultname": ""})'  \
      #

exit;
      
#      "$baseurl/course/modedit.php?add=$thingtoadd&type=&course=$course&section=$section&return=0&sr=3" \
#     -f 'moodle:modedit-form(/, $name, $description, $descriptionformat, $options)'                     \
#--download '/tmp/added/'  \
#      -e '//*[starts-with(@id, "id_error")]!normalize-space()[.]' 


while read -r title; do
  ~/xidel -s --variable course,user,pass,section,title \
  'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
  -f '//form[.//input[@name="edit" and @value="on"]]' \
  ((section = $section + 1))
done;
