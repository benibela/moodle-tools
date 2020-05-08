
MOODLEDIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"



if [[ -z "$user" ]]; then export user=$(cat ~/.moodleuser); fi
if [[ -z "$user" ]]; then echo Need moodle \$user; exit; fi
if [[ -z "$pass" ]]; then export pass=$(cat ~/.moodlepass); fi
if [[ -z "$pass" ]]; then echo "Enter password for $user"; read -r pass; fi
export user
export pass
xidel=~/xidel
export baseurl='https://moodle.uni-luebeck.de/'

function moodle {
  if test "`find ~/.moodlecookies -mmin -5`"; then
    $xidel --module $MOODLEDIR/moodle.xqm --variable user,pass,baseurl --load-cookies ~/.moodlecookies  "$@"
  else
    $xidel --variable user,pass,baseurl [ "$baseurl" -f 'form(//form, {"username": $user, "password": $pass})' -e '()' --save-cookies ~/.moodlecookies ] 
    moodle "$@"
  fi

}

function moodlewithcourse {
  if [[ -z "$course" ]]; then echo need course; exit; fi
  export course
  moodle --variable course "$@"
}

