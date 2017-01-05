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

declare variable $POSSESSION_ACT_CODES:= doc(concat($src, 'POSSESSION_ACT_CODES.xml')); 
declare variable $POSSESSION_ADDR:= doc(concat($src, 'POSSESSION_ADDR.xml')); 
declare variable $POSSESSION_DATA:= doc(concat($src, 'POSSESSION_DATA.xml')); 
declare variable $POSTED_TO_ADDR_DATA:= doc(concat($src, 'POSTED_TO_ADDR_DATA.xml')); 
declare variable $POSTED_TO_OFFICE_DATA:= doc(concat($src, 'POSTED_TO_OFFICE_DATA.xml')); 
declare variable $POSTING_DATA:= doc(concat($src, 'POSTING_DATA.xml')); 


declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 

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


declare function local:posting ($appointees as node()*) as node()* {
(:This function expects c_personid and returns tei:socecStatus description of the appointment.

Here we collect the information about an individuals 
particular post, the date of its tenure, the kind off appointment etc.
:)

(:
 [tts_sysno] INTEGER,                           d
 [c_personid] INTEGER,                          x
 [c_office_id] INTEGER, 
 [c_posting_id] INTEGER, 
 [c_posting_id_old] INTEGER, 
 [c_sequence] INTEGER, 
 [c_firstyear] INTEGER, 
 [c_fy_nh_code] INTEGER, 
 [c_fy_nh_year] INTEGER, 
 [c_fy_range] INTEGER, 
 [c_lastyear] INTEGER, 
 [c_ly_nh_code] INTEGER, 
 [c_ly_nh_year] INTEGER, 
 [c_ly_range] INTEGER, 
 [c_appt_type_code] INTEGER, 
 [c_assume_office_code] INTEGER, 
 [c_inst_code] INTEGER, 
 [c_inst_name_code] INTEGER, 
 [c_source] INTEGER, 
 [c_pages] CHAR(255), 
 [c_notes] CHAR, 
 [c_office_id_backup] INTEGER, 
 [c_office_category_id] INTEGER, 
 [c_fy_intercalary] BOOLEAN NOT NULL, 
 [c_fy_month] INTEGER, 
 [c_ly_intercalary] BOOLEAN NOT NULL, 
 [c_ly_month] INTEGER, 
 [c_fy_day] INTEGER, 
 [c_ly_day] INTEGER, 
 [c_fy_day_gz] INTEGER, 
 [c_ly_day_gz] INTEGER, 
 [c_dy] INTEGER, 
 [c_created_by] CHAR(255), 
 [c_created_date] CHAR(255), 
 [c_modified_by] CHAR(255), 
 [c_modified_date] CHAR(255), 
:)

(:POSTING_DATA seems on its way out, hence we query POSTED_TO_OFFICE_DATA directly:)
for $appointee in $appointees

let $post := $POSTED_TO_OFFICE_DATA//c_personid[. =$appointee]/../c_posting_id
let $addr := $POSTED_TO_ADDR_DATA//c_posting_id[. = $post]

for $post in $POSTED_TO_OFFICE_DATA//c_personid[. =$posting]/../c_posting_id

return
    <state notBefore = "{local:isodate($post/../c_firstyear/text())}" 
            notAfter = "{local:isodate($post/../c_lastyear/text())}"
            type = "posting" 
            sortKey = "{$post/../c_sequence/text()}"
            key ="{$post/../c_office_category_id/text()}">
        <label>posting</label>
        {
        if ($post/../c_notes[. != '']) 
        then (<note>{$post/../c_notes/text()}</note>)
        else()
        }
        {
        if ($post/../c_appt_type_code[. > -1] or $post/../c_assume_office_code[. > -1]) 
        then (<desc>
                <desc xml:lang ="en">{$APPOINTMENT_TYPE_CODES//c_appt_type_code[. = $post/../c_appt_type_code]/../c_appt_type_desc/text()}
                <label>{$ASSUME_OFFICE_CODES//c_assume_office_code[. = $post/../c_assume_office_code]/../c_assume_office_desc/text()}</label>
            </desc>
            <desc xml:lang="zh-Hant">{$APPOINTMENT_TYPE_CODES//c_appt_type_code[. = $post/../c_appt_type_code]/../c_appt_type_desc_chn/text()}
                <label>{$ASSUME_OFFICE_CODES//c_assume_office_code[. = $post/../c_assume_office_code]/../c_assume_office_desc_chn/text()}</label>
            </desc>
            </desc>)
        else()
        }
        {if ($POSTED_TO_ADDR_DATA//c_posting_id[. = $post]/../c_addr_id[. < 1]) 
        then ()
        else (<placeName ref="{concat('#PL', $POSTED_TO_ADDR_DATA//c_posting_id[. = $post]/../c_addr_id/text())}"/>)
        }    
        {if ($POSTED_TO_OFFICE_DATA//c_personid[. = $nodes]/../c_inst_code[. <1]) then()
        else(<state>{local:org-add($ppl, $POSTED_TO_OFFICE_DATA)}</state>)
        }
    </state>
};

declare function local:office_title ($offices as node()*) as node()* {

(:The offices and their location in the bureaucratic hierarchy are in tei:taxonomy[xml:id ='office'].
These are created by officeA.xql and officeB.xql. 
This function expects a c_personid and returns the title of a given office as tei:roleName with  @ref
pointing to the corresponding category in the header.
  
<socecStatus scheme="#office" code=""/>  
:)



for $ppl in $POSTED_TO_OFFICE_DATA//c_personid[. = $offices]/../c_office_id
let $cat := $OFFICE_CATEGORIES//c_office_category_id[. = $ppl/../c_office_category_id]

let $type := $OFFICE_TYPE_TREE//c_office_type_node_id[. = $OFFICE_CODE_TYPE_REL//c_office_id[. =$ppl]/../c_office_tree_id]
let $code := $OFFICE_CODES//c_office_id[. = $ppl]

return <roleName type ="office"> 
        <roleName xml:lang="en" key="{$type/text()}">
        {$code/../c_office_trans/text()}
            <trait>
                <desc>{$cat/../c_category_desc/text()}</desc>
                <label>{$type/../c_office_type_desc/text()}</label>
            </trait>
        </roleName>
        <roleName xml:lang="zh-alac97" key="{$type/text()}">
        {$code/../c_office_pinyin/text()}
            {if($code/../c_office_pinyin_alt[. !='']) 
            then(<roleName type="alias">{$code/../c_office_pinyin_alt/text()}</roleName>)
            else()
            }
        </roleName>            
        <roleName xml:lang="zh-Hant" key="{$type/text()}">
        {$code/../c_office_chn/text()}
            <trait>
                <desc>{$cat/../c_category_desc_chn/text()}</desc>
                <label>{$type/../c_office_type_desc_chn/text()}</label>
            </trait>
                {if($code/../c_office_chn_alt[. != '']) 
                then(<roleName type="alias">{$code/../c_office_chn_alt/text()}</roleName>)
                else()
                }
        </roleName>
    {if ($cat/../c_notes[.!= '']) 
    then (<note>{$cat/../c_notes/text()}</note>)
    else()
    }
    </roleName>
};
let $test := $BIOG_MAIN//c_personid[. > 0][. < 500]
let $full := $BIOG_MAIN//c_personid[. > 0]

return

local
        
