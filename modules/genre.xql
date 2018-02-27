xquery version "3.0";
(:~
: !!! DEPRECATED since ÆMNI !!!
: genre.xql combines $TEXT_BIBLCAT_CODES and $TEXT_BIBLCAT_TYPES into nested taxonomy elements.
: these are referenced from listBibl.xml. 
:
: The exact difference between bibliographical category codes, and category types is unclear. 
: This module joins them within one taxonomy and at the level speciefied in the sources. 
:
: @author Duncan Paterson
: @version 0.7
: 
: @return biblCat.xml:)

module namespace gen="http://exist-db.org/apps/cbdb-data/genre";

(:import module namespace functx="http://www.functx.com";:)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare namespace output = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";


(: !!! UPDATING FUNCTION, OVERWRITES DATA !!!:)

declare 
    %test:pending("fragment")
function gen:nest-types ($types as node()*, $type-id as node(), $zh as node(), $en as node(), $mode as xs:string?)  as item()* {

(:~ 
: gen:nest-types recursively transforms TEXT_BIBLCAT_TYPES into nested categories. 
:
: @param $types row in TEXT_BIBLCAT_TYPES
: @param $type-id is a ``c_text_cat_type_id``
: @param $zh category name in Chinese
: @param $en category name in English
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
:
: @return nested ``<category xml:id="biblType">...</category>``:)

let $output := 
element category { attribute xml:id {concat('biblType',  $type-id/text())},        
    element catDesc {attribute xml:lang {'zh-Hant'},
        $zh/text()},           
element catDesc {attribute xml:lang {'en'},
    $en/text()},
    
    for $child in $types[no:c_text_cat_type_parent_id = $type-id]
    return
        gen:nest-types($types, $child/no:c_text_cat_type_id, $child/no:c_text_cat_type_desc_chn, $child/no:c_text_cat_type_desc, '')               
}
return 
    switch($mode)
        case 'v' return global:validate-fragment($output, 'category')
        case 'd' return global:validate-fragment($output, 'category')[1]
    default return $output       
};

declare %private function gen:write($item as item()*) as item() {
(:~
: call recursive function from top level elements. 
: @param $typeTree the nested tree of types stored in the db.:)
let $types := $global:TEXT_BIBLCAT_TYPES//no:row
let $typeTree := xmldb:store($global:target, $global:genre, 
                    <taxonomy xml:id="biblCat">
                        <category xml:id="biblType01">
                            <catDesc xml:lang="zh-Hant">{$types/no:c_text_cat_type_id[. = '01']/../no:c_text_cat_type_desc_chn/text()}</catDesc>
                            <catDesc xml:lang="en">{$types/no:c_text_cat_type_id[. = '01']/../no:c_text_cat_type_desc/text()}</catDesc>       
                            {for $outer in $types[no:c_text_cat_type_parent_id = '01']
                            order by $outer[no:c_text_cat_type_sortorder]
                            return
                                gen:nest-types($types, $outer/no:c_text_cat_type_id ,$outer/no:c_text_cat_type_desc_chn, $outer/no:c_text_cat_type_desc, '')}
                        </category>
                    </taxonomy>)

(:~
: inserts the genre categories codes, into the previously generated tree of category types.:)

for $cat in $global:TEXT_BIBLCAT_CODES//no:c_text_cat_code

let $type-id := $global:TEXT_BIBLCAT_CODE_TYPE_REL//no:c_text_cat_code[ . = $cat]/../no:c_text_cat_type_id
let $type: = doc($typeTree)//category/@xml:id[. = concat('biblType', $type-id/text())]
let $category := element category { attribute xml:id {concat('biblCat',  $cat/text())},        
                    element catDesc {attribute xml:lang {'zh-Hant'},
                        $cat/../no:c_text_cat_desc_chn/text()},
                    element catDesc {attribute xml:lang {'zh-Latn-alalc97'},
                        $cat/../no:c_text_cat_pinyin/text()},    
                    element catDesc {attribute xml:lang {'en'},
                        $cat/../no:c_text_cat_desc/text()}}
(:order by number($cat/../no:c_text_cat_sortorder):)
return
 update insert $category into $type/..
}; 



