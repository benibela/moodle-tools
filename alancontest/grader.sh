#!/bin/bash
CURPATH=$PWD
RESULTS=$CURPATH/results
mkdir -p $RESULTS/failed
for submission in $(find submissions/files | grep "[.]c"); do 
  [[ $submission =~ ([0-9]+)/([^.]*)(_par.c)? ]]
  ID=${BASH_REMATCH[1]}
  TASK=${BASH_REMATCH[2]}
  echo ----------------- Processing: $ID for $TASK -----------------------
  rm results/*/$ID 2>/dev/null
  if [[ "${BASH_REMATCH[3]}" != "_par.c" ]]; then 
    mkdir -p $RESULTS/failed
    echo "failed: invalid filename: ${BASH_REMATCH[*]}" | tee $RESULTS/failed/$ID
    continue;
  fi
  rm -rf grading/
  mkdir grading
  cp files/benchmarker.c  files/Makefile files/${TASK}_generate.c files/${TASK}_seq.c grading/
  cp submissions/files/$ID/${TASK}_par.c grading
  cd grading
  make $TASK 2>&1 | tee compilemessages
  if [[ -e ./$TASK ]]; then
    mkdir -p $RESULTS/$TASK
    for run in {1..9}; do
      if timeout -k 15m 10m ./$TASK > log; then 
        tail -1 log |  awk '{print $5}' | tee -a $RESULTS/$TASK/$ID
      else
        if [[ $? -eq 124 ]]; then 
          tail log > $RESULTS/failed/$ID
          echo "TIMEOUT (> 10 min)" | tee -a $RESULTS/failed/$ID;
        else
          cp log $RESULTS/failed/$ID
        fi
        break
      fi
    done;
  else 
    echo "compilation failed" > $RESULTS/failed/$ID
    cat compilemessages >> $RESULTS/failed/$ID
  fi
  cd $CURPATH
done
