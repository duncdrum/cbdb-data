xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xi="http://www.w3.org/2001/XInclude";

(:Aux.xql contains hyelper functions mostly for cleaning data and constructing functions.:)


declare function local:table-variables($f as node()*) as xs:string {

(:construct a variable declaration for each file in the collection:)
for $f in collection($global:src)
let $n := substring-after(base-uri($f), $global:src)
order by $n

return
     'declare variable' || ' $' || string($n) || ' := doc(concat($src, ' || "'" ||string($n) || "'));"
};


declare function local:write-chunk-includes($num as xs:integer?) as item()*{
(:This function inserts xinclude statemtns into the main TEI file for each chunk's list.xml file. 
As such $ipad, $num, and the return string depend on the main write operation in biographies.xql.
:)

for $i in 1 to $num
let $ipad := functx:pad-integer-to-length($i, 2)

return
    update insert
        <xi:include href="{concat('listPerson/chunk-', $ipad, '/list-', $i, '.xml')}" parse="xml"/>
    into doc(concat($global:target, $global:main))//tei:body
};

(:local:write-chunk-includes(37):)
