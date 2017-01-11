xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $BIOG_MAIN:= doc(concat($src, 'BIOG_MAIN.xml')); 

declare variable $BIOG_INST_CODES:= doc(concat($src, 'BIOG_INST_CODES.xml')); 
declare variable $BIOG_INST_DATA:= doc(concat($src, 'BIOG_INST_DATA.xml')); 

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


 
 
declare function local:inst-add ($participant as node()*) as node()* {
(:This function reads the BIOG_INST_DATA for a given c_personid and outputs tei:event:)

(: TODO
- 
:)

(:
 [c_personid] INTEGER,                    x                   [c_bi_role_code] INTEGER PRIMARY KEY,                                                                 
 [c_inst_name_code] INTEGER,             d                   [c_bi_role_desc] CHAR(255), 
 [c_inst_code] INTEGER,                   x                   [c_bi_role_chn] CHAR(255),                                                                 
 [c_bi_role_code] INTEGER,                                  [c_notes] CHAR(255))
 [c_bi_begin_year] INTEGER,              x
 [c_bi_by_nh_code] INTEGER, 
 [c_bi_by_nh_year] INTEGER, 
 [c_bi_by_range] INTEGER,                d
 [c_bi_end_year] INTEGER,                x
 [c_bi_ey_nh_code] INTEGER, 
 [c_bi_ey_nh_year] INTEGER, 
 [c_bi_ey_range] INTEGER,                 d
 [c_source] INTEGER,                       x
 [c_pages] CHAR(255),                      d
 [c_notes] CHAR,                            x
 [c_created_by] CHAR(255),                d  
 [c_created_date] CHAR(255),              d  
 [c_modified_by] CHAR(255),               d  
 [c_modified_date] CHAR(255),             d  
:)


for $address in $BIOG_INST_DATA//c_personid[. = $participant][. > 0]
let $code := $BIOG_INST_CODES//c_addr_type[. = $address/../c_addr_type]

let $dy_by := $DYNASTIES//c_dy[. = $NIAN_HAO//c_nianhao_id[. = $address/../c_bi_by_nh_code]/../c_dy]/../c_sort
let $dy_ey := $DYNASTIES//c_dy[. = $NIAN_HAO//c_nianhao_id[. = $address/../c_bi_ey_nh_code]/../c_dy]/../c_sort

let $cal-ZH := doc(concat($target, 'cal_ZH.xml'))
let $cal-path := $cal-ZH/tei:taxonomy/tei:taxonomy/tei:category
let $motto := count($cal-path/tei:category[@xml:id = concat('R', $reign/text())]/preceding-sibling::tei:category) +1

return 
    element event { 
       attribute where {concat('#ORG', $address/../c_inst_code/text())},
       
       if ($code > 0)
       then (attribute key {$code/text()})
       else (),    
       
   (:   Dates :)
       if (empty($address/../c_bi_begin_year) or $address/../c_bi_begin_year = 0)
       then ()
       else (attribute from {local:isodate($address/../c_firstyear)}),
        
       if (empty($address/../c_bi_end_year) or $address/../c_bi_end_year = 0)
       then ()
       else (attribute to {local:isodate($address/../c_lastyear)}),
       
       if ((empty($address/../c_bi_by_nh_code) or $address/../c_bi_by_nh_code = 0)
          and (empty($address/../c_bi_ey_nh_code) or $address/../c_bi_ey_nh_code = 0))
       then ()
       else (attribute datingMethod {'#chinTrad'}),
       
       
       if (empty($address/../c_bi_by_nh_code) or $address/../c_bi_by_nh_code = 0) 
       then ()
       else (attribute from-custom {
                if ($address/../c_bi_by_nh_year > 0)
                then (string-join(
                        (concat('D', $dy_by), concat('R',$address/../c_bi_by_nh_code), concat('Y', $address/../c_bi_by_nh_year)),'-')
                      )
                else (string-join(
                        (concat('D', $dy_by), concat('R',$address/../c_bi_by_nh_code)),'-')
                      ),
       
       if (empty($address/../c_bi_ey_nh_code) or $address/../c_bi_ey_nh_code = 0) 
       then ()
       else (attribute to-custom {
                if ($address/../c_bi_ey_nh_year > 0)
                then (string-join(
                        (concat('D', $dy_by), concat('R',$address/../c_bi_ey_nh_code), concat('Y', $address/../c_bi_ey_nh_year)),'-')
                      )
                else (string-join(
                        (concat('D', $dy_by), concat('R',$address/../c_bi_ey_nh_code)),'-')
                      ),
       
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
       
                    
       if (empty($address/../c_notes))
       then ()
       else (element note {$address/../c_notes/text()})
    }
};

declare function local:biog ($persons as node()*) as node()* {

for $person in $persons
let $bio-inst := $BIOG_INST_DATA//c_personid[. = $person]

return 
    <person ana="historical" xml:id="{concat('BIO', $person/text())}">    
    {if (empty($bio-inst)) 
    then ()
    else(local:inst-add($person))
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