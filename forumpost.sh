#!/bin/bash
DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"
#Call it with message.sh forum id < text to post text. first line is title

export forum=$1
export message=$(cat)



moodle --variable forum,message \
   'https://moodle.uni-luebeck.de/mod/forum/post.php?forum='$forum                          \
   -f '
     let $form := //form[contains(@action, "post.php")],
         $message := x:lines($message),
         $subject := head($message),
         $message := tail($message),
         $has-options := matches($message[1], "\{.*\}"),
         $options := if ($has-options) then parse-json(head($message)) else (),
         $message := if ($has-options) then tail($message) else $message
     return form($form, map:merge(({"subject": $subject, "message[text]": join( $message, $line-ending) }, $options)))
   ' -e 'css(".alert")'
   #--download - -e //title
   