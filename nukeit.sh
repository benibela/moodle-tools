#!/bin/sh
if [[ -z "$course" ]]; then echo need course; exit; fi
if [[ -z "$user" ]]; then export user=$(cat ~/.moodleuser); fi
if [[ -z "$user" ]]; then echo Need moodle \$user; exit; fi
if [[ -z "$pass" ]]; then echo "Enter password for $user"; read -r pass; fi
export course
export user
export pass
 

echo This will destroy the course $course. Take a calm breath and think about your life
read

~/xidel --variable 'course,user,pass' \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
   -f '//form[.//input[@name="edit" and @value="on"]]' \
   -f '(//a[@data-action="delete"][not(ancestor::div[2]/css("span.accesshide")/normalize-space() = ("Forum", "Textseite"))])' \
   -f '//form[contains(@action, "mod.php")]'  
#   -e / --xml



