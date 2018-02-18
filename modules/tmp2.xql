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

(:declare default element namespace "http://www.tei-c.org/ns/1.0";:)

declare variable $path := collection($config:app-root || '/src/');
declare variable $model := $path/model/.;
declare variable $tmpl := doc('/db/apps/cbdb-data/templates/tei/cbdbTEI-template.xml');

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


(:~ 
 : called by scaffolding to calculate the number of directories
 : @param $i the number of items
 : @param $j the size of the grouping
 : @return the required number of folders to store the items in the desired groups
 :)
declare
%test:args(10, 5) %test:assertEquals(2)
%test:args(10, 4) %test:assertEquals(3)
%test:args(2, 100) %test:assertEquals(1)
function local:find-last-dir($i as xs:positiveInteger, $j as xs:positiveInteger) as xs:integer {
    if ($i mod $j = 0)
    then
        ($i div $j)
    else
        ($i idiv $j + 1)
};

let $test := element root {
    for $i in 1 to 500
    return
        element item {
            attribute xml:id {'i' || $i},
            $i
        }
}

let $count := count($test//item)
let $collection := 'recurse'

let $items-per-l2 := 75
let $items-per-l3 := 12

(: Make folders :)

let $parent := function ($col-name as xs:string) {
let $col-path := $config:target-aemni || $col-name
return
    if (exists(collection($col-path)))
    then
        ($col-path)
    else
        (xmldb:create-collection($config:target-aemni, $col-name))
}

let $chunks := function ($n as xs:positiveInteger) {
    for $i in 1 to local:find-last-dir($count, $n)
    return
        xmldb:create-collection($parent($collection),
        'chunk-' || functx:pad-integer-to-length($i, local:pad($count idiv $n)))
}


let $blocks := function ($n as xs:positiveInteger, $f as function(*)) {
    $n,
    if ($n eq 0)
    then
        ($collection)
    else
        ($f($n - 1, $f))
}

(: write doc into new collections :)
let $store-doc := function ($items as item()*) as item() {
    for $item in $items
    return
        <data>{$item}</data>
}

(:for $item in $test//item[position() = (. to 3)]:)
for $n at $pos in $test//item
return
   local:pad($pos)