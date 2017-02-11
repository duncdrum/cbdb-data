xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:Aux.xql contains helper functions mostly for cleaning data and constructing functions.:)


declare function local:table-variables($f as node()*) as xs:string {

(:construct a variable declaration for each file in the collection:)
for $f in collection($global:src)
let $n := substring-after(base-uri($f), $global:src)
order by $n

return
     'declare variable' || ' $' || string($n) || ' := doc(concat($src, ' || "'" ||string($n) || "'));"
};

declare function local:write-chunk-includes($num as xs:integer?) as item()*{
(:This function inserts xinclude statements into the main TEI file for each chunk's list.xml file. 
As such $ipad, $num, and the return string depend on the main write operation in biographies.xql.
:)

for $i in 1 to $num
let $ipad := functx:pad-integer-to-length($i, 2)

return
    update insert
        <xi:include href="{concat('listPerson/chunk-', $ipad, '/list-', $i, '.xml')}" parse="xml"/>
    into doc(concat($global:target, $global:main))//body
};
(:local:write-chunk-includes(37):)

(: !!! WARNING !!! Hands off if you are not sure what you are doing !!!! :)
declare function local:upgrade-contents($nodes as node()*) as node()* {

(: This function performs an inplace update off all person records. 
It expects $global:BIOG_MAIN//no:c_personid s. 
It is handy for patching large number of records. 
Using the structural index in the return clause is crucial for performance.
:)

for $n in $nodes
return
 update value collection(concat($global:target, 'listPerson/'))//person[id(concat('BIO', $n))] 
 with biog:biog($n, '')/*

(:update value doc('/db/apps/cbdb-data/samples/test.xml')//listPlace with biog:biog($n, '')/*:)

};
(:local:upgrade-contents($global:BIOG_MAIN//no:c_personid[. > 0][. < 2]):)


(:from biog:biog:)
let $test := $global:BIOG_MAIN//no:c_personid[. = 139680]
let $errors := (11786, 20888, 43665, 12353, 22175, 44821, 12908, 23652, 44891, 139017, 24130,
44894, 139018, 24915, 45204, 139042, 25089, 45221, 139446, 27474, 45399, 139447,
37934, 45409, 139503, 38061, 45641, 139680, 38248, 49513, 17236, 38450, 50730,
18663, 38594, 8001, 2074, 38825)
 

(:return
 $test/..:)
 
for $person in $errors
return
biog:biog($global:BIOG_MAIN//no:c_personid[. = $person], 'v')

(:$global:BIOG_ADDR_DATA//no:c_personid[. = 139680]:)

(:for $person in $test
return:)
(:update  value $person/../no:c_fy_day with 28:)

(:biog:biog($person, 'v'):)

(:let $birth-test :=


for $person in $birth-test//no:c_personid[. = 24130]
return

element birth { 
    if (empty($person/../no:c_deathyear) or $person/../no:c_deathyear[. = 0])
    then ()
    else (
        attribute when {string-join((cal:isodate($person/../no:c_deathyear),
            if ($person/../no:c_dy_month[. > 0])
            then (functx:pad-integer-to-length($person/../no:c_dy_month/text(), 2),
                if (empty($person/../no:c_dy_day) or $person/../no:c_dy_day = 0)
                then ()
                else (functx:pad-integer-to-length($person/../no:c_dy_day/text(), 2))
            )            
            else ()), '-')}
            ) 
            }:)
            
            
            
