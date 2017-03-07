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
    
    for $node in $nodes/../*
(:    for $match in $nodes/../*:)
    
    
(:    where contains(local-name($node), local-name($match)):)
    return
    
       if (contains(local-name($node), 'year'))
       then (local-name($node))
       else ()
        
(:        switch(local-name($node))
            case 'c_dy' return concat('D', $global:DYNASTIES//no:c_dy[. = $node]/../no:c_sort)
            case  contains(local-name($node), '_year') return cal:isodate($node)
        default return ():)


};
let $test := $global:BIOG_MAIN//no:c_personid[. = 1]

for $n in $test 
return
    local:zh-dates($n)