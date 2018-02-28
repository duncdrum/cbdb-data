xquery version "3.0";
(:~ 
: To generating the taxonomy for office titles we need two query files office.xql and officeB.xql. 
: 
: office creates two files which will be merged by officeB.
: Each file stores a taxonomy for one of two different ways that offices are categorized by CBDB.
:    
: @author Duncan Paterson
: @version 0.7
: 
: @return office.xml, officeA.xml.:)

module namespace off="http://exist-db.org/apps/cbdb-data/office";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare default element namespace "http://www.tei-c.org/ns/1.0";


declare 
    %test:pending("validation as test")
function off:office ($offices as node()*, $mode as xs:string?) as item()* {
(:~
: off:office transforms OFFICE_CODES, OFFICE_CODE_TYPE_REL, and OFFICE_TYPE_TREE data into categories elements.
: 
: @param $offices is a ``c_office_id``
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
: 
: @return ``<category xml:id="OFF...">...</category>``:)

let $output := 
    for $office in $offices[. > 0] 
    
    let $type-rel := $global:OFFICE_CODE_TYPE_REL//no:c_office_id[. = $office]
    let $type := $global:OFFICE_TYPE_TREE//no:c_office_type_node_id[. = $type-rel/../no:c_office_tree_id]
    
    return
        element category{ attribute xml:id {concat('OFF', $office/text())},
    (: We need a value for missing data for the merge to be successfull :)
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
return 
    switch($mode)
        case 'v' return global:validate-fragment($output, 'category')
        case 'd' return global:validate-fragment($output, 'category')[1]
    default return $output 
};

declare function off:nest-children ($data as node()*, $id as node(), $zh as node(), $en as node()) as node()*{
(:~
off:nest-children recursively transforms $OFFICE_TYPE_TREE into nested categories.

@param $data row in OFFICE_TYPE_TREE
: @param $id is a ``c_office_type_node_id``
: @param $zh category name in Chinese
: @param $en category name in English
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
: 
: @return nested ``<category n ="...">...</category>``:)

  element category { attribute n {$id},
    element catDesc { attribute xml:lang {'zh-Hant'},
        $zh/text()},
        
     if (empty($en) or $en/text() = '[not yet translated]')
     then ()
     else (element catDesc {attribute xml:lang {'en'},
        $en/text()}),
        
        for $child in $data[no:c_parent_id = $id]
        return off:nest-children($data, $child/no:c_office_type_node_id, 
            $child/no:c_office_type_desc_chn, $child/no:c_office_type_desc)    
        }
};

(:~
: once maxClauseCount errors are fixed the following will suffice for the join:
: let $tree-id := $data/no:c_office_type_node_id
: let $code := $global:OFFICE_CODE_TYPE_REL//no:c_office_tree_id[. =  $tree-id/text()]/../no:c_office_id:)
declare %private function off:office-write ($data as item()*) as item()* {
let $data := $global:OFFICE_TYPE_TREE//no:row
let $tree := xmldb:store($global:target, $global:office, 
                    <taxonomy xml:id="office">
                        <category n="00">
                            <catDesc xml:lang="en">missing data</catDesc>
                         </category>{                        
                        for $outer in $data[no:c_parent_id = 0]
                          return 
                            off:nest-children($data, $outer/no:c_office_type_node_id, 
                                $outer/no:c_office_type_desc_chn, $outer/no:c_office_type_desc)}
                    </taxonomy>)
                    
let $off := xmldb:store($global:target, $global:office-temp, 
                    <taxonomy xml:id="officeA">                       
                         {off:office($global:OFFICE_CODES//no:c_office_id, 'v')}                        
                     </taxonomy>)             

return
 ($tree, $off)
};


