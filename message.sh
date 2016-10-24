#!/bin/bash
#Call it with message.sh userid "message" to send a message to someone

export user2=$1
export message=$2

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"



~/xidel --variable user,pass,user2,message \
   'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
   -e 'user1 := (//a[contains(@href, "profile.php")])[1]/extract(@href, "id=([^&]+)", 1)'     \
   -e 'user2 := $user2'                                                                       \
   -f 'x"https://moodle.uni-luebeck.de/message/index.php?user1={$user1}&user2={$user2}"'      \
   -f 'form((//form)[last()], {"message": $message})'                                         \
   -e 'span.text'