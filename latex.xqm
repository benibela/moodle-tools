module namespace latex = "http://latex.benibela.de";

(: todo: check for \% :)
declare function latex:remove-comments($lines) {
  $lines ! replace(., "%.*", "")
};

(: todo: check for nested {} :)
declare function latex:command-from-lines($lines, $commandname){
  let $bscn := "\" || $commandname
  return
  for sliding window $line in $lines start $s when contains($s, $bscn) end $e when contains($e, "}") return (
    let $list := (substring-after($line[1], $bscn), tail($line))
    let $list := if (contains($list[1], "{")) then $list 
                 else for sliding window $w in $list start $s when contains($s, "{") end when false() return $w  
    let $list := (substring-after($list[1], "{"), tail($list))
    let $len := count($list)
    let $list := (subsequence($list, 1, $len - 1), substring-before($list[$len], "}"))
    return $list
  )
};

declare function latex:comma-list-from-lines($lines, $commandname){
  tokenize(join(latex:command-from-lines($lines, $commandname)), ",")!normalize-space()[.]
};

declare function latex:till-lecture-title-from-lines($lines){
  ($lines[contains(., "\lecturewithid")]!extract(., ".*[\\].*\{.*\}\{(.*)\}\{.*\}.*", 1))[1]
};

declare function latex:plaintext-from-lecture-slides($lines){
  $lines ! (
    . 
    => replace("\\item", "*")
    => replace("\\(begin|end)\{[a-zA-Z0-9 ]+\}(\[[^\]]+\])?|\\\\|\\[a-zA-Z]+(<[a-zA-Z0-9]+>)?|~", "")
    => replace("\{|\}|\$", "")
  )
};
  
declare function latex:sections-from-lecture-slides($lines){
  let $frames-and-sections := $lines[matches(., "\\(sub)?section|\\begin\{[a-zA-Z0-9 ]*frame|\\(begin|end)\{learning targets")]
  (:in till's lectures learnings count twice because they also insert TOC:)
  
  for tumbling window $frames-and-subsections in $frames-and-sections start when true() end next $e when contains($e, "\section") 
  let $head := head($frames-and-subsections)[contains(., "\section")]
  let $section := string($head) => replace("\\section\{|\}", "")
  let $frames-and-subsections := if (exists($head)) then tail($frames-and-subsections) else $frames-and-subsections
  
  for tumbling window $frames in $frames-and-subsections start when true() end next $e when contains($e, "\subsection") 
  let $head := head($frames)[contains(., "\subsection")]
  let $subsection := string($head) => replace("\\subsection\{|\}", "")
  let $frames := if (exists($head)) then tail($frames) else $frames
    
  return $frames ! ([ $section, $subsection, . ])
};


(:!extract(., "=([^,}]+)", 1)[.]:)
