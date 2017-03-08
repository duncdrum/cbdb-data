xquery version "3.1";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog="http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";
import module namespace org="http://exist-db.org/apps/cbdb-data/institutions" at "institutions.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:~
 This file imports all modules present in the database for easy testing. 
:)

(:
How little input can we give this to still function, and how much do i need to make it usable in any cases where there are dates. 
What is the best form for the output date element, or string to be used in values
Can the function determine when/notBefore/... based on switch
Should the date element alwys have @when?
:)

declare 
    function local:zh-dates ($nodes as item()*) as item()* {
    
(:~ 
 1. we need to match the nodes that stand in a relation like: c_by_nh_code, c_by_nh_year, c_by_intercalary
 2. we test the matches if they end in nh_code, nh_year, gz_... and filter empties
 3. process the filtered matches to output the normalised date string
 
:) 

(:
_range
_year
    _yr
year
_month
_day
_dy
_nh_year            ---> do nh_year first so that remaining years are easier to catch
    _nh_yr
_nh_code
_day_gz
    _day_ganzhi

_intercalary

_date (SQL)

:)

(:
switch ($range)
    case ('-1') return attribute notAfter {$date}
    case ('1') return attribute notBefore {$date}
    case ('2') return (attribute when {$date}, attribute cert {'medium'})
    case ('300') return (attribute from {'0960'}, attribute to {'1082'})
    case ('301') return (attribute from {'1082'}, attribute to {'1279'})
default return attribute when {$date} 
:)

(: First, we find all the date related nodes from a given row...:)
for $node in $nodes/../*
let $name := local-name($node)
let $suffix := ('_dy', ('_nh_year', '_nh_yr'), '_nh_code', ('_day_gz', '_day_ganzhi'), '_range', ('_year', '_yr', 'year'), '_month', '_day', '_intercalary', '_date')

let $match :=  map:new (    
        for $n at $pos in $suffix
        return
            if (ends-with($name, $n))
            then (map:entry($name, $pos))
            else())            
(: and  apply preprocessing to generate properly formated items to work with.:)
return
    switch($match($name))
        case 1 return concat('D', $global:DYNASTIES//no:c_dy[. = $node]/../no:sort)
        case 2 case 3 return $node/text()
        case 4 return concat('R', count($cal:path/category[@xml:id = concat('R', $node/text())]/preceding-sibling::category) +1)
        case 5 case 6 return 'GZ'
        case 7 return 
            switch($node/text())
                case ('-1') return attribute notAfter {$node}
                case ('1') return attribute notBefore {$node}
                case ('2') return (attribute when {$node}, attribute cert {'medium'})
                case ('300') return (attribute from {'0960'}, attribute to {'1082'})
                case ('301') return (attribute from {'1082'}, attribute to {'1279'})
            default return attribute when {$node} 
        case 8 case 9 case 10 return cal:isodate($node)
        case 11 case 12 return functx:pad-integer-to-length($node, 2)         
        case 13 return  'i'                       
        case 14 return cal:sqldate($node)       
    default return ()
    
(: Second, form group of nodes that belong together. 
If YYYY,  MM and DD tend to have a different $prefix
If D, R and Y (and GZ) tend to have a different $prefix
'i' always applies to?
'range is its own beast'
:)



(: then, check if the date is complete, ie. no YYYY-uu-DD.
    D can come from NH table.:)



};
let $test := $global:BIOG_MAIN//no:c_personid[. = 1]


for $n in $test
return    
    local:zh-dates($n)

    
(:    return
        distinct-values(local-name($all/*)):)