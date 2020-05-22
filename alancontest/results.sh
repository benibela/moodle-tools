#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"
source "$DIR/config.sh"

sed -Ee 's/([^§]*).*(gid=|files\/)([0-9]+).*/\3 \1/' $submissionspath/old* $submissionspath/new* |sort|uniq > $moodletmppath/usermap

export jsontaskresults


$xidel '<empty/>' --variable jsontaskresults,moodletmppath,resultpath -e '
  $usermap := {| file:read-text-lines($moodletmppath||"usermap")[normalize-space()] ! {substring-before(.," "): substring-after(.," ") } |},
  $tasks := jn:parse-json($jsontaskresults)'\
        --variable 'user,pass'  \
        'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})'  \
        '<empty/>' -f '$tasks()[. ne "0"] ! x"https://moodle.uni-luebeck.de/course/modedit.php?update={.}&return=0&sr=0"' \
        -f 'xquery version "3.0-xidel"; let 
 $id := extract($url, "update=([0-9]+)", 1), 
 $task := $tasks($id) 
 where file:exists($resultpath || $task)
 return 
 form((//form)[1], {"introeditor[text]": inner-xml(<p> <h3>Problem {$task}</h3> 
   <p>Die jeweils besten Speedups von neun Läufen auf Alan. </p>
   <table rules="all" style="text-align: right;" border="0">  { (
     <tr><td>Name</td> { (1 to 9) ! <td>{.}</td>  } <td>Median</td> </tr>,
     for $res in 
     for $file in file:list($resultpath || $task) ! tokenize(., $line-ending) 
     let $results := file:read-text-lines($resultpath|| $task||"/"||$file)
     return <tr><td>{$usermap($file)}</td>{
               ($results, (for $r in $results order by number($r) return $r)[ 5 ]) ! <td>{.}</td>                
            }</tr> 
     order by number($res/td[last()] ) descending return $res
   )}   </table> </p>) }) '  \
         'https://moodle.uni-luebeck.de/course/modedit.php?update='$failedresult'&return=0&sr=0' \
         -f 'xquery version "3.0-xidel"; form((//form)[1], {"introeditor[text]": join(("<h3>Hall of Fail</h3><p>Fehlgeschlagene Programme:</p>",
     let $task := "failed"
     for $file in file:list($resultpath || $task) ! tokenize(., $line-ending) [normalize-space()]
     return ("<h4>", $usermap($file), "</h4><pre>", file:read-text($resultpath|| $task||"/"||$file),"</pre>")
   )) } )
        ' -e //title
    
  

# ~/xidel  --xquery \
#  'let $usermap-lines := unparsed-text-lines("usermap")
#   for tumbling window $window in ("maximum_bench", 24510, "prefix_bench", ,  "pj_bench", 24515) start $foo when $foo instance of xs:string   
#   for $file in system("ls  ./results/" || $window[1]) ! tokenize(., $line-ending) 
#   let $results := unparsed-text-lines("results/"|| $window[1]||"/"||$file)
#   return <tr>{  ! <td>{.}</td> } </tr>'



