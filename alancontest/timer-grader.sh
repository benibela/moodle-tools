#!/bin/bash
#Start the grading process
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"
source "$DIR/config.sh"

mkdir -p $resultpath/failed
mkdir -p $pastsubmissionspath/files/

while true; do
  $DIR/grader.sh 
  sleep 1800;
done

