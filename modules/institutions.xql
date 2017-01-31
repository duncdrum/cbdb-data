xquery version "3.0";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
(:import module namespace functx = "http://www.functx.com";:)

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare namespace org = "http://exist-db.org/apps/cbdb-data/institutions";

declare default element namespace "http://www.tei-c.org/ns/1.0";


(:local:org does what biographies does for persons for institutions.:)

declare function org:org ($institutions as node()*) as item()* {
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

let $name := $global:SOCIAL_INSTITUTION_NAME_CODES//no:c_inst_name_code[. = $org/../no:c_inst_name_code]
let $type := $global:SOCIAL_INSTITUTION_TYPES//no:c_inst_type_code[. = $org/../no:c_inst_type_code]
let $alt := $global:SOCIAL_INSTITUTION_ALTNAME_DATA//no:c_inst_code[. = $org]
let $alt-type := $global:SOCIAL_INSTITUTION_ALTNAME_CODES//no:c_inst_altname_type[. = $alt/../no:c_inst_altname_type]

let $addr := $global:SOCIAL_INSTITUTION_ADDR//no:c_inst_code[. = $org]
let $addr-type := $global:SOCIAL_INSTITUTION_ADDR_TYPES//no:c_inst_addr_type[. = $addr/../no:c_inst_addr_type]

return
    global:validate-fragment(element org { attribute xml:id {concat('ORG', $org/text())},
        attribute ana {'historical'},
        switch ($type)
            case '1' return attribute role {'academy'}
            case '2' return attribute role {'buddhist'}
            case '3' return attribute role {'daoist'}
            default return (),
        if (empty($org/../no:c_source))
        then ()
        else (attribute source {concat('#BIB', $org/../no:c_source/text())}),
        element orgName { attribute type {'main'},
            element orgName {attribute xml:lang {'zh-Hant'},
                $name/../no:c_inst_name_hz/text()},
            element orgName {attribute xml:lang {'zh-Latn-alalc97'},
                $name/../no:c_inst_name_py/text()},
            if (empty($alt-type))    
            then ()
            else ( element orgName { attribute type {'alias'},
                 element orgName {attribute xml:lang {'zh-Hant'},
                    $alt-type/../no:c_inst_altname_chn/text()},
                 element orgName {attribute xml:lang {'zh-Latn-alalc97'},
                    $alt-type/../no:c_inst_altname_desc/text()}
            }),
            
        if (empty ($org/../no:c_inst_begin_year) and empty ($org/../no:c_inst_end_year))
        then ()
        else (element date {
            if (empty($org/../no:c_inst_begin_year))
            then ()
            else (attribute from {cal:isodate($org/../no:c_inst_begin_year)}),
            if (empty($org/../no:c_inst_end_year))
            then ()
            else (attribute to {cal:isodate($org/../no:c_inst_end_year)})       
        }),
        
        if (empty ($org/../no:c_inst_first_known_year) and empty ($org/../no:c_inst_last_known_year))
        then ()
        else (element date {
            if (empty($org/../no:c_inst_first_known_year))
            then ()
            else (attribute notBefore {cal:isodate($org/../no:c_inst_first_known_year)}),
            if (empty($org/../no:c_inst_last_known_year))
            then ()
            else (attribute notAfter {cal:isodate($org/../no:c_inst_last_known_year)})       
        }), 
        (: Full Chinese Range start and end ? :)
        if ($org/../no:c_inst_begin_dy > 0 and $org/../no:c_by_nianhao_code > 0
            and $org/../no:c_inst_end_dy > 0 and $org/../no:c_ey_nianhao_code > 0)
        then (cal:custo-date-range($org/../no:c_inst_begin_dy, $org/../no:c_inst_end_dy,
                $org/../no:c_by_nianhao_code, $org/../no:c_ey_nianhao_code, 
                $org/../no:c_by_nianhao_year,  $org/../no:c_ey_nianhao_year, 
                'R'))
        (:      Is there more then just a dynasty ?         :)
        else if ($org/../no:c_inst_begin_dy > 0 and $org/../no:c_by_nianhao_code > 0) 
              then (cal:custo-date-point($org/../no:c_inst_begin_dy, $org/../no:c_by_nianhao_code, $org/../no:c_by_nianhao_year, 'Start'))
              else if ($org/../no:c_inst_end_dy > 0 and $org/../no:c_ey_nianhao_code > 0)
                then (cal:custo-date-point($org/../no:c_inst_end_dy, $org/../no:c_ey_nianhao_code, $org/../no:c_ey_nianhao_year, 'End'))
        (:        There is only a dynasty        :)
                else if ($org/../no:c_inst_begin_dy > 0)
                      then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D',$org/../no:c_inst_begin_dy/text())},
                                    $global:DYNASTIES//no:c_dy[. = $org/../no:c_inst_begin_dy/text()]/../no:c_dynasty_chn/text()})
                      else if ($org/../no:c_inst_end_dy > 0)
                            then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D',$org/../no:c_inst_end_dy/text())},
                                    $global:DYNASTIES//no:c_dy[. = $org/../no:c_inst_end_dy/text()]/../no:c_dynasty_chn/text()})
                            else if ($org/../no:c_inst_floruit_dy > 0)
                                then (element date { attribute calendar {'#chinTrad'},
                                    attribute period {concat('#D', $org/../no:c_inst_floruit_dy/text())},
                                    $global:DYNASTIES//no:c_dy[. = $org/../no:c_inst_floruit_dy/text()]/../no:c_dynasty_chn/text()})
                                else ()    

        }, 
        if (empty($addr) or $addr = 0)
        then ()
        else (element place {attribute sameAs {concat('#PL', $addr/text())}, 
            if (empty($addr/../no:c_source) or $addr/../no:c_source = 0)
            then ()
            else (attribute source {concat('#BIB', $addr/../no:c_source/text())}), 
            
            if (empty($addr/../no:inst_xcoord) or $addr/../no:inst_xcoord = 0)
            then ()
            else (element location {
                    element geo {concat($addr/../no:inst_xcoord/text(), ' ', $addr/../no:inst_ycoord/text())}
                    }),            
            
            if (empty($addr/../no:c_notes) or $org/../no:c_notes/text() = $addr/../no:c_notes/text())
            then ()
            else (element note {$addr/../no:c_notes/text()})            
            }),
        if (empty($org/../no:c_notes))
        then ()
        else (element note {$org/../no:c_notes/text()})   
    }, 'org')
};

let $test := $global:SOCIAL_INSTITUTION_CODES//no:c_inst_code[. > 0][. < 500]
let $full := $global:SOCIAL_INSTITUTION_CODES//no:c_inst_code[. > 0]

return

xmldb:store($global:target, $global:institution,
    <listOrg>
        {org:org($full)}
    </listOrg>) 