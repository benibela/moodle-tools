#!/bin/bash
while true; do
  if [[ -z "$( who  | grep -Ev 'tantau +pts/3' | grep -Ev 'benito +pts/4')" ]]; then 
     ./grader.sh 
  else  echo too many people ;
  fi
  sleep 3600;
done

