#!/bin/bash
# Hides activities with caption "Vorlesungsfolien"
# Input as environment variables
#   course

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

$DIR/hideactivities.sh "Vorlesungsfolien"

