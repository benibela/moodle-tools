module namespace moodle = "http://moodle.benibela.de";

declare function moodle:modedit-form($root, $options){
  $root/(
    head(//form)/moodle:form(., $options) 
  )
};

declare function moodle:form($form, $options){
  $form ! form(., ( .//input[@name="submitbutton"], moodle:unserialize-form-options($options) ) )
};

declare function moodle:unserialize-form-options($options){
  $options!(typeswitch(.)
    case xs:string return 
      if (starts-with(., "{")) then parse-json(.) 
      else .
    default return .
  ) 
};

declare function moodle:modedit-form($root, $name, $description, $descriptionformat, $options){
  let $editor := let $names := $root//textarea/@name
                 return if ($names = "summary_editor[text]") then "summary_editor" 
                   else if ($names = "message[text]") then "message" 
                   else "introeditor" 
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
  ($root//form[.//input[@name="edit" and @value="on"]], $root/base-uri())[1]
  
};
