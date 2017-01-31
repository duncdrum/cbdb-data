xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare default element namespace "http://www.tei-c.org/ns/1.0";

(:Generating the taxonomy for office titles requires two parts officeA.xql and officeB.xql. 
This is due to a potential bug  with the new range index. 

officeA creates two files:
  office.xml contains the tree structure of OFFICE_TYPE_TREE in TEI
  officeA.xml contains all offices found in OFFICE_CODES in TEI
officeB merges officeA.xml into office.xml.
    for this merge we require a category for missing data in the stored structure.
:)

declare function local:office ($offices as node()*) as item()* {

(:This function transforms OFFICE_CODE data into  tei:categories via  c_office_id. 
These are then inserted intointo the right postions in the office-tree via $OFFICE_CODE_TYPE_REL by officeB.xql
:)

(:Wow this is a mess. TODO
- OFFICE_CATEGORIES is linked with POSTED_TO_OFFICE_DATA so either it becomes tei:event/@type, 
or if gets its own taxonomy.
- $OFFICE_CODE_TYPE_REl//no:c_office_type_type_code ... WTF?
- clean up {A1D7} from $OFFICE_CODES//no:c_office_trans
:)

(:
[tts_sysno] INTEGER,                        d
 [c_office_id] INTEGER PRIMARY KEY,       x
 [c_dy] INTEGER,                             x
 [c_office_pinyin] CHAR(255),              x
 [c_office_chn] CHAR(255),                  x
 [c_office_pinyin_alt] CHAR(255),           x
 [c_office_chn_alt] CHAR(255),              x
 [c_office_trans] CHAR(255),                x
 [c_office_trans_alt] CHAR(255),            x
 [c_source] INTEGER,                         x
 [c_pages] CHAR(255),                        d
 [c_notes] CHAR,                              x
 [c_category_1] CHAR(50),                   !
 [c_category_2] CHAR(50),                   !
 [c_category_3] CHAR(50),                   !
 [c_category_4] CHAR(50),                   !
 [c_office_id_old] INTEGER)                 d
:)

for $office in $offices[. > 0] 

let $type-rel := $global:OFFICE_CODE_TYPE_REL//no:c_office_id[. = $office]
let $type := $global:OFFICE_TYPE_TREE//no:c_office_type_node_id[. = $type-rel/../no:c_office_tree_id]

return
    global:validate-fragment(element category{ attribute xml:id {concat('OFF', $office/text())},
        if (empty($type-rel/../no:c_office_tree_id) and empty($office/../no:c_dy))
        then (attribute n {'00'})
        else if (empty($type-rel/../no:c_office_tree_id))
            then (attribute n {$office/../no:c_dy/text()})
        else (attribute n {$type-rel/../no:c_office_tree_id/text()}),
    if (empty($office/../no:c_source) or $office/../no:c_source[. < 1])
    then ()
    else (attribute source {concat('#BIB', $office/../no:c_source/text())}),
        element catDesc {
            if (empty($office/../no:c_dy))
            then ()
            else (element date{ attribute sameAs {concat('#D', $office/../no:c_dy/text())}}),
            element roleName { attribute type {'main'},
                element roleName { attribute xml:lang {'zh-Hant'},
                    $office/../no:c_office_chn/text()},
                    if (empty($office/../no:c_office_pinyin))
                    then ()
                    else (element roleName { attribute xml:lang {'zh-Latn-alalc97'},
                    $office/../no:c_office_pinyin/text()}),
                if (empty($office/../no:c_office_trans) or $office/../no:c_office_trans/text() = '[Not Yet Translated]')
                then ()
                else if (contains($office/../no:c_office_trans/text(), '(Hucker)'))
                    then (element roleName {attribute xml:lang {'en'},
                                attribute resp {'Hucker'},
                            substring-before($office/../no:c_office_trans/text(), ' (Hucker)')})
                    else (element roleName { attribute xml:lang {'en'}, 
                $office/../no:c_office_trans/text()}), 
            if (empty($office/../no:c_notes))
            then ()
            else (element note {$office/../no:c_notes/text()})
            },
            if (empty($office/../no:c_office_chn_alt) and empty($office/../no:c_office_trans_alt))
            then ()
            else (element roleName { attribute type {'alt'},
                    if ($office/../no:c_office_chn_alt)
                    then (element roleName { attribute xml:lang {'zh-Hant'},
                            $office/../no:c_office_chn_alt/text()},
                        element roleName { attribute xml:lang {'zh-Latn-alalc97'},
                            $office/../no:c_office_pinyin_alt/text()})
                    else(),
                    if ($office/../no:c_office_trans_alt)
                    then (element roleName { attribute xml:lang {'en'}, 
                        $office/../no:c_office_trans_alt/text()})
                    else ()}
                  )
        }
    }, 'category')
};

declare function local:nest-children($data as node()*, $id as node(), $zh as node(), $en as node()) as node()*{
(: This function expects rows from $OFFICE_TYPE_TREE and returns a nested
tree of office types as tei:category.
:)

(:
[c_office_type_node_id] CHAR(50),               x
 [c_tts_node_id] CHAR(255),                      d
 [c_office_type_desc] CHAR(255),                x
 [c_office_type_desc_chn] CHAR(255),           x
 [c_parent_id] CHAR(50),                         d
:)

  element category { attribute n {$id},
    element catDesc { attribute xml:lang {'zh-Hant'},
    $zh/text()},
    if (empty($en) or $en/text() = '[not yet translated]')
    then ()
    else (element catDesc {attribute xml:lang {'en'},
    $en/text()}),
      for $child in $data[no:c_parent_id = $id]
      return local:nest-children($data, $child/no:c_office_type_node_id, 
        $child/no:c_office_type_desc_chn, $child/no:c_office_type_desc)    
  }
};

(: once maxCauseCount errors are fixed the following will suffice for the join:
let $tree-id := $data/no:c_office_type_node_id
let $code := $globalOFFICE_CODE_TYPE_REL//no:c_office_tree_id[. =  $tree-id/text()]/../no:c_office_id
:)

let $data := $global:OFFICE_TYPE_TREE//no:row
let $tree := xmldb:store($global:target, $global:office, 
                    <taxonomy xml:id="office">
                        <category n="00">
                            <catDesc xml:lang="en">missing data</catDesc>
                         </category>{                        
                        for $outer in $data[no:c_parent_id = 0]
                          return 
                            local:nest-children($data, $outer/no:c_office_type_node_id, 
                                $outer/no:c_office_type_desc_chn, $outer/no:c_office_type_desc)}
                    </taxonomy>)
                    
let $off := xmldb:store($global:target, $global:office-temp, 
                    <taxonomy xml:id="officeA">                       
                         {local:office($global:OFFICE_CODES//no:c_office_id)}                        
                     </taxonomy>)             



return
 ($tree, $off)


