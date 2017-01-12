xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $TEXT_BIBLCAT_CODES:= doc(concat($src, 'TEXT_BIBLCAT_CODES.xml')); 
declare variable $TEXT_BIBLCAT_CODE_TYPE_REL:= doc(concat($src, 'TEXT_BIBLCAT_CODE_TYPE_REL.xml')); 
declare variable $TEXT_BIBLCAT_TYPES:= doc(concat($src, 'TEXT_BIBLCAT_TYPES.xml')); 
declare variable $TEXT_BIBLCAT_TYPES_1:= doc(concat($src, 'TEXT_BIBLCAT_TYPES_1.xml')); 
declare variable $TEXT_BIBLCAT_TYPES_2:= doc(concat($src, 'TEXT_BIBLCAT_TYPES_2.xml')); 
declare variable $TEXT_CODES:= doc(concat($src, 'TEXT_CODES.xml')); 
declare variable $TEXT_DATA:= doc(concat($src, 'TEXT_DATA.xml')); 
declare variable $TEXT_ROLE_CODES:= doc(concat($src, 'TEXT_ROLE_CODES.xml')); 
declare variable $TEXT_TYPE:= doc(concat($src, 'TEXT_TYPE.xml')); 


declare function local:categories ($types as node()*, $categories as node()*, $parent-id as xs:string?)  as node()* {

(:This function transforms $TEXT_BIBLCAT_CODES and $TEXT_BIBLCAT_TYPES into a nested TEI <taxonomy>.
To call types, genres, and biblcats a mess would be a compliment...another time.

:)

for $type in $types
let $code :=  $TEXT_BIBLCAT_CODE_TYPE_REL//c_text_cat_type_id[. = $type]/../c_text_cat_code[. = $categories]

where $type/../c_text_cat_type_parent_id = $parent-id

order by $type/../c_text_cat_type_sortorder
return
     element category { attribute xml:id {concat('biblType', $type/text())},
        attribute n {$type/../c_text_cat_type_level/text()},
            element catDesc {attribute xml:lang {'zh-Hant'},
                $type/../c_text_cat_type_desc_chn/text()},           
            element catDesc {attribute xml:lang {'en'},
                $type/../c_text_cat_type_desc/text()},
                
                for $cat in $TEXT_BIBLCAT_CODES//c_text_cat_code[. = $code]           
                let $parent-id := $cat/../c_text_cat_type_parent_id
                let $type-lvl := $cat/../c_text_cat_type_level
                (:  $TEXT_BIBLCAT_TYPES_1   $TEXT_BIBLCAT_TYPES_2  :)
                
                order by $cat/../c_text_cat_sortorder
                
                return
                    element category { attribute xml:id {concat('biblCat', $cat/text())},
                        attribute n {$code/text()},
                            element catDesc {attribute xml:lang {'zh-Hant'},
                                $cat/../c_text_cat_desc_chn/text()},
                            element catDesc {attribute xml:lang {'zh-alac97'},
                                $cat/../c_text_cat_pinyin/text()},
                            element catDesc {attribute xml:lang {'en'},
                                $cat/../c_text_cat_desc/text()}    
                    } 
    }      
};

declare function local:bibliography ($texts as node()*) {

(:This function reads the entities in TEXT_CODES [sic] and generates corresponding tei:bibl elements:)

for $text in $texts

let $role := $TEXT_DATA//c_textid[ . = $text]/../c_role_id

let $cat  := $TEXT_BIBLCAT_CODES//c_text_cat_code[. =  $text/../c_bibl_cat_code/text()]
let $type := $TEXT_TYPE//c_text_type_code[. =$text/../c_text_type_id/text()]


(: d= drop
[tts_sysno] INTEGER,                     x
 [c_textid] INTEGER PRIMARY KEY,       x
 [c_title_chn] CHAR(255),               x
 [c_suffix_version] CHAR(255),         x
 [c_title] CHAR(255),                    x
 [c_title_trans] CHAR(255),             x
 [c_text_type_id] INTEGER,              x        
 [c_text_year] INTEGER,                 x
 [c_text_nh_code] INTEGER,              x
 [c_text_nh_year] INTEGER,              x
 [c_text_range_code] INTEGER,          x
 [c_period] CHAR(255),                  x
 [c_bibl_cat_code] INTEGER,            x     
 [c_extant] INTEGER,                    x
 [c_text_country] INTEGER,             x 
 [c_text_dy] INTEGER,                   x
 [c_pub_country] INTEGER,              x
 [c_pub_dy] INTEGER,                    x
 [c_pub_year] CHAR(50),                 x
 [c_pub_nh_code] INTEGER,               x   
 [c_pub_nh_year] INTEGER,               x
 [c_pub_range_code] INTEGER,            x
 [c_pub_loc] CHAR(255),                  x
 [c_publisher] CHAR(255),               x
 [c_pub_notes] CHAR(255),               x
 [c_source] INTEGER,                     x
 [c_pages] CHAR(255),                    x
 [c_url_api] CHAR(255),                  x
 [c_url_homepage] CHAR(255),            x
 [c_notes] CHAR,                          x
 [c_number] CHAR(255),                   x
 [c_counter] CHAR(255),                  x
 [c_title_alt_chn] CHAR(255),           x
 [c_created_by] CHAR(255),              x
 [c_created_date] CHAR(255),            x
 [c_modified_by] CHAR(255),             x
 [c_modified_date] CHAR(255))           x
 :)


return
    <bibl xml:id="{concat("BIB", $text/text())}">

        {if (empty($text/../c_text_type_id) or $text/../c_text_type_id[. = 0])
        then ()
        else (<ref type="genre" subtype="texttype" target="{concat("#TT", $text/../c_text_type_id/text())}"/>)        
        }
        {if (empty($text/../c_bibl_cat_code) or $text/../c_bibl_cat_code[. = 0])
        then ()
        else (<ref type="genre" subtype="biblcat" target="{concat("#TT", $text/../c_bibl_cat_code/text())}"/>)        
        }

</bibl>

};

let $test := $TEXT_CODES//c_textid[. > 0][. < 501]
let $full := $TEXT_CODES//c_textid[. > 0]

return 
    local:categories($TEXT_BIBLCAT_TYPES//c_text_cat_type_id, $TEXT_BIBLCAT_CODES//c_text_cat_code, '01')

(:xmldb:store($target, 'biblCat.xml', 
    <taxonomy xml:id="biblCat">                
        {local:categories($tax)}
    </taxonomy>
):)

(:<listBibl>
        {local:bibliography($full)}
</listBibl>:)  