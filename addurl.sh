#!/bin/bash
# Adds a link to $1
# Input as environment variables and parameters
#   course
#   section
#   name
#   description
#   descriptionformat
#   $1            -> link target
#   $2            -> additional options (url encoded or JSON)

export externalurl="$1"
export options="$2"

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source $DIR/common.sh


$DIR/add.sh url "$($xidel --variable externalurl,options --module $MOODLEDIR/moodle.xqm -e 'moodle:prepend-uri-options($options, {"externalurl": $externalurl})')"

