#!/bin/bash
# Add something to a moodle course
# Input as environment variables and parameters
#   course
#   section
#   name
#   description
#   descriptionformat
#   $1            -> the thing to add
#                    e.g. label, url, etherpadlite, moodleoverflow
#   $2            -> additional options (url encoded or JSON)

thingtoadd=$1
options=$2

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

export name
export description
export descriptionformat
export options

moodle --variable name,description,descriptionformat,options                                            \
      "$baseurl/course/modedit.php?add=$thingtoadd&type=&course=$course&section=$section&return=0&sr=3" \
     -f 'moodle:modedit-form(/, $name, $description, $descriptionformat, $options)'                     \
     --download '/tmp/added/'  \
      -e '//*[starts-with(@id, "id_error")]!normalize-space()[.]' 

#echo debug
#echo $section
#echo $thingtoadd
#echo $options
