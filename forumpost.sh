#!/bin/bash
#Post message STDIN to forum $1
#$1 is the forum post id not the id from the forum view url. (look at the hidden input with name "forum" in the form code of the forum)
#options: 
#  $2             -> subject
#  $3             -> additional options (url encoded or JSON)
#  messageformat



DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

export forum=$1
export subject=$2
export message=$(cat)
export messageformat
export options=$3
 

moodle --variable forum,subject,message,messageformat,options \
   'https://moodle.uni-luebeck.de/mod/forum/post.php?forum='$forum                          \
   -f '
     let $form := //form[contains(@action, "post.php")],
         $options := moodle:prepend-uri-options($options, {"subject": $subject}),
         $request := moodle:modedit-form($form, (), $message, $messageformat, $options)
     return $request     
   ' -e 'css(".alert")'
   #--download - -e //title
   
