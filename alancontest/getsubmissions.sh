#!/bin/bash
~/xidel  --variable 'user,pass' 'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   -f '(24720 to 24722, 25396 to 25397, 26050) ! x"https://moodle.uni-luebeck.de/mod/assign/view.php?id={.}&action=grading"'                               \
   -e 'for $user in //a[contains(@href, "assignsubmission_file")] return $user/ancestor::tr[1]/((.//a[contains(@href, "user/view")])[last()])/x"{extract($user/@href, "(([0-9]+)/[^/]+[.]c)([?].*)?$", 2)} {extract(@href, "id=([0-9]+)", 1)} {.}"' \
   -f '//a[contains(@href, "assignsubmission_file")]' --download  'submissions/{extract($url, "([0-9]+/[^/]+[.]c)([?].*)?$", 1)}' | tee -a usermap
 
mkdir -p submittedsubmissions

for submission in submissions/*; do
  if diff -q $submission/*.c  submitted$submission/*.c ; then echo $submission already processed; rm -rf $submission; fi
done

scp -i ~/.ssh/id_rsa_tcs -r submissions/ alan:~/contest
cp -r submissions/* submittedsubmissions
rm -rf submissions/*
