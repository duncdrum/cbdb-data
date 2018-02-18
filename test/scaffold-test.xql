xquery version "3.1";

(:~
 : Independent tests for functions 
 : Replace local with name of target module
 :
 : @author Duncan Paterson
 : @version 0.8.0
 :)
module namespace scaf="http://exist-db.org/apps/cbdb-data/test";

declare namespace test="http://exist-db.org/xquery/xqsuite";

declare variable $scaf:data := 
    <root>{
        for $i in 1 to 500
        return
            <item xml:id="{concat('i', $i)}">{$i}</item>
        }
    </root>
;

declare %test:setUp function scaf:setup () {
 xmldb:store('/db/test', 'scaf-in.xml', $scaf:data)
};

declare %test:tearDown function scaf:cleanup () {
 xmldb:remove('/db/test', 'scaf-in.xml')
};

declare %test:assertTrue function scaf:sample () {

let $count := count($test//item)
let $items-per-l2 := 75
let $items-per-l3 := 12

return
<test>{$count mod $items-per-l3}</test>
<test>{($count > $items-per-l2) and ($items-per-l2 > $items-per-l3)}</test>
<test>{not($items-per-l3 * local:find-last-dir($count, $items-per-l3) <= $count)}</test>
};