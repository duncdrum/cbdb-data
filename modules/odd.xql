xquery version "3.1";

(:~
: The odd module creates a a custom odd based on the exported CBDB source files
: 
: @author Duncan Paterson
: @version 0.8.0
:)

(:module namespace odd="http://exist-db.org/apps/cbdb-data/odd";:)

import module namespace functx = "http://www.functx.com";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace global = "http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare
%private
function odd:test($max as xs:integer?) as xs:integer* {
    
    for $n in 1 to $max
    return
        $n
};
(:~
 : TODO: make closed lists for all (sub-)type attributes 
 : settle on a date format for chinese dates
 :)
 
declare function odd:scan-src($nodes as item()*) as item()* {
for $node in $nodes 
return
    switch(local-name($node))
     case 'c_assoc_type_short_desc' return 'relation'
     
     default return ()
};

declare
    %public
    function odd:transform($nodes as node()*, $cleanup as function(*), $ident as map(*)) as item()* {
    
    for $node in $nodes
    return
        element elementSpec { attribute ident {$odd-el},
        attribute mode {'change'},
            element attList {
                element attDef { attribute ident {$odd-at},
                    attribute usage {'rec'},
                    attribute mode {'change'},
                        element gloss { $odd-el || ' should have' || $odd-at || ' attribute'},
                        element datatype {
                            element rng:ref { attribute name {datatype.Code} }
                        },
                        element valItem { attribute ident {$src-el},
                            element gloss {$src-gloss}
                        }
                }
            }        
        }
};

odd:scan-src($config:src-data)
