#!/bin/bash
#Start the moodle download/upload processes
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"
source "$DIR/config.sh"

touch $lockfile
chmod a+rwx $lockfile 
exec 100>$lockfile 

mkdir -p $graderbasepath
chmod a+rwx $graderbasepath

mkdir -p $submissionspath/files
mkdir -p $moodletmppath
cd $submissionspath/../
while true; do
  if flock -w 3600 100; then 
     source "$DIR/config.sh"
     export exercise
     $DIR/getsubmissions.sh
     for submission in $submissionspath/files/*; do
       for cfile in $submission/*.c; do
         oldcfile=$pastsubmissionspath/${cfile#"$submissionspath"}
         if diff -q "$cfile"  "$oldcfile" ; then 
           echo $submission already processed; 
           #rm "$cfile"
           rm -rf "$submission"; 
         fi
       done
       #rm -d "$submission"; 
     done

     
     ( find $resultpath -type f   | sort | xargs sha1sum ) > $moodletmppath/resulthashs
     if ! diff $moodletmppath/resulthashs $moodletmppath/oldresulthashs;  then
       $DIR/results.sh;
       ( find $resultpath/failed -type f   | sort | xargs sha1sum ) > $moodletmppath/resultfailedhashs
       if ! diff $moodletmppath/resultfailedhashs $moodletmppath/oldresultfailedhashs;  then
         $DIR/submission-feedback.sh
       fi
       cp $moodletmppath/resulthashs $moodletmppath/oldresulthashs
       cp $moodletmppath/resultfailedhashs $moodletmppath/oldresultfailedhashs
     fi
     
    flock -u 100
  fi
  sleep 3600;
done

