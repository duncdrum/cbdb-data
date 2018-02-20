xquery version "3.1";

(:~
: aemni working module.
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
import module namespace sparql = "http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";

declare namespace output = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $test := element root {
    for $i in 1 to 500
    return
        element item {
            attribute xml:id {'i' || $i},
            $i
        }
};

(:~ 
 : determine the required padding length for a sequence of ints for human friendly display
 : @param $num onn or more integers
 : @return integer
 :)
declare function local:pad($num as xs:integer*) as xs:integer {
    let $max := max($num) cast as xs:string
    return
        string-length($max)
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

declare
(:%test:args(<root xmlns="http://none">
    <row>
        <c_text_cat_type_id>01</c_text_cat_type_id>
        <c_text_cat_type_desc>Chinese Primary Texts</c_text_cat_type_desc>
        <c_text_cat_type_desc_chn>古書原文</c_text_cat_type_desc_chn>
    </row>
    </root>)):)
function local:nest-types($types as node()*, $type-id as node(), $zh as node(), $en as node()) as element(category)* {
    
(:~ 
 : taxo:nest-types recursively transforms 'TEXT_BIBLCAT_TYPES' into nested categories. 
 :
 : @param $types **row** in TEXT_BIBLCAT_TYPES
 : @param $type-id is a `c_text_cat_type_id`
 : @param $zh category name in Chinese
 : @param $en category name in English
 :
 : @return nested `<category xml:id="biblType">...</category>`:)
    
    
    element category {
        attribute xml:id {concat('biblType', $type-id)},
        element catDesc {
            attribute xml:lang {'zh-Hant'},
            normalize-space($zh)
        },
        element catDesc {
            attribute xml:lang {'en'},
            normalize-space($en)
        },
        
        for $child in $types[no:c_text_cat_type_parent_id = $type-id]
        order by $child[no:c_text_cat_type_sortorder]
        return
            local:nest-types($types, $child/no:c_text_cat_type_id, $child/no:c_text_cat_type_desc_chn, $child/no:c_text_cat_type_desc)
    }

};
let $test := <root xmlns="http://none">
    <row>
        <c_text_cat_type_id>01</c_text_cat_type_id>
        <c_text_cat_type_desc>Chinese Primary Texts</c_text_cat_type_desc>
        <c_text_cat_type_desc_chn>古書原文</c_text_cat_type_desc_chn>
    </row>
    </root>
let $date := '-0140'

return
    $date cast as xs:gYear

(:local:nest-types($test//no:row, $test//no:c_text_cat_type_id, $test//no:c_text_cat_type_desc_chn, $test//no:c_text_cat_type_desc):)
