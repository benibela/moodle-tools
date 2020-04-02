#!/bin/bash
# Uploads a file to a moodle course. 
# Input as environment variables and parameters
#   course
#   section
#   name
#   description
#   folderid                if uploading to an existing folder
#   $1            -> filename

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

if [[ -z "$section" ]]; then export section=1; fi

export name
export description
export filename="$1"


if [[ -z "$folderid" ]]; then 
  if [[ -z "$course" ]]; then echo need course; exit; fi
  export course

  startpage="https://moodle.uni-luebeck.de/course/modedit.php?add=resource&type=&course=$course&section=$section&return=0&sr=0"
  finalconfirm='form(//form[contains(@action, "modedit")], {"name": $name, "introeditor[text]": $description})'
else 
  startpage="https://moodle.uni-luebeck.de/mod/folder/edit.php?id=$folderid"
  finalconfirm='form(//form[contains(@action, "folder/edit.php")])'
fi

moodle --variable course,name,description,filename,folderid \
       "$startpage" \
      -e 'finalconfirm := '"$finalconfirm" \
      -f '//noscript//object/@data[contains(., "env=filemanager")]' \
      -f '//a/@href[contains(., "filepicker")]'  \
      -f '//a[contains(., "hochladen")]'  \
      -f 'form(//form, {"repo_upload_file": {"file": $filename}})' \
      -f '$finalconfirm' \
      -e 'css("p.activity")[last()]' 


#      -f '//a/@href[not(starts-with(., "#"))]' \
