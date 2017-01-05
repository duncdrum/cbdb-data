xquery version "3.0";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace functx = "http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $BIOG_MAIN := doc(concat($src, 'BIOG_MAIN.xml'));

declare variable $APPOINTMENT_TYPE_CODES:= doc(concat($src, 'APPOINTMENT_TYPE_CODES.xml')); 
declare variable $OFFICE_CATEGORIES:= doc(concat($src, 'OFFICE_CATEGORIES.xml')); 

declare variable $POSTED_TO_ADDR_DATA:= doc(concat($src, 'POSTED_TO_ADDR_DATA.xml')); 
declare variable $POSTED_TO_OFFICE_DATA:= doc(concat($src, 'POSTED_TO_OFFICE_DATA.xml')); 
declare variable $POSTING_DATA:= doc(concat($src, 'POSTING_DATA.xml')); 

declare variable $ASSUME_OFFICE_CODES:= doc(concat($src, 'ASSUME_OFFICE_CODES.xml')); 

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

declare function local:create-mod-by ($created as node()*, $modified as node()*) as node()*{


for $creator in $created
return
    if (empty($creator)) 
    then ()
    else (<note type="created" target="{concat('#',$creator/text())}">
                <date when="{local:sqldate($creator/../c_created_date)}"/>
           </note>),
              
for $modder in $modified
return
    if (empty($modder)) 
    then ()
    else (<note type="modified" target="{concat('#',$modder/text())}">
                <date when="{local:sqldate($modder/../c_modified_date)}"/>
          </note>)   
        
        };


declare function local:posting ($appointees as node()*) as node()* {

(:
 [tts_sysno] INTEGER,                           d
 [c_personid] INTEGER,                          x
 [c_office_id] INTEGER,                         x
 [c_posting_id] INTEGER,                        x
 [c_posting_id_old] INTEGER,                   d
 [c_sequence] INTEGER,                          x
 [c_firstyear] INTEGER,                         x
 [c_fy_nh_code] INTEGER, 
 [c_fy_nh_year] INTEGER, 
 [c_fy_range] INTEGER, 
 [c_lastyear] INTEGER,                          x
 [c_ly_nh_code] INTEGER, 
 [c_ly_nh_year] INTEGER, 
 [c_ly_range] INTEGER, 
 [c_appt_type_code] INTEGER,                   x
 [c_assume_office_code] INTEGER,               x
 [c_inst_code] INTEGER, 
 [c_inst_name_code] INTEGER, 
 [c_source] INTEGER,                             x
 [c_pages] CHAR(255),                            d
 [c_notes] CHAR,                                  x
 [c_office_id_backup] INTEGER,                  d
 [c_office_category_id] INTEGER,                d
 [c_fy_intercalary] BOOLEAN NOT NULL,           
 [c_fy_month] INTEGER, 
 [c_ly_intercalary] BOOLEAN NOT NULL, 
 [c_ly_month] INTEGER, 
 [c_fy_day] INTEGER, 
 [c_ly_day] INTEGER, 
 [c_fy_day_gz] INTEGER, 
 [c_ly_day_gz] INTEGER, 
 [c_dy] INTEGER, 
 [c_created_by] CHAR(255),                      d
 [c_created_date] CHAR(255),                    d
 [c_modified_by] CHAR(255),                     d
 [c_modified_date] CHAR(255),                   d
:)


for $post in $POSTED_TO_OFFICE_DATA//c_personid[. = $appointees]
let $addr := $POSTED_TO_ADDR_DATA//c_posting_id[. = $post/../c_posting_id]
let $cat := $OFFICE_CATEGORIES//c_office_category_id[. = $post/../c_office_category_id]
let $appt := $APPOINTMENT_TYPE_CODES//c_appt_type_code[. = $post/../c_appt_type_code]
let $assu := $ASSUME_OFFICE_CODES//c_assume_office_code[. =$post/../c_assume_office_code]

return
    element state {
        attribute type {'posting'},        
        if (empty($post/../c_firstyear) or $post/../c_firstyear = 0) 
        then ()
        else (attribute notBefore {local:isodate($post/../c_firstyear/text())}),
        if (empty($post/../c_lastyear) or $post/../c_lastyear = 0) 
        then ()
        else (attribute notAfter {local:isodate($post/../c_lastyear/text())}),
        attribute key {$post/../c_posting_id/text()},
        if (empty($post/../c_sequence) or $post/../c_sequence = 0)
        then ()
        else (attribute sortKey {$post/../c_sequence/text()}), 
        if (empty($post/../c_source) or $post/../c_source = 0)
        then ()
        else (attribute source {concat('#BIB', $post/../c_source/text())}),
        attribute ref {concat('#OFF', $post/../c_office_id)}, 
        
      if (empty($post/../c_appt_type_code))
      then ()
      else (element desc { element label {'appointment'},
        element desc {attribute xml:lang {'zh-Hant'},
            $appt/../c_appt_type_desc_chn/text()}, 
        if (empty($appt/../c_appt_type_desc))
        then ()
        else (element desc {attribute xml:lang {'en'}, 
            $appt/../c_appt_type_desc/text()})
      }),
      
      if (empty($post/../c_assume_office_code))
      then ()
      else (element desc {element label {'assumes'},
        element desc {attribute xml:lang {'zh-Hant'},
            $assu/../c_assume_office_desc_ch/text()}, 
        element desc {attribute xml:lang {'en'}, 
            $assu/../c_assume_office_desc/text()}
      }),
        
      if (empty($post/../c_office_category_id) or $post/../c_office_category_id = 0)
      then ()
      else (attribute subtype {$post/../c_office_category_id/text()}),
      
      if (empty($post/../c_notes))
      then ()
      else (element note {$post/../c_notes/text()})
    }
};



declare function local:biog($persons as node()*) as node()* {
    
    for $person in $persons
    
    let $post := $POSTED_TO_OFFICE_DATA//c_personid[. = $person]
    
    return
        <person
            ana="historical"
            xml:id="{concat('BIO', $person/text())}">
            <idno
                type="TTS">{$person/../tts_sysno/text()}</idno>
            
            {if (empty($post))
            then ()
            else (local:posting($person))                
            }
        
        </person>
};

let $test := $BIOG_MAIN//c_personid[. > 0][. < 500]
let $full := $BIOG_MAIN//c_personid[. > 0]


return
    local:biog($test)




