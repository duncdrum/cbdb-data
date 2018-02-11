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


(:~ A convenience function for creating element names in the TEI namespace :)
declare function local:make-no-element-name($local-name as xs:string) {
    QName("http://none", $local-name)
};
(: identify the table that requires processing :)
(: TODO turn this into a map for easier passing around:)

declare function local:find-table($table as xs:string?) as item()*{
let $n := $model//column[. = $table]
return
    local-name($n[1]/..)
};

(:~
: local:find-values finds the unique values to populate odd:attVal list
: 
:
: @param  $data column name 
:)
declare function local:find-values($data as xs:string) as item()* {
let $table := local:find-table($data)
let $col-path := $config:src-data || $table || '.xml'
(:let $name := local:make-no-element-name#1:)
for $n in doc($col-path)//*[local-name(.) eq $data]

return    
    distinct-values($n/text())
};

(:~
: local:transform the distinct values of the source-tables into odd:attDef
: 
:
: @param $odd-el the tei element name
: @param $odd-at the tei attribute to modified typically 'type' or 'sub-type'
: @param $src-el the cdbd element that contains the unique values
: @param $src-gloss the cbdb element that contains gloss for $src-el, if any. 
:)
declare function local:transform (
    $odd-el as xs:string, 
    $odd-at as xs:string, 
    $src-el as xs:string*, 
    $src-gloss as xs:string?) as item()* {
    
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
                        
                        for $value in local:find-values($src-el)
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



(:    local:find-values('c_name_type_desc_chn'):)
    local:transform('addName', 'type', 'c_name_type_desc_chn', '')
    

(:    
let $n := $model//column[. = 'c_name_type_desc_chn']
return
    if (count($n) < 1)
    then ('oh snap')
    else (local:find-table(local-name($n[1]/..))):)

(:for $n in $model/
return
    local:find-table():)



