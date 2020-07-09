#!/bin/bash
echo '# Moodle tools

Automate various teaching actions in the Moodle of the university of Lübeck.

Almost all scripts take these environment variables as input: 

    course   Course id
    section  Weekly section in the course 
    user     Username
    pass     Password

## Examples

Upload file "exercises.pdf" with title "Exercise Sheet":

    name="Exercise Sheet" description="Exercise Sheet" ./upload.sh exercises.pdf

Create a heading in a course:

    description="<h5>Some heading text</h5>" descriptionformat=html ./add.sh label showdescription=1

The examples assume the above environment variables have been set, so it knows in which course the content should be created.

## Installation

You only need bash and Xidel >= 0.9.9 installed. 

The scripts can then be called without installation.

## Available scripts

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
  return ("### " || $fn, "", head($info), "", tail($info) ! ("    " || .), "","") ' >> README.md
