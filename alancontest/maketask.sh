#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"/..
source "$DIR/common.sh"

if [[ -z "$course" ]]; then echo need course; exit; fi
export course


if [[ -z "$task" ]]; then task=$1; fi
if [[ -z "$task" ]]; then echo "Need task name \$task"; read -r task; fi

verbosetask=
case "$task" in
  maximum) verbosetask="Paralleles Maximum";;  
  prefix) verbosetask="Parallele Prefixsumme";;  
  pj) verbosetask="Paralleles Pointer Jumping";;  
  lr) verbosetask="Paralleles List Ranking";; 
  sort) verbosetask="Parallele Sortierung";;
  lenz) verbosetask="Parallelen Lenz";;  
  *) echo unknown tssk; echo "Need task verbose name"; read -r verbosetask;;
esac

export task
export verbosetask

~/xidel "" --variable 'course,user,pass,task,verbosetask' --allow-repetitions \
  'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  \
  'https://moodle.uni-luebeck.de/course/view.php?id={$course}' \
   -e 'section := (//li[contains(@class, "section") and matches(@aria-label, "Speedup|Wettbewerb")])[last()]/extract(@id, "[0-9]+")' \
   -e 'sdeadline := (31,7)' \
   \
   'https://moodle.uni-luebeck.de/course/modedit.php?add=label&type=&course={$course}&section={$section}&return=0&sr=0' \
   -f 'form((//form)[1], { "introeditor[text]": x"<h3>Problem {$task}_bench</h3> <p>Die jeweils besten Speedups von neun Läufen auf Alan.</p>" }) ' \
   -e '//h3[contains(., $task)]!("for results.sh: ", .,//ancestor::*[contains(@id,"module")]/@id)' -e 'span.error' \
   \
   'https://moodle.uni-luebeck.de/course/modedit.php?add=assign&type=&course={$course}&section={$section}&return=0&sr=0' \
   -f 'form((//form)[1], {
     "name": "Einreichung Ihres Codes für " || $verbosetask, 
     "introeditor[text]": x"Problem {$task}_bench", 
     "duedate[day]": $sdeadline[1], "duedate[month]": $sdeadline[2], 
     "assignsubmission_file_enabled": "1"})' \
   -e 'css("span.instancename") [contains(., string($verbosetask))] ! ("for getsubmissions.sh: ",., ancestor::a[1]/@href)' -e 'span.error' 
   
    
   
   