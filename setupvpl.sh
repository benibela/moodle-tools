#!/bin/bash
# Creates or changes a VPL. 
# Input as environment variables and parameters
#   course
#   section
#   name
#   description
#   $1            -> filename

DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

configfile=$1

export id
export configfile

if [[ -z "$id" ]]; then 
  export course
  export section
  export name
  export description
  export points
  eval "$($xidel --output-format bash --variable configfile -e 'let $config := doc("file:///"||$configfile) return $config!($defaulttitle := /vpl/@name, $defaultpoints := /vpl/@points)')"
  export defaulttitle
  export defaultpoints
  #echo $defaulttitle ::: $defaultpoints
  moodle --variable course,section,name,description,points,configfile,defaulttitle,defaultpoints \
    [ 'https://moodle.uni-luebeck.de/course/modedit.php?add=vpl&type=&course={$course}&section={$section}&return=0&sr=0' \
     -f 'head(//form)/form(., ({
       "name": $name || " " || $defaulttitle, 
       "introeditor[text]": $description, 
       "duedate[enabled]": "",
       "grade[modgrade_point]": ($points,$defaultpoints,"100")[.][1] }, .//input[@name="submitbutton"]))' -e '()' ]
       #
       #
       #"duedate[day]": $sdeadline[1], 
       #"duedate[month]": $sdeadline[2], 
       #"duedate[year]": $sdeadline[3], 
       #"duedate[hour]":  $hour, 
       #
       #
       #
  export id=$(moodle --variable name,defaulttitle 'https://moodle.uni-luebeck.de/course/view.php?id='$course -e 'max(css("li.vpl")//a[contains(@href, "view.php") and starts-with(normalize-space(),  $name || " " || $defaulttitle)]/request-decode(@href)?params?id)')
fi


 


$xidel --variable user,pass,id,configfile --extract-exclude=config --verbose -e '
  $config := doc("file:///"||$configfile)/vpl, 
  $basedon := $config/basedon,
  $serialize-files := function($f) { serialize-json({"files": array{ $f!{"name": @name!string(), "contents": string(), "encoding": 0} } }) } 
  ' \
  'https://moodle.uni-luebeck.de/' -f 'form(//form, {"username": $user, "password": $pass})' \
  'https://moodle.uni-luebeck.de/mod/vpl/forms/executionoptions.php?id={$id}' -f '//form/form(., ({
    "basedon": head(.//option[. = $basedon]/@value),
    "run": 1,
    "debug": 1,
    "evaluate": 1,
    "automaticgrading": 1
  }, head(.//input[@type="submit"])))' \
  -f '{"url": x"https://moodle.uni-luebeck.de/mod/vpl/forms/requiredfiles.json.php?id={$id}&action=save", "post": $serialize-files($config/requiredfiles/file)}'  \
  -f '{"url": x"https://moodle.uni-luebeck.de/mod/vpl/forms/executionfiles.json.php?id={$id}&action=save", "post": $serialize-files($config/executionfiles/file)}' \
  -e '()'

#old moodle:
#  -f '{"url": x"https://moodle.uni-luebeck.de/mod/vpl/forms/requiredfiles.json.php?id={$id}&action=save", "post": serialize-json({|$config/requiredfiles/file!{@name: string()}|})}'  \
#  -f '{"url": x"https://moodle.uni-luebeck.de/mod/vpl/forms/executionfiles.json.php?id={$id}&action=save", "post": serialize-json({|$config/executionfiles/file!{@name: string()}|})}'  


#  --post '{{"test":""}}' '' 
  #
  
#  --post '{"vpl_run.sh":"","vpl_debug.sh":"","vpl_evaluate.sh":"","vpl_evaluate.cases":""}' 'https://moodle.uni-luebeck.de/mod/vpl/forms/executionfiles.json.php?id={$id}&action=save' 
  

