xquery version "3.1";

(:~
: Temporary working module.
: Replace local with name of target module
:
: @author Duncan Paterson
: @version 0.8.0
:)
import module namespace functx = "http://www.functx.com";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace dbutil = "http://exist-db.org/xquery/dbutil"; 

(:import module namespace global = "http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
:)
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";


declare variable $test := element root {
    for $i in 1 to 50
    return
        element item {
            attribute xml:id {'i' || $i},
            $i
        }
};

(:~ 
 : determine the required padding length for a sequence of ints
 : @param $num onn or more integers
 : @return integer
 :)
declare function local:pad($num as xs:integer*) as xs:integer {
    let $max := max($num) cast as xs:string
    return
        string-length($max) + 1
};

declare function local:transform($items as item()*, $validation as xs:string) as item()* {
    <TEI>
        <body>
            <text>{
                    typeswitch ($items)
                        case element(item)
                            return
                                <person>{$items/text()}</person>
                        default
                            return
                                ()
                }
            </text>
        </body>
    </TEI>
};

(:~ 
 : This function ensures that individual records 
 : are written to a three deep nested collection hierarchy.
 : TODO switch to xml:id ? 
 : TODO test function call
 : TODO let $info := util:log('info', 'Successfully created ' || $sum || ' nested collections for ' || $count ||
    ' items. ' || $l2-count || ' chunks contain ' || $l3-sum || ' blocks each.')
 :
 : @param $nodes the items to be transformed
 : @param $parent-name of the top level directory name e.g. listPerson, listPlace, …
 : @param $items-per-chunk number of records per l2 collection (chunk)
 : @param $items-per-block number of records per l3 collection (block)
 : @param $f the transformation function that generates TEI
 :
 : @return individual records stored in dynamically generated collection tree 
 :)
declare function local:write-and-split ($nodes as item()*,
$parent-name as xs:string, 
$items-per-chunk as xs:positiveInteger, 
$items-per-block as xs:positiveInteger,
$transform as function(*)) as item()* {

let $count := count($nodes)
let $chunk-pad := local:pad($count idiv $items-per-chunk)
let $block-pad := local:pad($count idiv $items-per-block)
let $file-pad := local:pad($count)

for $n at $pos in $nodes
(: +1 avoids '/chunk-00' paths :)
let $chunk-name := $parent-name || '/chunk-' || functx:pad-integer-to-length($pos idiv $items-per-chunk + 1, $chunk-pad)
let $block-name := $chunk-name || '/block-' || functx:pad-integer-to-length($pos idiv $items-per-block + 1, $block-pad)

order by $pos
        
let $file-name := 'item-' || functx:pad-integer-to-length($pos, $file-pad) || '.xml'
return
    xmldb:store(xmldb:create-collection($config:target-aemni, $block-name), $file-name, $transform($n))
};    


    local:write-and-split($test//item, 'tada', 25, 3, local:transform#1)
    
