#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

mkdir -p pastsubmissions/files
while true; do
  if [[ -z "$( who  | grep -Ev 'root' | grep -Ev 'benitovanderzand +pts/3'|grep xxx)" ]]; then 
     source "$DIR/config.sh"
     export exercise
     $DIR/getsubmissions.sh
     for submission in submissions/files/*; do
#echo diff -q $submission/*.c  past$submission/*.c
       cfile="$submission/*.c"
       if diff -q "$cfile"  "past$cfile" ; then echo $submission already processed; rm -rf $submission; fi
     done

     $DIR/grader.sh 
     ( find ./results -type f   | sort | xargs sha1sum ) > resulthashs
     if ! diff resulthashs oldresulthashs;  then
       $DIR/results.sh;
       cp resulthashs oldresulthashs
     fi
     
#     cp -r submissions/files/* pastsubmissions/files
#     rm -rf submissions/files/*
  else  echo too many people ;
  fi
  sleep 3600;
done

