 #!/bin/bash
if [[ -z "$exercise" ]]; then echo need exercise; exit; fi
if [[ -z "$reviewnr" ]]; then echo need reviewnr; exit; fi

#basepath="$(dirname -- ${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]})"/../
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )/.."
source "$DIR/common.sh"


export exercise
export reviewnr
export DIR

$DIR/getsubmissions.sh 


~/xidel  --variable reviewnr,user,pass,exercise,titleprepend,DIR \
          -e 'xquery version "3.0-xidel"; 
            import module namespace utils="studenttopics" at "topiclib.xqm";
            
            for $submission in unparsed-text-lines("submissions/active"||$exercise)
            let $name := $submission!normalize-space(substring-before(.,"§"))
            let $filename := "submissions/files/" || extract($submission, "sid=(\d+)", 1) || "/onlinetext.html"
            let $reviewed := utils:get-reviewed("review" || $reviewnr, $name)
            let $messageto := utils:get-student-moodle-id($reviewed)
            return x"{$DIR}/message.sh {$messageto} ""Anonymes Review {$reviewnr}:<br><br> $(<""{$filename}"")"" "
            '  | while read r; do 
echo "$r";
eval "$r"; 
done
