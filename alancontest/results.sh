#!/bin/bash



cp usermap /tmp
sort < /tmp/usermap | uniq > usermap

~/xidel '<empty/>' -e '$usermap := {| unparsed-text-lines("usermap")[normalize-space()] ! {substring-before(.," "): substring-after(substring-after(.," "), " ")} |} ' \
        --variable 'user,pass'  \
        'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})'  \
        '<empty/>' -f '(24510,24514,24515,25398,25399,26051) ! x"https://moodle.uni-luebeck.de/course/modedit.php?update={.}&return=0&sr=0"' \
        -f 'xquery version "3.0"; let 
 $id := extract($url, "update=([0-9]+)", 1), 
 $task := {"24510": "maximum_bench", "24514": "prefix_bench", "24515": "pj_bench", "25398": "sort_bench", "25399": "lenz_bench", "26051": "lr_bench"}($id) return 
 form((//form)[1], {"introeditor[text]": inner-xml(<p> <h3>Problem {$task}</h3> 
   <p>Die jeweils besten Speedups von neun Läufen auf Alan. </p>
   <table rules="all" style="text-align: right;" border="0">  { (
     <tr><td>Name</td> { (1 to 9) ! <td>{.}</td>  } <td>Median</td> </tr>,
     for $res in 
     for $file in system("ls  ./results/" || $task) ! tokenize(., $line-ending) 
     let $results := unparsed-text-lines("file://./results/"|| $task||"/"||$file)
     return <tr><td>{$usermap($file)}</td>{
               ($results, (for $r in $results order by number($r) return $r)[ 5 ]) ! <td>{.}</td>                
            }</tr> 
     order by number($res/td[last()] ) descending return $res
   )}   </table> </p>) }) '  \
         'https://moodle.uni-luebeck.de/course/modedit.php?update=25266&return=0&sr=0' \
         -f 'xquery version "3.0"; form((//form)[1], {"introeditor[text]": join(("<h3>Hall of Fail</h3><p>Fehlgeschlagene Programme:</p>",
     let $task := "failed"
     for $file in system("ls  ./results/" || $task) ! tokenize(., $line-ending) 
     return ($usermap($file), unparsed-text("file://./results/"|| $task||"/"||$file))
   )) } )
        ' 
    
  

# ~/xidel  --xquery \
#  'let $usermap-lines := unparsed-text-lines("usermap")
#   for tumbling window $window in ("maximum_bench", 24510, "prefix_bench", ,  "pj_bench", 24515) start $foo when $foo instance of xs:string   
#   for $file in system("ls  ./results/" || $window[1]) ! tokenize(., $line-ending) 
#   let $results := unparsed-text-lines("results/"|| $window[1]||"/"||$file)
#   return <tr>{  ! <td>{.}</td> } </tr>'



