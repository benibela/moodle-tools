#!/bin/bash
echo '# Moodle tools

Automate various teaching actions in the Moodle of the university of Lübeck.

Almost all scripts take these environment variables as input: 

    course   Course id
    section  Weekly section in the course 
    user     Username
    pass     Password

' > README.md

xidel -s --xquery '
  for $fn in sort((file:list("."), file:list("groupgrading")!("groupgrading/"||.))) 
  where ends-with($fn, ".sh") 
  let $file := tail(file:read-text-lines($fn)) 
  let $info := for sliding window $w in $file 
               start at $i when $i eq 1 
               end next $n when not(starts-with($n, "#")) 
               return $w 
  let $info := $info ! replace(., "^ *#", "")
  return ("## " || $fn, "", head($info), "", tail($info) ! ("    " || .), "","") ' >> README.md
