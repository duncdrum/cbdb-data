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
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

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

declare function local:office ($offices as node()*) as item()* {
(:~
: local:office transforms `OFFICE_CODES`, `OFFICE_CODE_TYPE_REL`, and `OFFICE_TYPE_TREE`
: data into nested categories elements.
: 
: @param $offices is a ``c_office_id``
: 
: @return ``<category xml:id="OFF...">...</category>``:)


    for $office in $offices[. > 0] 
    
    let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:c_office_id[. = $office]
    let $type := $config:OFFICE_TYPE_TREE//no:c_office_type_node_id[. = $type-rel/../no:c_office_tree_id]
    
    return
        element category{ attribute xml:id {concat('OFF', $office/text())},
    (: We need an value for missing data for the merge to be successfull :)
            if (empty($type-rel/../no:c_office_tree_id) and empty($office/../no:c_dy))
            then (attribute n {'00'})
            else if (empty($type-rel/../no:c_office_tree_id))
                then (attribute n {$office/../no:c_dy/text()})
                else (attribute n {$type-rel/../no:c_office_tree_id/text()}),
            
        if (empty($office/../no:c_source) or $office/../no:c_source[. < 1])
        then ()
        else (attribute source {concat('#BIB', $office/../no:c_source/text())}),
    (: catDesc:)
            element catDesc {
                 element roleName { attribute type {'main'}, 
                    for $n in $office/../*
                    order by local-name($n) 
                    return
                        typeswitch($n)
                            case element (no:c_office_chn) return element roleName { attribute xml:lang {'zh-Hant'}, $n/text()}
                            case element (no:c_office_pinyin) return element roleName { attribute xml:lang {'zh-Latn-alalc97'}, $n/text()}
                            case element (no:c_office_trans) return 
                                if ($n/text() = '[Not Yet Translated]')
                                then ()
                                else if (contains($n/text(), '(Hucker)'))
                                    then (element roleName { attribute xml:lang {'en'},
                                             attribute resp {'Hucker'},  substring-before($n/text(), ' (Hucker)')})
                                    else (element roleName { attribute xml:lang {'en'},
                                             $n/text()})                                             
                        default return (), 
    (: looks odd at start of element :)
                        if (empty($office/../no:c_notes))
                        then ()
                        else (element note {$office/../no:c_notes/text()})
                        },
                        
                if (empty($office/../no:c_office_chn_alt) and empty($office/../no:c_office_trans_alt))
                then ()
                else (element roleName { attribute type {'alt'},        
                    for $off in $office/../*[. != '0']
                    order by local-name($off) 
                    return
                        typeswitch($off)                        
                            case element (no:c_office_chn_alt) return element roleName { attribute xml:lang {'zh-Hant'}, $off/text()}
                            case element (no:c_office_pinyin_alt) return element roleName { attribute xml:lang {'zh-Latn-alalc97'}, $off/text()}
                            case element (no:c_office_trans_alt) return element roleName { attribute xml:lang {'en'}, $off/text()}                        
                        default return ()}), 
                
                if (empty($office/../no:c_dy))
                then ()
                else (cal:new-date($office/../no:c_dy, 'when-custom')[@calendar])              
            }
        }
};

declare function local:nest-children ($types as node()*, $id as node(), $zh as node(), $en as node()) element(category)*{
(:~
: local:nest-children recursively transforms $OFFICE_TYPE_TREE into nested categories.
: 
 : @param $types **row** in `TEXT_BIBLCAT_TYPES`
 : @param $type-id is a `c_text_cat_type_id`
 : @param $zh category name in Chinese
 : @param $en category name in English
: 
: 
: @return nested ``<category n ="...">...</category>``:)

let $initial := 
    switch($types)
    case 'TEXT_BIBLCAT_TYPES' return 'biblType'
    case 'OFFICE_TYPE_TREE' return 'offType'
    default return ('someType')
    
return
  element category {
        attribute xml:id { $initial || $type-id },
        element catDesc {
            attribute xml:lang {'zh-Hant'},
            normalize-space($zh)
        },
        if (empty($en) or $en eq '[not yet translated]') 
        then ()
        else (element catDesc { attribute xml:lang {'en'},
            normalize-space($en)
        }),
        
        for $child in $types[no:c_text_cat_type_parent_id = $type-id]
            order by $child[no:c_text_cat_type_sortorder]
        return
            taxo:nest-biblCat($types, $child/no:c_text_cat_type_id, $child/no:c_text_cat_type_desc_chn, $child/no:c_text_cat_type_desc)
    }
};

(:~
: once maxCauseCount errors are fixed the following will suffice for the join:
: let $tree-id := $data/no:c_office_type_node_id
: let $code := $globalOFFICE_CODE_TYPE_REL//no:c_office_tree_id[. =  $tree-id/text()]/../no:c_office_id:)