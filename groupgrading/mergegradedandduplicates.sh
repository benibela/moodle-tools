#!/bin/bash
#Create a "merged" subdirectory containing:
#  all files of the current directory
#  all files removed by moveduplicates.sh, but replaced by the file that has replaced the duplicate in the current dir (assuming all duplicates are named GROUP...-). 
xidel --xquery 'file:create-dir("merged"), 
                let $here := file:list("./")[file:is-file(.)] 
                let $duplicates := file:list("./duplicates") 
                for $h in $here 
                let $group := substring-before($h, "-") 
                return (file:copy($h, "merged/"), 
                        for $d in $duplicates 
                        let $group2 := substring-before($d, "-") 
                        where $group = $group2 
                        return file:copy($h, "merged/" || $d))'

rm merged.zip 2>/dev/null
zip merged.zip -r merged