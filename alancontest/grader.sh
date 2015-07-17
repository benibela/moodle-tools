#!/bin/bash
CURPATH=$PWD
RESULTS=$CURPATH/results
for submission in $(find submissions/ | grep "[.]c"); do 
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
  cp submissions/$ID/${TASK}_par.c grading
  cd grading
  make $TASK 2>&1 | tee compilemessages
  if [[ -e ./$TASK ]]; then
    mkdir -p $RESULTS/$TASK
    touch $RESULTS/$TASK/$ID
    for run in {1..9}; do
      ./$TASK  | tail -1 |  awk '{print $5}' | tee -a $RESULTS/$TASK/$ID
    done;
  else 
    mkdir -p $RESULTS/failed
    echo "compilation failed" > $RESULTS/failed/$ID
    cat compilemessages >> $RESULTS/failed/$ID
  fi
  cd $CURPATH
  rm -rf submissions/$ID
  #if [[ "$ID" -e "prefix_bench_par" ]]; then 
  #exit
done
