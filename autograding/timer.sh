#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )/.."
if [[ ! -f "$DIR/common.sh" ]]; then DIR=~/moodle; fi
source "$DIR/common.sh"

while true; do
  course=1929 exercise=53959 titleprepend=Ausarbeitung: $DIR/autograding/autoseminarupload.sh 
  course=1929 exercise=53960 titleprepend=Vortragsfolien: $DIR/autograding/autoseminarupload.sh 
  exercise=53961 reviewnr=1 ~/moodle/autograding/autoreviewupload.sh
  exercise=53962 reviewnr=2 ~/moodle/autograding/autoreviewupload.sh

  sleep 3600;
done





