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

declare function local:make ($att as item()) as map()* {
(:~ anything but array here leads to error, yet arrays remore ws :)
let $att-name:=  for $n in $tmpl//*/@*[local-name(.) = $att]
    return
        local-name($n/..)
        
for $x in distinct-values($att-name)
let $key := $x || '/@' || $att 
let $val := 'distinct-values(data($tmpl//tei:' || $x || '/@' || $att || '))'
let $seq := [util:eval($val)]

return
   map {$key := $seq}
};

declare function local:transform (
    $odd-el as xs:string, 
    $odd-at as xs:string, 
    $src-el as xs:string*, 
    $src-gloss as xs:string*) as item()* {
(:~
: local:transform the distinct values of the source-tables into odd:attDef
: 
:
: @param $odd-el the tei element name
: @param $odd-at the tei attribute to modified typically 'type' or 'sub-type'
: @param $src-el the cdbd element that contains the unique values
: @param $src-gloss the cbdb element that contains gloss for $src-el, if any. 
:)


element elementSpec { attribute ident {$odd-el},
        attribute mode {'change'},
            element attList {
                element attDef { attribute ident {$odd-at},
                    attribute usage {'rec'},
                    attribute mode {'change'},
                        element gloss { $odd-el || ' should have ' || $odd-at || ' attribute'},
                        element datatype {
                            element rng:ref { attribute name {'datatype.Code'} }
                        },
                        
                        for $value in distinct-values($src-el)                            
                        return
                            element valItem { attribute ident {$value},
                                if ($src-gloss = '') 
                                then (element gloss {'machine generated'})
                                else (element gloss {$src-gloss})
                            }
                }
            }        
        }
};


let $attribute := function () {
let $a := for $n in $tmpl//*/@*
    return local-name($n)

return
    distinct-values(data($a))
}

let $filter := 
map:merge(
    for $n in $attribute()
    
    return
        switch($n)
            case 'type' return local:make('type')
            case 'status' return local:make('status')
            case 'n' return local:make('n')
            case 'ana' return local:make('ana')
            case 'resp' return local:make('resp')
            case 'value' return local:make('value')
            case 'role' return local:make('role')
            case 'name' return local:make('name')
            case 'subtype' return local:make('subtype')
         default return map {'' : ''} )  

return


map:for-each($filter, function($key, $value){
let $a := substring-before($key, '/')
let $b := substring-after($key, '@')
let $c :=  map:get($filter, $key)

return
    
    "local:transform('" || $a || "', '" || $b || "', ('" || $c || "'), ''),"
})