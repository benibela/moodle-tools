

if [[ -z "$user" ]]; then export user=$(cat ~/.moodleuser); fi
if [[ -z "$user" ]]; then echo Need moodle \$user; exit; fi
if [[ -z "$pass" ]]; then export pass=$(cat ~/.moodlepass); fi
if [[ -z "$pass" ]]; then echo "Enter password for $user"; read -r pass; fi
export user
export pass
xidel=~/xidel

function moodle {
  $xidel --variable user,pass [ 'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' ] "$@"
}

function moodlewithcourse {
  if [[ -z "$course" ]]; then echo need course; exit; fi
  export course
  moodle --variable course "$@"
}

