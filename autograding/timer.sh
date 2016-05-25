#!/bin/sh
if [[ -z "$user" ]]; then export user=$(whoami)".tcs"; fi
if [[ -z "$pass" ]]; then echo "Enter password for $user"; read -r pass; fi

export user
export pass

while true; do
  course=1081 exercise=32214 assignmentfile=~/seminargeometry/termine.tex titleprepend=Ausarbeitung: ./autoseminarupload.sh 
  course=1081 exercise=32215 assignmentfile=~/seminargeometry/termine.tex titleprepend=Vortragsfolien: ./autoseminarupload.sh 
  course=1080 exercise=32225 assignmentfile=~/seminardatensicherheit/termine.tex titleprepend=Ausarbeitung: ./autoseminarupload.sh 
  course=1080 exercise=32226 assignmentfile=~/seminardatensicherheit/termine.tex titleprepend=Vortragsfolien: ./autoseminarupload.sh 

  sleep 3600;
done





