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

declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 

(:local:org does what biographies does for persons for institutions.:)
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

declare function local:custo-date-point (
    $dynasty as node()*, 
    $reign as node()*,
    $year as xs:string*, 
    $type as xs:string?) as node()*{

(:This function takes chinese calendar date points ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. 

The normalized format takes DYNASTY//c_sort which is specific to CBDB,  
followed by the sequence of reigns determined by their position in cal_ZH.xml
followed by the Year number.D(\d*)-R(\d*)-(\d*)
:)

(:TODO
- getting to a somehwhat noramlized useful representation ofChinese Reign dates is tricky.
    inconsinsten pinyin for Nianhao creates ambigous and ugly dates.
- handle //c_dy[. = 0] stuff
- add @period with #d42 #R123
- find a way to prevent empty attributes more and better logic FTW
- If only a dynasty is known lets hear it,
the others are dropped since only a year or nianhao is of little information value. 
:)

let $cal-ZH := doc(concat($target, 'cal_ZH.xml'))
let $cal-path := $cal-ZH/tei:taxonomy/tei:taxonomy/tei:category

let $dy := $DYNASTIES//c_dy[. = $dynasty/text()]
let $motto := count($cal-path/tei:category[@xml:id = concat('R', $reign/text())]/preceding-sibling::tei:category) +1

        
let $date-norm := string-join((concat('D', $dy/../c_sort), concat('R',$motto), concat('Y', $year)),'-')
        


let $date-orig := string-join(($dy/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reign/text()]/../c_nianhao_chn,
                    concat($year, '年')),'-')


(:$type has two basic values
defaults to when
S/E = start / end
c/u for certain/uncertain
:)

           

return 
    element date { attribute datingMethod {'#chinTrad'}, 
        attribute calendar {'#chinTrad'},
        switch
            ($type)
                case 'uStart'return attribute notBefore-custom {$date-norm}
                case 'uEnd' return attribute notAfter-custom {$date-norm}
                case 'Start' return attribute from-custom {$date-norm}
                case 'End' return attribute to-custom {$date-norm}
                default return  attribute when-custom  {$date-norm},
                $date-orig                  
    }
};

declare function local:custo-date-range (
    $dy-start as node()*, $dy-end as node()*,
    $reg-start as node()*, $reg-end as node()*, 
    $year-start as xs:string*, $year-end as xs:string*, 
    $type as xs:string?) as node()*{

(:this function takes chinese calendar date ranges ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. :)

let $cal-ZH := doc(concat($target, 'cal_ZH.xml'))
let $cal-path := $cal-ZH/tei:taxonomy/tei:taxonomy/tei:category

let $DS := $DYNASTIES//c_dy[. = $dy-start/text()]
let $DE := $DYNASTIES//c_dy[. = $dy-end/text()]

let $RS := count($cal-path/tei:category[@xml:id = concat('R',  $reg-start/text())]/preceding-sibling::tei:category) +1
let $RE := count($cal-path/tei:category[@xml:id = concat('R',  $reg-end/text())]/preceding-sibling::tei:category) +1

        
let $start-norm := string-join((concat('D', $DS/../c_sort), concat('R',$RS), concat('Y', $year-start)),'-')
let $end-norm := string-join((concat('D', $DE/../c_sort), concat('R',$RE), concat('Y', $year-end)),'-')       


                  
let $start-orig := string-join(($DS/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reg-start/text()]/../c_nianhao_chn,
                    concat($year-start, '年')),'-')  
                    
let $end-orig := string-join(($DE/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reg-end/text()]/../c_nianhao_chn,
                    concat($year-end, '年')),'-')                 
                    
(:$type 
defaults to certain dates = from/when
'uRange' returns uncertain date-ranges

:)                    

return     
        switch
            ($type)
                case 'uRange'return element date { attribute datingMethod {'#chinTrad'}, 
                                            attribute calendar {'#chinTrad'},
                                            attribute notBefore-custom {$start-norm},
                                       attribute notAfter-custom {$end-norm},
                                       concat($start-orig, ' ',$end-orig)                 
                                        }
                default return element date { attribute datingMethod {'#chinTrad'}, 
                                            attribute calendar {'#chinTrad'}, 
                                        attribute from-custom {$start-norm}, 
                                        attribute to-custom  {$end-norm},
                                    concat($start-orig, ' ',$end-orig)                 
                                    }
};

declare function local:org ($institutions as node()*) as node()* {
(:This function writes the org / orgName elements to be stored in listOrg.xml.
altName tables, and address-type tables are empty!!
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
 [c_ey_year_range] INTEGER,                    x                  
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

let $addr := $SOCIAL_INSTITUTION_ADDR//c_inst_code[. = $org]
let $addr-type := $SOCIAL_INSTITUTION_ADDR_TYPES//c_inst_addr_type[. = $addr/../c_inst_addr_type]

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
            else (attribute notBefore {local:isodate($org/../c_inst_first_known_year)}),
            if (empty($org/../c_inst_last_known_year))
            then ()
            else (attribute notAfter {local:isodate($org/../c_inst_last_known_year)})       
        }), 
        (: Full Chinese Range start and end ? :)
        if ($org/../c_inst_begin_dy > 0 and $org/../c_by_nianhao_code > 0
            and $org/../c_inst_end_dy > 0 and $org/../c_ey_nianhao_code > 0)
        then (local:custo-date-range($org/../c_inst_begin_dy, $org/../c_inst_end_dy,
                $org/../c_by_nianhao_code, $org/../c_ey_nianhao_code, 
                $org/../c_by_nianhao_year,  $org/../c_ey_nianhao_year, 
                'R'))
        (:      Is there more then just a dynasty ?         :)
        else if ($org/../c_inst_begin_dy > 0 and $org/../c_by_nianhao_code > 0) 
              then (local:custo-date-point($org/../c_inst_begin_dy, $org/../c_by_nianhao_code, $org/../c_by_nianhao_year, 'Start'))
              else if ($org/../c_inst_end_dy > 0 and $org/../c_ey_nianhao_code > 0)
                then (local:custo-date-point($org/../c_inst_end_dy, $org/../c_ey_nianhao_code, $org/../c_ey_nianhao_year, 'End'))
        (:        There is only a dynasty        :)
                else if ($org/../c_inst_begin_dy > 0)
                      then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D',$org/../c_inst_begin_dy/text())},
                                    $DYNASTIES//c_dy[. = $org/../c_inst_begin_dy/text()]/../c_dynasty_chn/text()})
                      else if ($org/../c_inst_end_dy > 0)
                            then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D',$org/../c_inst_end_dy/text())},
                                    $DYNASTIES//c_dy[. = $org/../c_inst_end_dy/text()]/../c_dynasty_chn/text()})
                            else if ($org/../c_inst_floruit_dy > 0)
                                then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D', $org/../c_inst_floruit_dy/text())},
                                    $DYNASTIES//c_dy[. = $org/../c_inst_floruit_dy/text()]/../c_dynasty_chn/text()})
                                else ()    

        }, 
        if (empty($addr) or $addr = 0)
        then ()
        else (element place {attribute sameAs {concat('#PL', $addr/text())}, 
            if (empty($addr/../c_source) or $addr/../c_source = 0)
            then ()
            else (attribute source {concat('#BIB', $addr/../c_source/text())}), 
            
            if (empty($addr/../inst_xcoord) or $addr/../inst_xcoord = 0)
            then ()
            else (element location {
                    element geo {concat($addr/../inst_xcoord/text(), ' ', $addr/../inst_ycoord/text())}
                    }),            
            
            if (empty($addr/../c_notes) or $org/../c_notes/text() = $addr/../c_notes/text())
            then ()
            else (element note {$addr/../c_notes/text()})            
            }),
        if (empty($org/../c_notes))
        then ()
        else (element note {$org/../c_notes/text()})   
    }

};

let $test := $SOCIAL_INSTITUTION_CODES//c_inst_code[. > 0][. < 500]
let $full := $SOCIAL_INSTITUTION_CODES//c_inst_code[. > 0]

return
(:    <listOrg>
        {local:org($full)}
    </listOrg> :)

xmldb:store($target, 'listOrg.xml',
    <listOrg>
        {local:org($full)}
    </listOrg>    
) 