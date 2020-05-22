#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/config.sh"

exec 100>$lockfile || exit 1
if ! flock -w 3600 100; then echo locked; exit 1; fi



RESULTS=$resultpath
for submission in $(find $submissionspath/files | grep "[.]c"); do 
  [[ $submission =~ ([0-9]+)/([^.]*)(_par.c)? ]]
  ID=${BASH_REMATCH[1]}
  TASK=${BASH_REMATCH[2]}
  oldcfile=$pastsubmissionspath/${submission#"$submissionspath"}
  if diff -q "$submission"  "$oldcfile" ; then
    echo $submission already processed
    continue
  fi
  echo ----------------- Processing: $ID for $TASK -----------------------
  rm $RESULTS/*/$ID 2>/dev/null
  if [[ "${BASH_REMATCH[3]}" != "_par.c" ]]; then 
    mkdir -p $RESULTS/failed
    echo "failed: invalid filename: ${BASH_REMATCH[*]}" | tee $RESULTS/failed/$ID
  else
    rm -rf $gradingpath/
    mkdir $gradingpath
    cd $contestfilespath
    cp benchmarker.c  Makefile ${TASK}_generate.c ${TASK}_seq.c $gradingpath/
    cp $submissionspath/files/$ID/${TASK}_par.c $gradingpath/
    cd $gradingpath/
    make $TASK 2>&1 | tee compilemessages
    if [[ -e ./$TASK ]]; then
      mkdir -p $RESULTS/$TASK
      for run in {1..9}; do
        if timeout -k 15m 10m ./$TASK > log 2> errlog; then 
          tail -1 log |  awk '{print $5}' | tee -a $RESULTS/$TASK/$ID
        else
          if [[ $? -eq 124 ]]; then 
            tail log > $RESULTS/failed/$ID
            echo "TIMEOUT (> 10 min)" | tee -a $RESULTS/failed/$ID;
          else
            cp log $RESULTS/failed/$ID
          fi
  	      cat errlog >> $RESULTS/failed/$ID
          break
        fi
      done;
    else 
      echo "compilation failed" > $RESULTS/failed/$ID
      cat compilemessages >> $RESULTS/failed/$ID
    fi
  fi
  cp -r $submissionspath/files/$ID $pastsubmissionspath/files/
done
