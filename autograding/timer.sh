#!/bin/sh
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )/.."
source "$DIR/common.sh"

while true; do
  course=1081 exercise=32214 assignmentfile=~/seminargeometry/termine.tex titleprepend=Ausarbeitung: ./autoseminarupload.sh 
  course=1081 exercise=32215 assignmentfile=~/seminargeometry/termine.tex titleprepend=Vortragsfolien: ./autoseminarupload.sh 
  course=1080 exercise=32225 assignmentfile=~/seminardatensicherheit/termine.tex titleprepend=Ausarbeitung: ./autoseminarupload.sh 
  course=1080 exercise=32226 assignmentfile=~/seminardatensicherheit/termine.tex titleprepend=Vortragsfolien: ./autoseminarupload.sh 

  sleep 3600;
done





