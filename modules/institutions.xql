xquery version "3.0";

(:~
: This module does what biographies does for persons for institutions.
:
: @author Duncan Paterson
: @version 0.7
:
: @return listOrg.xml:)

module namespace org="http://exist-db.org/apps/cbdb-data/institutions";

(:import module namespace functx = "http://www.functx.com";:)
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare 
    %test:pending("validation as test")
function org:org ($institutions as node()*, $mode as xs:string?) as item()* {
(:~ 
: This function transforms data from SOCIAL_INSTITUTION_CODES, SOCIAL_INSTITUTION_NAME_CODES, 
: SOCIAL_INSTITUTION_TYPES,  SOCIAL_INSTITUTION_ALTNAME_DATA, SOCIAL_INSTITUTION_ALTNAME_CODES, 
: SOCIAL_INSTITUTION_ADDR, and SOCIAL_INSTITUTION_ADDR_TYPES into TEI. 
:
: For now there are only three ``role`` attribute values: academy, buddhist, and daoist. 
:
: However, the altName tables, and address-type tables are empty!
:
: @param $institutions is a ``c_inst_code``
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
:
: @return ``<org>...</org>``:)

let $output := 
    for $org in $institutions
    
    let $name := $global:SOCIAL_INSTITUTION_NAME_CODES//no:c_inst_name_code[. = $org/../no:c_inst_name_code]
    let $type := $global:SOCIAL_INSTITUTION_TYPES//no:c_inst_type_code[. = $org/../no:c_inst_type_code]
    let $alt := $global:SOCIAL_INSTITUTION_ALTNAME_DATA//no:c_inst_code[. = $org]
    let $alt-type := $global:SOCIAL_INSTITUTION_ALTNAME_CODES//no:c_inst_altname_type[. = $alt/../no:c_inst_altname_type]
    
    let $addr := $global:SOCIAL_INSTITUTION_ADDR//no:c_inst_code[. = $org]
    let $addr-type := $global:SOCIAL_INSTITUTION_ADDR_TYPES//no:c_inst_addr_type[. = $addr/../no:c_inst_addr_type]
    
    order by number($org/../no:c_inst_code)
    return
        element org { attribute ana {'historical'},            
            for $att in $org/../*[. != '0']
            order by ($att)
            return 
                typeswitch($att)
                    case element (no:c_inst_code) return attribute xml:id {concat('ORG', $att/text())}
                    case element (no:c_inst_type_code) return switch ($type)
                            case '1' return attribute role {'academy'}
                            case '2' return attribute role {'buddhist'}
                            case '3' return attribute role {'daoist'}
                            default return ()
                    case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
                default return (),
            
            element orgName { attribute type {'main'},
                element orgName {attribute xml:lang {'zh-Hant'},
                    $name/../no:c_inst_name_hz/text()},
                element orgName {attribute xml:lang {'zh-Latn-alalc97'},
                    normalize-space($name/../no:c_inst_name_py/text())},
                    
                if (empty($alt-type))    
                then ()
                else ( element orgName { attribute type {'alias'},
                     element orgName {attribute xml:lang {'zh-Hant'},
                        $alt-type/../no:c_inst_altname_chn/text()},
                     element orgName {attribute xml:lang {'zh-Latn-alalc97'},
                        $alt-type/../no:c_inst_altname_desc/text()}
                }),
            (: Western Dates contains a hack to filter 809 Qing dynasty dates with year = 0:)
            if ((empty($org/../no:c_inst_begin_year) or $org/../no:c_inst_begin_year = 0) and 
                empty($org/../no:c_inst_end_year) and empty($org/../no:c_inst_first_known_year) and 
                empty($org/../no:c_inst_last_known_year))
            then ()
            else (element date {
                for $iso in $org/../*[. != '0']
                order by local-name($iso)
                return
                    typeswitch($iso)
                        case element (no:c_inst_begin_year) return attribute from {cal:isodate($iso)}
                        case element (no:c_inst_end_year) return attribute to {cal:isodate($iso)}
                        case element (no:c_inst_first_known_year) return attribute notBefore {cal:isodate($iso)}
                        case element (no:c_inst_last_known_year) return attribute notAfter {cal:isodate($iso)}
                    default return ()}),
            
            (: Chinese Range has both start and end ? :)
            if ($org/../no:c_inst_begin_dy > 0 and $org/../no:c_by_nianhao_code > 0 and
                $org/../no:c_inst_end_dy > 0 and $org/../no:c_ey_nianhao_code > 0)
            then (cal:custo-date-range($org/../no:c_inst_begin_dy, $org/../no:c_inst_end_dy,
                    $org/../no:c_by_nianhao_code, $org/../no:c_ey_nianhao_code, 
                    $org/../no:c_by_nianhao_year,  $org/../no:c_ey_nianhao_year, 
                    'R'))
            (: Is there more then just a dynasty ? :)
            else if ($org/../no:c_inst_begin_dy > 0 and $org/../no:c_by_nianhao_code > 0) 
                  then (cal:custo-date-point($org/../no:c_inst_begin_dy, $org/../no:c_by_nianhao_code, $org/../no:c_by_nianhao_year, 'Start'))
                  else if ($org/../no:c_inst_end_dy > 0 and $org/../no:c_ey_nianhao_code > 0)
                        then (cal:custo-date-point($org/../no:c_inst_end_dy, $org/../no:c_ey_nianhao_code, $org/../no:c_ey_nianhao_year, 'End'))
                (: There is only a dynasty :)
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
            
        (: ADDRESS :)
            if (empty($addr) or $addr = 0)
            then ()
            else (element place { attribute sameAs {concat('#PL', $addr/text())}, 
                if (empty($addr/../no:c_source) or $addr/../no:c_source = 0)
                then ()
                else (attribute source {concat('#BIB', $addr/../no:c_source/text())}), 
                
                for $n in $addr/../*[. != '0']
                order by local-name($n)
                return
                    typeswitch($n)
                        case element (no:inst_xcoord) return element location {
                            element geo {concat($n/text(), ' ', $addr/../no:inst_ycoord/text())}}
                        case element (no:c_notes) return 
                            if ($n = $org/../no:c_notes) 
                            then () 
                            else(element note {$n/text()})
                    default return ()}),                    
                
            if (empty($org/../no:c_notes))
            then ()
            else (element note {$org/../no:c_notes/text()})   
    }
return 
    switch($mode)
        case 'v' return global:validate-fragment($output, 'org')
        case 'd' return global:validate-fragment($output, 'org')[1]
    default return $output 
};

declare %private function org:write($item as item()*) as item()* {
let $test := $global:SOCIAL_INSTITUTION_CODES//no:c_inst_code[. > 0][. < 500]
let $full := $global:SOCIAL_INSTITUTION_CODES//no:c_inst_code[. > 0]

return

xmldb:store($global:target, $global:institution,
    <listOrg>
        {org:org($full, 'v')}
    </listOrg>) 
};