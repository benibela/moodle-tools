#!/bin/sh
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )/.."
source "$DIR/common.sh"

while true; do
  course=1929 exercise=53959 titleprepend=Ausarbeitung: $DIR/autograding/autoseminarupload.sh 
  course=1929 exercise=53960 titleprepend=Vortragsfolien: $DIR/autograding/autoseminarupload.sh 

  sleep 3600;
done





