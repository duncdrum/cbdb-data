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


declare function pla:merge-place-dupes ($places as node()*) as item()*{
(:this function takes the place nodes to be merged and writes them into an aux file:)
let $dupes := xmldb:store($global:target, 'place-lookup.xml',
    <listPlace>
        {for $place in $global:ADDRESSES//c_addr_id
         where count($global:ADDRESSES//c_addr_id[. = $place]) > 1
         return
            pla:address($place)}
    </listPlace>)
    
let $dedupes :=  <listPlace>
                        {for $dupe in $dupes/listPlace/place
                        let $id := data($dupe/@xml:id)                 
                        return
                            <place xml:id="{data($dupe/@xml:id)}">
                                {functx:distinct-deep($dupes//place[@xml:id = $id]/*)}
                            </place>}
                     </listPlace>

return
    xmldb:store($global:target, 'place-dupe.xml',
    <tei:listPLace>{functx:distinct-deep($dedupes//place)}</tei:listPLace>)
};

declare function pla:update-listPlace (){    

let $listPlace := doc(concat($global:target, $global:place))
let $dedupe := doc(concat($global:target, 'place-dedupe.xml'))

(:

dimitri's solution 
http://stackoverflow.com/questions/3875560/xquery-finding-duplciate-ids?rq=1

delete all dupes but the first

let $vSeq := $listPlace//tei:place[@xml:id = data($dedupe//tei:place/@xml:id)]
return
    update delete $vSeq[position() = index-of($vSeq, .)[. > 1]] 
    
    :)
    
let $vSeq := $listPlace//tei:place[@xml:id = data($dedupe//tei:place/@xml:id)]

for $n in $vSeq
let $m := $dedupe//tei:place[@xml:id = data($n/@xml:id)]



return
    (update delete $vSeq[position() = index-of($vSeq, .)[. > 1]] ), (update replace $n with $m)
    };
    
    for $i in 1 to 10
    return 
    $i