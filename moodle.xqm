module namespace moodle = "http://moodle.benibela.de";

declare function moodle:modedit-form($root, $options){
  $root/(
  head(//form)/form(., ( .//input[@name="submitbutton"], $options!(typeswitch(.)
    case xs:string return 
      if (starts-with(., "{")) then parse-json(.) 
      else .
    default return .
  ) ))
  )
};

declare function moodle:modedit-form($root, $name, $description, $descriptionformat, $options){
  let $editor := let $textareas := $root//textarea/@name return if ($textareas = "summary_editor[text]") then "summary_editor" else "introeditor" 
  return
  moodle:modedit-form($root, ({
    "name" ?: $name[.], 
    $editor || "[text]": $description, 
    $editor || "[format]": switch ($descriptionformat)
      case "html" return 1
      case "moodle" return 0
      case "text" return 2
      case "markdown" return 4
      default return 2    
  }, $options
  ))
};

declare function moodle:prepend-uri-options($options, $prepend){
  if (starts-with($options, "{")) then serialize-json(map:merge(($prepend, parse-json( $options ))))
  else string-join( ( map:keys($prepend)!(encode-for-uri(.) || "=" || encode-for-uri( $prepend(.)) ) , $options[.] ), x:cps(38) )

};

declare function moodle:course-edit-follow($root){
  $root//form[.//input[@name="edit" and @value="on"]]
};
