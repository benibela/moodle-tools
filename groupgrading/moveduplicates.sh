#!/bin/bash
#Move duplicated files in the current directory to a "duplicates" subdirectory
xidel --xquery 'file:create-dir("duplicates"), 
                for $f in file:list(.) group by $group := substring-before($f, "-") || file:size($f) for $t in tail($f) 
                return file:move($t, "duplicates/"|| $t)'