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
  tokenize(join(latex:command-from-lines($lines, $commandname)), ",")!normalize-space()
};

declare function latex:till-lecture-title-from-lines($lines){
  ($lines[contains(., "\lecturewithid")]!extract(., ".*[\\].*\{.*\}\{(.*)\}\{.*\}.*", 1))[1]
};

(:!extract(., "=([^,}]+)", 1)[.]:)
