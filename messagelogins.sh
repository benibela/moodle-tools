#!/bin/bash
#Message login data to multiple people

DIR=~/moodle
source $DIR/common.sh

if [[ -z "$course" ]]; then echo need course; exit; fi
export course

export baseuser=$1
export secretpass=$2

if [[ -z "$baseuser" ]]; then baseuser="user"; fi

((i=2));
while read -r e; do 
  ./message.sh $(grep -oE "[0-9]+" <<< $e) "Benutzername: $baseuser$i <br>Passwort: $secretpass "

  ((i=$i+1))
done
