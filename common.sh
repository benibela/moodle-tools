

if [[ -z "$user" ]]; then export user=$(cat ~/.moodleuser); fi
if [[ -z "$user" ]]; then echo Need moodle \$user; exit; fi
if [[ -z "$pass" ]]; then export pass=$(cat ~/.moodlepass); fi
if [[ -z "$pass" ]]; then echo "Enter password for $user"; read -r pass; fi
#export course
export user
export pass
xidel=~/xidel