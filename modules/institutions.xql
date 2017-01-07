xquery version "3.0";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace functx = "http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $SOCIAL_INSTITUTION_ADDR:= doc(concat($src, 'SOCIAL_INSTITUTION_ADDR.xml')); 
declare variable $SOCIAL_INSTITUTION_ADDR_TYPES:= doc(concat($src, 'SOCIAL_INSTITUTION_ADDR_TYPES.xml')); 

declare variable $SOCIAL_INSTITUTION_ALTNAME_CODES:= doc(concat($src, 'SOCIAL_INSTITUTION_ALTNAME_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_ALTNAME_DATA:= doc(concat($src, 'SOCIAL_INSTITUTION_ALTNAME_DATA.xml')); 
declare variable $SOCIAL_INSTITUTION_CODES:= doc(concat($src, 'SOCIAL_INSTITUTION_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_CODES_CONVERSION:= doc(concat($src, 'SOCIAL_INSTITUTION_CODES_CONVERSION.xml')); 
declare variable $SOCIAL_INSTITUTION_NAME_CODES:= doc(concat($src, 'SOCIAL_INSTITUTION_NAME_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_TYPES:= doc(concat($src, 'SOCIAL_INSTITUTION_TYPES.xml')); 

(:This function does what biographies does for persons for institutions.:)
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


declare function local:org ($institutions as node()*) as node()* {
(:This function writes the org / orgName elements to be stored in listOrg.xml.
altName tables are empty, ??
:)

(:TODO
- careful this has a combined primary key between inst_name and inst_code
- fix datable -custom stuff otherwise ok
- friggin YEAR_RANGE_CODES are back
= most of this fields in these tables are empty 
:)

(:
[c_inst_name_code] INTEGER,                    d
 [c_inst_code] INTEGER,                         x
 [c_inst_type_code] INTEGER,                   x
 [c_inst_begin_year] INTEGER,                  x
 [c_by_nianhao_code] INTEGER,                  x               
 [c_by_nianhao_year] INTEGER,                  x
 [c_by_year_range] INTEGER,                    d              
 [c_inst_begin_dy] INTEGER,                    x                  
 [c_inst_floruit_dy] INTEGER,                  x                 
 [c_inst_first_known_year] INTEGER,           x          
 [c_inst_end_year] INTEGER,                    x                  
 [c_ey_nianhao_code] INTEGER,                  x                 
 [c_ey_nianhao_year] INTEGER,                  x           
 [c_ey_year_range] INTEGER,                    d                  
 [c_inst_end_dy] INTEGER,                      x              
 [c_inst_last_known_year] INTEGER,           x
 [c_source] INTEGER,                           x
 [c_pages] CHAR(50),                           d
 [c_notes] CHAR,                                x
:)

for $org in $institutions

let $name := $SOCIAL_INSTITUTION_NAME_CODES//c_inst_name_code[. = $org/../c_inst_name_code]
let $type := $SOCIAL_INSTITUTION_TYPES//c_inst_type_code[. = $org/../c_inst_type_code]
let $alt := $SOCIAL_INSTITUTION_ALTNAME_DATA//c_inst_code[. = $org]
let $alt-type := $SOCIAL_INSTITUTION_ALTNAME_CODES//c_inst_altname_type[. = $alt/../c_inst_altname_type]

return
    element org { attribute xml:id {concat('ORG', $org/text())},
        attribute ana {'historical'},
        switch ($type)
            case '1' return attribute role {'academy'}
            case '2' return attribute role {'buddhist'}
            case '3' return attribute role {'daoist'}
            default return (),
        if (empty($org/../c_source))
        then ()
        else (attribute source {concat('#BIB', $org/../c_source/text())}),
        element orgName { attribute type {'main'},
            element orgName {attribute xml:lang {'zh-Hant'},
                $name/../c_inst_name_hz/text()},
            element orgName {attribute xml:lang {'zh-alalc97'},
                $name/../c_inst_name_py/text()},
            if (empty($alt-type))    
            then ()
            else ( element orgName { attribute type {'alias'},
                 element orgName {attribute xml:lang {'zh-Hant'},
                    $alt-type/../c_inst_altname_chn/text()},
                 element orgName {attribute xml:lang {'zh-alalc97'},
                    $alt-type/../c_inst_altname_desc/text()}
            }),
            
        if (empty ($org/../c_inst_begin_year) and empty ($org/../c_inst_end_year))
        then ()
        else (element date {
            if (empty($org/../c_inst_begin_year))
            then ()
            else (attribute from {local:isodate($org/../c_inst_begin_year)}),
            if (empty($org/../c_inst_end_year))
            then ()
            else (attribute to {local:isodate($org/../c_inst_end_year)})       
        }),
        
        if (empty ($org/../c_inst_first_known_year) and empty ($org/../c_inst_last_known_year))
        then ()
        else (element date {
            if (empty($org/../c_inst_first_known_year))
            then ()
            else (attribute from {local:isodate($org/../c_inst_first_known_year)}),
            if (empty($org/../c_inst_last_known_year))
            then ()
            else (attribute to {local:isodate($org/../c_inst_last_known_year)})       
        }),
        
        if (empty($org/../c_inst_begin_dy) and empty($org/../c_inst_end_dy) and empty($org/../c_inst_floruit_dy))
        then ()
        else (element date { attribute datingMethod {'chinTrad'},            
            if (empty($org/../c_inst_begin_dy) or $org/../c_inst_begin_dy = 0)
            then ()
            else (attribute from-custom {concat('#D',$org/../c_inst_begin_dy/text())}),
            if (empty($org/../c_inst_end_dy) or $org/../c_inst_end_dy = 0)
            then ()
            else (attribute to-custom {concat('#D',$org/../c_inst_end_dy/text())}),
            if (empty($org/../c_inst_floruit_dy) or $org/../c_inst_floruit_dy = 0)
            then ()
            else (attribute datingPoint {concat('#D',$org/../c_inst_floruit_dy/text())})
        }),
        
        if (empty($org/../c_by_nianhao_code) and empty ($org/../c_ey_nianhao_code))
        then ()
        else ( element date { attribute datingMethod {'chinTrad'},
            if (empty($org/../c_by_nianhao_code) or $org/../c_by_nianhao_code = 0)
            then ()
            else (attribute from-custom {concat('#R',$org/../c_by_nianhao_code/text(), '-', 
                                    $org/../c_by_nianhao_year/text(), '-',
                                    '年')}), 
            if (empty($org/../c_ey_nianhao_code) or $org/../c_ey_nianhao_code = 0)
            then ()
            else (attribute to-custom {concat('#R',$org/../c_ey_nianhao_code/text(), '-', 
                                    $org/../c_ey_nianhao_year/text(), '-',
                                    '年')})                    
        })
        },        
        if (empty($org/../c_notes))
        then ()
        else (element note {$org/../c_notes/text()})   
    }

};

let $test := $SOCIAL_INSTITUTION_CODES//c_inst_code[. > 0][. < 500]
let $full := $SOCIAL_INSTITUTION_CODES//c_inst_code[. > 0]

return
xmldb:store($target, 'listOrg.xml',
    <listOrg>
        {local:org($full)}
    </listOrg>    
) 