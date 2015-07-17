#!/bin/bash
echo Moodle user:
read -r user
export user
echo Pass:
read -r pass
export pass
while true; do
./getsubmissions.sh
sleep 600;
scp -i ~/.ssh/id_rsa_tcs -r alan:~/contest/results .
( find ./results -type f   | sort | xargs sha1sum ) > resulthashs
if ! diff resulthashs oldresulthashs;  then
  ./results.sh;
  cp resulthashs oldresulthashs
fi
  sleep 3600;
done

