#!/bin/bash
#Input on stdin
#
#  keys to change  (in JSON/XQuery, without surrounding {})
#  urls to exercises
#
#important keys:
#
#"duedate", "allowsubmissionsfromdate", "cutoffdate"
#"assignsubmission_file_enabled": 1
#"sendnotifications":  0, 1
#
#------------------
#Example to shift exercises from one year to the next:
#"alldates": xs:dayTimeDuration("P364D"), 
#"assignsubmission_file_enabled": 1,
#"sendnotifications":  0
#
#https://moodle.uni-luebeck.de/course/modedit.php?update=112042&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112057&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112070&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112077&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112087&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112117&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112127&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112135&return=1
#https://moodle.uni-luebeck.de/course/modedit.php?update=112143&return=1
#
#----------------------


DIR="$( cd "$( dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")" )" && pwd )"
source "$DIR/common.sh"

input=$(cat)

export rawoptions=$(grep -v "^\s*http"  <<<"$input")

grep "^\s*http"   <<<"$input" | sed -Ee 's:mod/(vpl|assign)/view.php\?id=:course/modedit.php?update=:' | while read -r url; do
  moodle  --variable rawoptions "$url" -f ' 
    declare function local:get-date($r, $name) {
      let $params := $r?params
      let $y := $name||"[year]", $m := $name||"[month]", $d := $name || "[day]"
      return parse-date($params($y) || "-" || $params($m) || "-"|| $params($d), "yyyy-m-d" )
    };
    declare function local:set-date-values($name, $date) {
      { $name || "[year]": year-from-date($date),
        $name || "[month]": month-from-date($date),
        $name || "[day]": day-from-date($date)
      }
    };
    let $possibledates := ("duedate", 
                           "allowsubmissionsfromdate", "cutoffdate",
                           "startdate")
    let $options := if (matches($rawoptions, "^\s*(map\s*)?\{")) then $rawoptions else " map{"||$rawoptions||"}"
    let $options := eval($options, {"language":"xquery3.1"})
    let $f := //form[contains(@action, "modedit")]
    let $r := form($f)
    let $rd := request-decode($r)
    return request-combine($r, 
      map:for-each($options, function($basekey, $value){
        for $key at $i in if ($basekey = "alldates") then $possibledates else $basekey return
        typeswitch ($value)
          case xs:dayTimeDuration|xs:yearMonthDuration return 
            if ($i eq 1 or exists($rd("params")($key||"[year]"))) then
              local:set-date-values($key, local:get-date($rd, $key) + $value)
            else
              ()
          case xs:dateTime|xs:date return local:set-date-values($key, $value)
          default return if ($key = $possibledates ) then local:set-date-values($key, xs:date($value))
          else {$key:$value}
      })
    )
    ' -e '//title' -e 'span.error' -e '//*[contains(@id, "error")]!normalize-space()[.]' 
    
    #--download /tmp/test.html
done

exit




789 10
einführung bio informatik
einführung programmierung












xs:date("2017-12-15")+xs:dayTimeDuration("P364D")'






allowsubmissionsfromdate

"assignsubmission_file_enabled": 1,
"cutoffdate[hour]":  23
"cutoffdate[minute]": 55


