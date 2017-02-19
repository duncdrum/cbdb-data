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
let $test := $global:BIOG_MAIN//no:c_personid[. = 198040]
(:The following records contained validation errors on 2nd run 
<ref target="https://github.com/duncdrum/cbdb-data/commit/1646a678201ae634dd746c25e34a361b221f3ab0"/>:)
let $errors := (2074, 8001, 11786, 12353, 12908, 17236, 18663, 20888, 22175, 
23652, 24130, 24915, 25089, 27474, 37934, 38061, 38248, 38450, 38594, 38825, 
43665, 44821, 44891, 44894, 45204, 45221, 45399, 45409, 45641, 49513, 50730, 
139017, 139018, 139042, 139446, 139447, 139503, 139680, 198040, 198892, 
199880, 200696, 201124, 201125, 201321, 202090, 202224, 202650, 203229, 
203454, 203625, 203845, 203989, 204202, 204270, 204798, 205142, 205345, 
205770, 206011, 206050, 206715, 206933, 206972, 207151, 207543, 207576, 
207881)

 

(:return
 $test/..:)



for $person in $errors
let $file-name := concat('cbdb-', 
    functx:pad-integer-to-length($person, 7), '.xml')
return
xmldb:store($global:patch, $file-name, 
biog:biog($global:BIOG_MAIN//no:c_personid[. = $person], ''))


(:for $person in $global:BIOG_MAIN//no:c_personid[. = 207881]
return
update  value $person/../no:c_by_day with 28:)

(:biog:biog($person, ''):)


(:for $person in $global:BIOG_MAIN//no:c_personid[. = 371243]
let $ethnicity := $global:ETHNICITY_TRIBE_CODES//no:c_ethnicity_code[. = $person/../no:c_ethnicity_code]
return

if ($person/../no:c_ethnicity_code > 0) 
then (<trait type="ethnicity" key="{$ethnicity/../no:c_group_code/text()}">
        {for $n in $ethnicity/../*
        return
         typeswitch ($n)
             case element (no:c_ethno_legal_cat) return element label {$n/text()}
             case element (no:c_name_chn) return element desc { attribute xml:lang {'zh-Hant'}, $n/text()}
             case element (no:c_name) return element desc { attribute xml:lang {'zh-Latn-alalc97'}, $n/text()}
             case element (no:c_romanized) return element desc { attribute xml:lang {'en'}, $n/text()}
             case element (no:c_notes) return element note {$n/text()}
         default return ()}
       </trait>)
else():)
            
            
            
