#!/bin/bash
cache=~/semesterdatescache

if [[ -z $xidel ]]; then xidel=~/xidel; fi

mkdir -p $cache
export year=$(date +%Y)

for y in $(seq $year $((year+1))); do 
  if [[ ! -s $cache/holidays$y ]]; then
    $xidel "https://ipty.de/feiertag/api.php?do=getFeiertage&loc=SH&jahr=$y" --input-format json -e 'let $j := $json() return {
      "dates": $j?date!parse-date(.), 
      "titles": $j?title, 
      "combined": $j!{"date": parse-date(?date), "title": ?title} }' > $cache/holidays$y
  fi
done
if [[ ! -s $cache/semester$year ]]; then
  $xidel "https://www.uni-luebeck.de/?id=80" --variable year -e '
    <html>
      <title>Vorlesungszeiten</title>
      <h6>Termine</h6>
      <h1>Vorlesungszeiten</h1>
      <p t:condition="starts-with(normalize-space(), &quot;Sommersemester &quot;||$year )">{$ss}</p>
      <p t:condition="starts-with(normalize-space(), &quot;Wintersemester &quot;||$year )">{$ws}</p>
      <p t:condition="starts-with(normalize-space(), &quot;Weihnachtsfrei&quot; )">{$xmas}</p>
    </html>
  ' --output-format json-wrapped | $xidel - --input-format json --variable year -e '
    let $ss := $json//ss,
        $ws := $json//ws,
        $xmas := $json//xmas,
        $parse := function($l) { let $s := tokenize(replace($l, ".*frei|.*semester *[0-9/]+|"||x:cps(160), ""), "-") return {"start": parse-date($s[1]), "end": parse-date($s[2])} }
    return 
    {
      ("ss") : { 
        "start": xs:date($year||"-04-01"),
        "end": xs:date($year||"-09-30"),
        "lectures": $parse($ss)
      },
      ("ws") : { 
        "start": xs:date($year||"-10-01"),
        "end": xs:date(($year+1)||"-03-31"),
        "lectures": $parse($ws),
        "xmas": $parse($xmas)
      }
    }
  ' > $cache/semester$year
fi
