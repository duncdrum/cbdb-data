xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $OFFICE_CATEGORIES:= doc(concat($src, 'OFFICE_CATEGORIES.xml')); 
declare variable $OFFICE_CODES:= doc(concat($src, 'OFFICE_CODES.xml')); 
declare variable $OFFICE_CODES_CONVERSION:= doc(concat($src, 'OFFICE_CODES_CONVERSION.xml')); 
declare variable $OFFICE_CODE_TYPE_REL:= doc(concat($src, 'OFFICE_CODE_TYPE_REL.xml')); 
declare variable $OFFICE_TYPE_TREE:= doc(concat($src, 'OFFICE_TYPE_TREE.xml')); 

declare variable $POSTED_TO_OFFICE_DATA:= doc(concat($src, 'POSTED_TO_OFFICE_DATA.xml')); 


declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 

(:Generating the taxonomy for office titles requires two parts officeA.xql and officeB.xql. 
This is due to a potential bug  with the new range index. 

officeA creates two files:
  office.xml contains the tree structure of OFFICE_TYPE_TREE in TEI
  officeA.xml contains all offices found in OFFICE_CODES in TEI
officeB merges officeA.xml into office.xml.
    for this merge we require a category for missing data in the stored structure.
:)

declare function local:isodate ($string as xs:string?)  as xs:string* {
(:see calendar.xql:)
        
    if (empty($string)) then ()
    else if (number($string) eq 0) then ('-0001')
    else if (starts-with($string, "-")) then (concat('-',(concat (string-join((for $i in (string-length(substring($string,2)) to 3) return '0'),'') , substring($string,2)))))
    else (concat (string-join((for $i in (string-length($string) to 3) return '0'),'') , $string))
};

declare function local:sqldate ($timestamp as xs:string?)  as xs:string* {
concat(substring($timestamp, 1, 4), '-', substring($timestamp, 5, 2), '-', substring($timestamp, 7, 2)) 
};


declare function local:office ($offices as node()*) as node()* {

(:This function transforms OFFICE_CODE data into  tei:categories via  c_office_id. 
These are then inserted intointo the right postions in the office-tree via $OFFICE_CODE_TYPE_REL by officeB.xql
:)

(:Wow this is a mess. TODO
- OFFICE_CATEGORIES is linked with POSTED_TO_OFFICE_DATA so either it becomes tei:event/@type, 
or if gets its own taxonomy.
- $OFFICE_CODES//c_category_1, _2, _3, _4 no clue what these are supposed to be, spot checks show them to be 
    part of the tree id?
- $OFFICE_CODE_TYPE_REl//c_office_type_type_code ... WTF?
- clean up {A1D7} from $OFFICE_CODES//c_office_trans
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

let $type-rel := $OFFICE_CODE_TYPE_REL//c_office_id[. = $office]
let $type := $OFFICE_TYPE_TREE//c_office_type_node_id[. = $type-rel/../c_office_tree_id]




return
    element category{ attribute xml:id {concat('OFF', $office/text())},
        if (empty($type-rel/../c_office_tree_id) and empty($office/../c_dy))
        then (attribute n {'00'})
        else if (empty($type-rel/../c_office_tree_id))
            then (attribute n {$office/../c_dy/text()})
        else (attribute n {$type-rel/../c_office_tree_id/text()}),
    if (empty($office/../c_source) or $office/../c_source[. < 1])
    then ()
    else (attribute source {concat('#BIB', $office/../c_source/text())}),
        element catDesc {
            if (empty($office/../c_dy))
            then ()
            else (element date{ attribute sameAs {concat('#D', $office/../c_dy/text())}}),
            element roleName { attribute type {'main'},
                element roleName { attribute xml:lang {'zh-Hant'},
                    $office/../c_office_chn/text()},
                    if (empty($office/../c_office_pinyin))
                    then ()
                    else (element roleName { attribute xml:lang {'zh-alalc97'},
                    $office/../c_office_pinyin/text()}),
                if (empty($office/../c_office_trans) or $office/../c_office_trans/text() = '[Not Yet Translated]')
                then ()
                else if (contains($office/../c_office_trans/text(), '(Hucker)'))
                    then (element roleName {attribute xml:lang {'en'},
                                attribute resp {'Hucker'},
                            substring-before($office/../c_office_trans/text(), ' (Hucker)')})
                    else (element roleName { attribute xml:lang {'en'}, 
                $office/../c_office_trans/text()}), 
            if (empty($office/../c_notes))
            then ()
            else (element note {$office/../c_notes/text()})
            },
            if (empty($office/../c_office_chn_alt) and empty($office/../c_office_trans_alt))
            then ()
            else (element roleName { attribute type {'alt'},
                    if ($office/../c_office_chn_alt)
                    then (element roleName { attribute xml:lang {'zh-Hant'},
                            $office/../c_office_chn_alt/text()},
                        element roleName { attribute xml:lang {'zh-alalc97'},
                            $office/../c_office_pinyin_alt/text()})
                    else(),
                    if ($office/../c_office_trans_alt)
                    then (element roleName { attribute xml:lang {'en'}, 
                        $office/../c_office_trans_alt/text()})
                    else ()}
                  )
        }
    }
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
    else (element catDesc { attribute xml:lang {'en'},
    $en/text()}),
      for $child in $data[c_parent_id = $id]
      return local:nest-children($data, $child/c_office_type_node_id, 
        $child/c_office_type_desc_chn, $child/c_office_type_desc)    
  }
};

(: once maxCauseCount errors are fixed the following will suffice for the join:
let $tree-id := $data/c_office_type_node_id
let $code := $OFFICE_CODE_TYPE_REL//c_office_tree_id[. =  $tree-id/text()]/../c_office_id
:)

let $data := $OFFICE_TYPE_TREE//row
let $tree := xmldb:store($target, 'office.xml', 
                    <taxonomy xml:id="office">
                        <category n="00">
                            <catDesc xml:lang="en">missing data</catDesc>
                         </category>
                    {for $outer in $data[c_parent_id = 0]
                      return 
                        local:nest-children($data, $outer/c_office_type_node_id, 
                            $outer/c_office_type_desc_chn, $outer/c_office_type_desc)}
                    </taxonomy>)
                    
let $off := xmldb:store($target, 'officeA.xml', 
                     <taxonomy xml:id="officeA">                        
                         {local:office($OFFICE_CODES//c_office_id)}                         
                     </taxonomy>)             



return
 ($tree, $off)


