xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $BIOG_MAIN:= doc(concat($src, 'BIOG_MAIN.xml')); 

declare variable $BIOG_ADDR_CODES:= doc(concat($src, 'BIOG_ADDR_CODES.xml')); 
declare variable $BIOG_ADDR_DATA:= doc(concat($src, 'BIOG_ADDR_DATA.xml')); 

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




 
 
declare function local:pers-add ($resident as node()*) as node()* {
(:This function reads the BIOG_ADDR_DATA for a given c_personid and outputs tei:residence:)

(: TODO
- CODES c_note neds to go into ODD
:)
(:
tts_sysno] INTEGER,                             d
 [c_personid] INTEGER,                          x
 [c_addr_id] INTEGER,                           x
 [c_addr_type] INTEGER,                         x
 [c_sequence] INTEGER,                          x
 [c_firstyear] INTEGER,                         x
 [c_lastyear] INTEGER,                          x
 [c_source] INTEGER,                            x
 [c_pages] CHAR(255),                           d
 [c_notes] CHAR,                                 x
 [c_fy_nh_code] INTEGER,                        x
 [c_ly_nh_code] INTEGER,                        x
 [c_fy_nh_year] INTEGER,                        x
 [c_ly_nh_year] INTEGER,                        x
 [c_fy_range] INTEGER,                          d
 [c_ly_range] INTEGER,                          d
 [c_natal] INTEGER,                             x
 [c_fy_intercalary] BOOLEAN NOT NULL,        !
 [c_ly_intercalary] BOOLEAN NOT NULL,        !   
 [c_fy_month] INTEGER,                          x
 [c_ly_month] INTEGER,                          x
 [c_fy_day] INTEGER,                            x
 [c_ly_day] INTEGER,                            x
 [c_fy_day_gz] INTEGER,                        x
 [c_ly_day_gz] INTEGER,                        x 
 [c_created_by] CHAR(255),                      d
 [c_created_date] CHAR(255),                    d
 [c_modified_by] CHAR(255),                     d
 [c_modified_date] CHAR(255),                   d
 [c_delete] INTEGER)                             d
:)


for $address in $BIOG_ADDR_DATA//c_personid[. = $resident][. >0]
let $code := $BIOG_ADDR_CODES//c_addr_type[. = $address/../c_addr_type]
order by $address/../c_sequence

return 
    element residence { 
       attribute ref {concat('#PL', $address/../c_addr_id/text())},
       
       if ($code > 0)
       then (attribute key {$code/text()})
       else (),
       
       if (empty($address/../c_sequence) or $address/../c_sequence = 0)
       then ()
       else (attribute n {$address/../c_sequence/text()}), 
       
   (:   Dates ISO :)
       if (empty($address/../c_firstyear) or $address/../c_firstyear = 0)
       then ()
       else if ($address/../c_firstyear != 0 and $address/../c_fy_month != 0 and $address/../c_fy_day != 0)
            then (attribute from {
             string-join((local:isodate($address/../c_firstyear),
             functx:pad-integer-to-length($address/../c_fy_month, 2),
             functx:pad-integer-to-length($address/../c_fy_day, 2)), '-')})
            else if  ($address/../c_firstyear != 0 and $address/../c_fy_month != 0)
                then (attribute from {string-join((local:isodate($address/../c_firstyear),
                        functx:pad-integer-to-length($address/../c_fy_month, 2)), '-')})
                else (attribute from {local:isodate($address/../c_firstyear)}),
        
       if (empty($address/../c_lastyear) or $address/../c_lastyear = 0)
       then ()
       else if ($address/../c_lastyear != 0 and $address/../c_ly_month != 0 and $address/../c_ly_day != 0)
            then (attribute to {
             string-join((local:isodate($address/../c_lastyear),
             functx:pad-integer-to-length($address/../c_ly_month, 2),
             functx:pad-integer-to-length($address/../c_ly_day, 2)), '-')})
            else if  ($address/../c_lastyear != 0 and $address/../c_ly_month != 0)
                then (attribute to {string-join((local:isodate($address/../c_lastyear),
                        functx:pad-integer-to-length($address/../c_ly_month, 2)), '-')})
                else (attribute to {local:isodate($address/../c_lastyear)}),        
   (: Source   :)
       if (empty($address/../c_source) or $address/../c_source = 0)
       then ()
       else (attribute source {concat('#BIB', $address/../c_source/text())}),
       
    (: Desc :)
    
       if ($code < 1)
       then ()
       else (element state {
         if ($address/../c_natal = 0)
         then ()
         else (attribute type {'natal'}),
         
         element desc { attribute xml:lang {'zh-Hant'},
         $code/../c_addr_desc_chn/text()},
         element desc {attribute xml:lang {'en'},
        $code/../c_addr_desc/text()}
            }),
        
       (:     Date ZH     :)
       if (empty($address/../c_fy_nh_code) or $address/../c_fy_nh_code = 0) 
       then ()
       else (element date { 
                attribute calendar {'#chinTrad'},
                attribute period {concat('#R', $address/../c_fy_nh_code/text())},
                if ($address/../c_fy_nh_year > 0)
                then (concat($address/../c_fy_nh_year/text(), '年'))
                else (),
                
                if ($address/../c_fy_day_gz > 0)
                then (concat('-', $address/../c_fy_day_gz/text(), '日'))
                else ()
                }),
                
       if (empty($address/../c_ly_nh_code) or $address/../c_ly_nh_code = 0) 
       then ()
       else (element date { attribute calendar {'#chinTrad'},
                attribute period {concat('#R', $address/../c_ly_nh_code/text())},
                if ($address/../c_ly_nh_year > 0)
                then (concat($address/../c_ly_nh_year/text(), '年'))
                else (),
                
                if ($address/../c_ly_day_gz > 0)
                then (concat('-', $address/../c_ly_day_gz/text(), '日'))
                else ()
                }),
                    
       if (empty($address/../c_notes))
       then ()
       else (element note {$address/../c_notes/text()})
    }
};

declare function local:biog ($persons as node()*) as node()* {

for $person in $persons
let $bio-add := $BIOG_ADDR_DATA//c_personid[. = $person]

return 
    <person ana="historical" xml:id="{concat('BIO', $person/text())}">    
    {if (empty($bio-add)) 
    then ()
    else(local:pers-add($person))
        }
    </person>
};

let $test := $BIOG_MAIN//c_personid[. = 339453]
let $full := $BIOG_MAIN//c_personid[. > 0]

return

(:42346 FY 1209 FY-month 1159 :)

(:distinct-values($BIOG_ADDR_DATA//c_fy_month):)
    <listPerson>
        {local:biog($test)}
    </listPerson>   