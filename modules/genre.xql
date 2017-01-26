xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
(:import module namespace functx="http://www.functx.com";:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace gen="http://exist-db.org/apps/cbdb-data/genre";

declare namespace output = "http://www.tei-c.org/ns/1.0";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";


(:genre.xql combines $TEXT_BIBLCAT_CODES and $TEXT_BIBLCAT_TYPES inot a nested tei:taxonomy.
the categories appear mostly listBibl.xml
:)

(:!!!Calling this function overwrites data!!!:)

declare function gen:nest-types ($types as node()*, $type-id as node(), $zh as node(), $en as node())  as node()* {

(:This function transforms $TEXT_BIBLCAT_TYPES inoto nested tei:categoreis.

:)

(:TODO
-  Q: Is there  any use for $TEXT_BIBLCAT_TYPES_1 and $TEXT_BIBLCAT_TYPES_2? 
   A: NO!
:)

element category { attribute xml:id {concat('biblType',  $type-id/text())},        
    element catDesc {attribute xml:lang {'zh-Hant'},
        $zh/text()},           
element catDesc {attribute xml:lang {'en'},
    $en/text()},
    
    for $child in $types[c_text_cat_type_parent_id = $type-id]
    return
        gen:nest-types($types, $child/c_text_cat_type_id, $child/c_text_cat_type_desc_chn, $child/c_text_cat_type_desc)               
}      
};


let $types := $global:TEXT_BIBLCAT_TYPES//row
let $typeTree := xmldb:store($global:target, $global:genre, 
                    element taxonomy { namespace {"tei"} {"http://www.tei-c.org/ns/1.0"},
                        attribute xml:id {"biblCat"},
                        element category {
                            attribute xml:id {'biblType01'},
                            element catDesc { attribute xml:lang {'zh-Hant'},
                                $types/c_text_cat_type_id[. = '01']/../c_text_cat_type_desc_chn/text()},
                            element catDesc { attribute xml:lang {'en'},    
                                $types/c_text_cat_type_id[. = '01']/../c_text_cat_type_desc/text()},        
                        for $outer in $types[c_text_cat_type_parent_id = '01']
                        order by $outer[c_text_cat_type_sortorder]
                        return
                            gen:nest-types($types, $outer/c_text_cat_type_id ,$outer/c_text_cat_type_desc_chn, $outer/c_text_cat_type_desc)
                            }
                        }
                    )





for $cat in $global:TEXT_BIBLCAT_CODES//c_text_cat_code

let $type-id := $global:TEXT_BIBLCAT_CODE_TYPE_REL//c_text_cat_code[ . = $cat]/../c_text_cat_type_id
let $type: = doc($typeTree)//category/@xml:id[. = concat('biblType', $type-id/text())]
let $category := element category { attribute xml:id {concat('biblCat',  $cat/text())},        
                    element catDesc {attribute xml:lang {'zh-Hant'},
                        $cat/../c_text_cat_desc_chn/text()},
                    element catDesc {attribute xml:lang {'zh-Latn-alalc97'},
                        $cat/../c_text_cat_pinyin/text()},    
                    element catDesc {attribute xml:lang {'en'},
                        $cat/../c_text_cat_desc/text()}}

return
 update insert $category into $type/..
 



