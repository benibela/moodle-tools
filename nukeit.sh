#!/bin/bash
# Deletes everything from a course
#   course
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"


if [[ -z "$course" ]]; then echo need course; exit; fi


 

echo This will destroy the course $course. Take a calm breath and think about your life
read

~/xidel --variable 'course,user,pass' \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
   -f '//form[.//input[@name="edit" and @value="on"]]' \
   -f '(//a[@data-action="delete"][not(ancestor::div[2]/css("span.accesshide")/normalize-space() = ("Forum", "Textseite", "Gruppenwahl"))])' \
   -f '//form[contains(@action, "mod.php")]'  
#   -e / --xml



