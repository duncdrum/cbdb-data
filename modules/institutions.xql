xquery version "3.0";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
(:import module namespace functx = "http://www.functx.com";:)

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace org = "http://exist-db.org/apps/cbdb-data/institutions";
declare namespace output = "http://www.tei-c.org/ns/1.0";


(:local:org does what biographies does for persons for institutions.:)

declare function org:org ($institutions as node()*) as node()* {
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

let $name := $global:SOCIAL_INSTITUTION_NAME_CODES//c_inst_name_code[. = $org/../c_inst_name_code]
let $type := $global:SOCIAL_INSTITUTION_TYPES//c_inst_type_code[. = $org/../c_inst_type_code]
let $alt := $global:SOCIAL_INSTITUTION_ALTNAME_DATA//c_inst_code[. = $org]
let $alt-type := $global:SOCIAL_INSTITUTION_ALTNAME_CODES//c_inst_altname_type[. = $alt/../c_inst_altname_type]

let $addr := $global:SOCIAL_INSTITUTION_ADDR//c_inst_code[. = $org]
let $addr-type := $global:SOCIAL_INSTITUTION_ADDR_TYPES//c_inst_addr_type[. = $addr/../c_inst_addr_type]

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
            element orgName {attribute xml:lang {'zh-Latn-alalc97'},
                $name/../c_inst_name_py/text()},
            if (empty($alt-type))    
            then ()
            else ( element orgName { attribute type {'alias'},
                 element orgName {attribute xml:lang {'zh-Hant'},
                    $alt-type/../c_inst_altname_chn/text()},
                 element orgName {attribute xml:lang {'zh-Latn-alalc97'},
                    $alt-type/../c_inst_altname_desc/text()}
            }),
            
        if (empty ($org/../c_inst_begin_year) and empty ($org/../c_inst_end_year))
        then ()
        else (element date {
            if (empty($org/../c_inst_begin_year))
            then ()
            else (attribute from {cal:isodate($org/../c_inst_begin_year)}),
            if (empty($org/../c_inst_end_year))
            then ()
            else (attribute to {cal:isodate($org/../c_inst_end_year)})       
        }),
        
        if (empty ($org/../c_inst_first_known_year) and empty ($org/../c_inst_last_known_year))
        then ()
        else (element date {
            if (empty($org/../c_inst_first_known_year))
            then ()
            else (attribute notBefore {cal:isodate($org/../c_inst_first_known_year)}),
            if (empty($org/../c_inst_last_known_year))
            then ()
            else (attribute notAfter {cal:isodate($org/../c_inst_last_known_year)})       
        }), 
        (: Full Chinese Range start and end ? :)
        if ($org/../c_inst_begin_dy > 0 and $org/../c_by_nianhao_code > 0
            and $org/../c_inst_end_dy > 0 and $org/../c_ey_nianhao_code > 0)
        then (cal:custo-date-range($org/../c_inst_begin_dy, $org/../c_inst_end_dy,
                $org/../c_by_nianhao_code, $org/../c_ey_nianhao_code, 
                $org/../c_by_nianhao_year,  $org/../c_ey_nianhao_year, 
                'R'))
        (:      Is there more then just a dynasty ?         :)
        else if ($org/../c_inst_begin_dy > 0 and $org/../c_by_nianhao_code > 0) 
              then (cal:custo-date-point($org/../c_inst_begin_dy, $org/../c_by_nianhao_code, $org/../c_by_nianhao_year, 'Start'))
              else if ($org/../c_inst_end_dy > 0 and $org/../c_ey_nianhao_code > 0)
                then (cal:custo-date-point($org/../c_inst_end_dy, $org/../c_ey_nianhao_code, $org/../c_ey_nianhao_year, 'End'))
        (:        There is only a dynasty        :)
                else if ($org/../c_inst_begin_dy > 0)
                      then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D',$org/../c_inst_begin_dy/text())},
                                    $global:DYNASTIES//c_dy[. = $org/../c_inst_begin_dy/text()]/../c_dynasty_chn/text()})
                      else if ($org/../c_inst_end_dy > 0)
                            then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D',$org/../c_inst_end_dy/text())},
                                    $global:DYNASTIES//c_dy[. = $org/../c_inst_end_dy/text()]/../c_dynasty_chn/text()})
                            else if ($org/../c_inst_floruit_dy > 0)
                                then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D', $org/../c_inst_floruit_dy/text())},
                                    $global:DYNASTIES//c_dy[. = $org/../c_inst_floruit_dy/text()]/../c_dynasty_chn/text()})
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

let $test := $global:SOCIAL_INSTITUTION_CODES//c_inst_code[. > 0][. < 500]
let $full := $global:SOCIAL_INSTITUTION_CODES//c_inst_code[. > 0]

return

xmldb:store($global:target, $global:institution,
    <listOrg>
        {org:org($full)}
    </listOrg>    
) 