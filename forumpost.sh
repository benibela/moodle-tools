#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"
#Call it with message.sh forum id < text to post text. first line is title

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
   
