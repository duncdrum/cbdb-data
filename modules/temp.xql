xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";


import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare function local:entry-new ($initiates as node()*) as node()* {
(: biog:entry expects persons from BIOG_MAIN and returns tei:event for entries into social institutions.
the output of biog:entry should match the structure of biog:event's ouput.

Note about 100 entries are tagede both by 7 specials and other (id =90) hence the filter for 
count($types) > 1 below. 
:)

(: TODO
what does c_exam_field point to nothing its a string zh-Hant only
use @role to "link to status of a place, or occupation of a person"!
@type = $type (99) -> label
@subtype = $code (>200) -> desc
@sortKey = sequence 
? = attempts
- @ana for s.th.
- $global:PARENTAL_STATUS_CODES
- see c_personid 914 for dual @type entries

entries should become a nested taxonomy to be @ref'ed
make sponsors into their own note element? @role?
parental status code?
institutional addressess via biog:org-add
switch to tei:education | tei:faith for entry type data
:)

for $initiate in $global:ENTRY_DATA//c_personid[. =$initiates]

let $code := $global:ENTRY_CODES//c_entry_code[. = $initiate/../c_entry_code]
let $type-rel := $global:ENTRY_CODE_TYPE_REL//c_entry_code[ . = $initiate/../c_entry_code]
let $type :=  $global:ENTRY_TYPES//c_entry_type[. = $type-rel/../c_entry_type]

(:
[tts_sysno] INTEGER, 
 [c_personid] INTEGER,                          x
 [c_entry_code] INTEGER,                        x
 [c_sequence] INTEGER,                          x
 [c_exam_rank] CHAR(255),                       x                       
 [c_kin_code] INTEGER,                          x
 [c_kin_id] INTEGER,                            !
 [c_assoc_code] INTEGER,                        x
 [c_assoc_id] INTEGER,                          !
 [c_year] INTEGER,                              x
 [c_age] INTEGER,                               !
 [c_nianhao_id] INTEGER,                       d
 [c_entry_nh_year] INTEGER,                    d
 [c_entry_range] INTEGER,                      d
 [c_inst_code] INTEGER NOT NULL,              !!!
 [c_inst_name_code] INTEGER NOT NULL,        !!!
 [c_exam_field] CHAR(255),                     x
 [c_addr_id] INTEGER,                           x
 [c_parental_status] INTEGER,                 !!!
 [c_attempt_count] INTEGER,                    x
 [c_source] INTEGER,                            x
 [c_pages] CHAR(255),                           d
 [c_notes] CHAR,                                 x
 [c_posting_notes] CHAR(255),                  !
 [c_created_by] CHAR(255),                      d
 [c_created_date] CHAR(255),                    d
 [c_modified_by] CHAR(255),                     d
 [c_modified_date] CHAR(255),                   d
:)

return
    element event{
        if (count($type) > 1)
        then (attribute type {$type[. < 90]/text()})
        else if (empty($type))
              then ()
              else (attribute type {$type/text()}),
        
        attribute subtype {$code/text()}, 
        
        if ($initiate/../c_year[. = 0] or empty($initiate/../c_year)) 
        then ()
        else (attribute when {cal:isodate($initiate/../c_year/text())}),
        
        if ($initiate/../c_addr_id[. = 0] or empty($initiate/../c_addr_id))
        then ()
        else (attribute where {concat('#PL', $initiate/../c_addr_id/text())}),
        
        attribute sortKey {$initiate/../c_sequence/text()},
        
        for $sponsor in $initiate
        return 
            if ($sponsor/../c_kin_id[. > 0] or $sponsor/../c_assoc_id[. > 0])
            then (attribute role {concat('#BIO', $sponsor/text())})
            else (),    
            
        if ($initiate/../c_source[. = 0] or empty($initiate/../c_source))
        then ()
        else (attribute source{concat('#BIB', $initiate/../c_source/text())}),
            element head {'entry'}, 
            if ($code[. < 1])
            then ()
            else(
                element label {attribute xml:lang {'zh-Hant'},
                    $code/../c_entry_desc_chn/text()},
                element label {attribute xml:lang{'en'},
                    $code/../c_entry_desc/text()}),   
                    
            if ($type[. < 1] or empty($type) )
            then ()
            else if (count($type) > 1) 
                  then (element desc { attribute type {$type[. < 90]/../c_entry_type_level/text()},
                            attribute subtype {$type[. < 90]/../c_entry_type_sortorder/text()},
                        element desc {attribute xml:lang {'zh-Hant'},
                            $type[. < 90]/../c_entry_type_desc_chn/text()},
                        element desc {attribute xml:lang{'en'},
                            $type[. < 90]/../c_entry_type_desc/text()}})
                  else (element desc { attribute type {$type/../c_entry_type_level/text()},
                            attribute subtype {$type/../c_entry_type_sortorder/text()},
                        element desc {attribute xml:lang {'zh-Hant'},
                            $type/../c_entry_type_desc_chn/text()},
                        element desc {attribute xml:lang{'en'},
                            $type/../c_entry_type_desc/text()}}), 
                    
            if ($initiate/../c_exam_field)
            then (element note{ attribute type {'field'},
                $initiate/../c_exam_field/text()})
            else (),
            
            if ($initiate/../c_attempt_count[. > 0]) 
            then (element note{ attribute type{'attempts'},
                $initiate/../c_attempt_count/text()})
            else (),
            
            if ($initiate/../c_exam_rank[. != '0']) 
            then (element note{ attribute type{'rank'},
                $initiate/../c_exam_rank/text()})
            else (),    
            
            if ($initiate/../c_notes)
            then (element note {$initiate/../c_notes/text()})
            else ()
    }               
};

declare function local:kin-new ($self as node()*) as node()* {
    
    (:This function takes persons via c_personid and returns a list kin group  relations.
It's structure is tied to biog:asso and changes should be made to both functions in concert.:)
    
    (:
[tts_sysno] INTEGER,                    x                [c_kincode] INTEGER PRIMARY KEY,   x
 [c_personid] INTEGER,                  x                [c_kin_pair1] INTEGER,              d
 [c_kin_id] INTEGER,                    x                [c_kin_pair2] INTEGER,              d
 [c_kin_code] INTEGER,                  x                [c_kin_pair_notes] CHAR(50),       d
 [c_source] INTEGER,                   x                  [c_kinrel_chn] CHAR(255),         x
 [c_pages] CHAR(255),                   d                 [c_kinrel] CHAR(255),             x
 [c_notes] CHAR,                        x                 [c_kinrel_alt] CHAR(255),         x
 [c_autogen_notes] CHAR,                  x               [c_pick_sorting] INTEGER,         x
 [c_created_by] CHAR(255),              d               [c_upstep] INTEGER,                 d
 [c_created_date] CHAR(255),            d               [c_dwnstep] INTEGER,                d
 [c_modified_by] CHAR(255),             d               [c_marstep] INTEGER,                d
 [c_modified_date] CHAR(255),           d               [c_colstep] INTEGER)                d
 :)
    
    (:9 basic categories of kinship Source: CBDB Manual p 13f
none of these is symmetrical hence there is no need for mutuality checks as in biog:asso
'e' Ego (the person whose kinship is being explored) 
'F' Father
'M' Mother
'B' Brother
'Z' Sister
'S' Son
'D' Daughter
'H' Husband
'W' Wife
'C' Concubine

'+' Older (e.g. older brother B+, 兄)
'-' Younger (e.g. younger sister 妹)
'*' Adopted heir ( as in S*, adopted son)
'°' Adopted
'!' Bastard
'^' Step- (as in S^ step-son)
'½'  half- (as in Z½ , half-sister)
'~' Nominal (as in M~ , legitimate wife as nominal mother to children of concubine)
'%' Promised husband or wife (marriage not completed at time of record)
'y' Youngest (e.g., Sy is the youngest known son)
'1' Numbers distinguish sequence (e.g., S1, S2 for first and second sons; W1, W2 for the first and the successor wives)
'n' precise generation unknown
'G-#', 'G+#' lineal ancestor (–) or descendant (+) of # generation №
'G-n', 'G+n', 'Gn' lineal kin of an unknown earlier generation (G-n), or unknown later generation (G+n), or unknown generation (Gn)
'G-#B', 'BG+#' a brother of a lineal ancestor of # generation; a brother’s lineal descendant of # generation
'K', 'K-#', 'K+#', 'Kn' Lineage kin, of the same, earlier (–), later (+) or unknown (n) generation. CBDB uses “lineage kin” for cases where kinship is attested but the exact relationship is not known. Lineage kin are presumably not lineal (direct descent) kin.
'K–', 'K+' Lineage kin of the same generation, younger (-) or elder (+).
'P', 'P-#', 'P+#', 'Pn' Kin related via father’s sisters or mother’s siblings, of the same, earlier (–), later (+) or unknown (n) generation. Signified by the term biao (表) in Chinese. (CBDB uses these codes only when the exact relationship is not known). 
'P–', 'P+' Kin related via father's sisters or mother's siblings, of the same generation, younger (-) or elder (+).
'A' Affine/Affinal kin, kin by marriage

NOT Documented
'(male)' -> ♂
'(female)' -> ♀
'©' -> of concubine
' (claimed)' -> 
' (eldest surviving son)' -> 
' (only ...)'
' (apical)'

:)
    
    (:it would be nice to find valid xml expressions for kinrel so they can be added to tei:relation as @name:)
    
    for $kin in $global:KIN_DATA//c_personid[. = $self]
    let $tie := $global:KINSHIP_CODES//c_kincode[. = $kin/../c_kin_code]
    
    (:let basic :=
 for $:)
    
    return
        element relation {
            attribute active {concat('#BIO', $kin/../c_personid/text())},
            attribute passive {concat('#BIO', $kin/../c_kin_id/text())},
            if (empty($tie/../c_kincode))
            then ()
            else (attribute key {$tie/../c_kincode/text()}),
            
            if (empty($tie/../c_pick_sorting))
            then ()
            else (attribute sortKey {$tie/../c_pick_sorting/text()}),
            
            if (empty($tie/../c_kinrel))
            then ()
            else (attribute name {
                    if (contains($tie/../c_kinrel/text(), ' ('))
                    then (substring-before($tie/../c_kinrel/text(), ' ('))
                    else if (contains($tie/../c_kinrel/text(), 'male)'))
                        then (replace(replace($tie/../c_kinrel/text(), '\(male\)', '♂'), '\(female\)', '♀'))
                        else(translate($tie/../c_kinrel/text(), '#', '№'))}),
                        
            if ($kin/../c_source[. > 0])
            then (attribute source {concat('#BIB', $kin/../c_source/text())})
            else (),
            
            if (empty($kin/../c_autogen_notes))
            then ()
            else (attribute type {'auto-generated'}),
            
            if (empty($tie/../c_kinrel_chn) and empty ($tie/../c_kinrel_alt))
            then ()
            else (element desc {
                    if ($kin/../c_notes)
                    then (element label {$kin/../c_notes/text()})
                    else (),
                    
                    element desc { attribute xml:lang {"zh-Hant"},
                        $tie/../c_kinrel_chn/text()},    
                    element desc {attribute xml:lang {"en"},
                        $tie/../c_kinrel_alt/text()}
                })
        }
};

declare function local:asso-new ($ego as node()*) as node()* {
    
(: This function records association data in Tei. It expects a person as input, 
to generate a list relations. 

The structure of its output should match the output of biog:kin

ASSOC_CODES contains both symmetrical and assymetrical relations, 
these are converted into tei:relation/@active || @passive  || @mutual
the following are still problematic:
let $passive := ('Executed at the order of', 'Killed by followers of',
                'was served by the medical arts of',
                'Funerary stele written (for a third party) at the request of',
                'Killed by followers of', 'His coalition attacked', 'Was claimed kin with')
                
let $active :=  ('Knew','Tried and found guilty'
       ,'Fought against the rebel','Hired to teach in lineage school' 
       ,'proceeded with (friendship)','Defeated in battle'
       ,'Treated with respect','Served as lady-in-waiting' 
       ,'friend to Y when Y was heir-apparent','recruited Y to be instructor at school,academy' 
       ,'saw off on journey','took as foster daughter'
       ,'Memorialized concerning','Took as foster son'
       ,'opposed militarily','Toady to Y'
       ,'Relied on book by','Refused affinal relation offered by'
       ,'Requested Funerary stele be written by','Requested Tomb stone (mubiao) be written by'
       ,'opposed assertion of emperorship by')
.

TODO
yet unused mediated relations , tei handles this quite easily use @role?

:)

(: REPORT
let $symmetry :=
    for $symmetric in $ASSOC_CODES//row
    where $symmetric/c_assoc_code = $symmetric/c_assoc_pair
    return
        $symmetric
    
let $assymetry := 
    for $assymetric in $ASSOC_CODES//row
    where $assymetric/c_assoc_code != $assymetric/c_assoc_pair
    return
        $assymetric
        
let $bys :=
(\: filters all */by pairs :\)
    for $by in $ASSOC_CODES//c_assoc_desc
    where contains($by/text(), ' by')
    return 
        $by
    
let $was :=
(\: filter all  was/of pairs:\)
    for $was in $ASSOC_CODES//c_assoc_desc
    where contains($was/text(), ' was')
    return
        $was
let $to :=
(\: filter all from/to pairs :\)
    for $to in $ASSOC_CODES//c_assoc_desc
    where contains($to/text(), ' to')
    return
        $to
    
let $report := 
    <report>
        <total>{count(//row)}</total>
        <unaccounted>{count(//row) - (count($assymetry) + count($symmetry))}</unaccounted>
        <symmetric>
            <sym_sum>{count($symmetry)}</sym_sum>
            <rest>{count(//row) - count($symmetry)}</rest>
        </symmetric>
        <assymetric>
            <assy_sum>{count($assymetry)}</assy_sum>
            <assy_by>{count($bys)*2}</assy_by>
            <rest>{count($assymetry) - count($bys)*2}</rest>
            <assy_was>{count($was)*2}</assy_was>
            <rest>{count($assymetry) - count($bys)*2 - count($was)*2}</rest>
            <assy_to>{count($to)*2}</assy_to>
        </assymetric>
    </report> 
:)

(:
[tts_sysno] INTEGER,                                d
 [c_assoc_code] INTEGER,                            x
 [c_personid] INTEGER,                              x
 [c_kin_code] INTEGER,                              
 [c_kin_id] INTEGER,                    
 [c_assoc_id] INTEGER,                              x
 [c_assoc_kin_code] INTEGER,                    
 [c_assoc_kin_id] INTEGER, 
 [c_tertiary_personid] INTEGER, 
 [c_assoc_count] INTEGER, 
 [c_sequence] INTEGER, 
 [c_assoc_year] INTEGER, 
 [c_source] INTEGER,                                x
 [c_pages] CHAR(255),                               d
 [c_notes] CHAR,                                     x
 [c_assoc_nh_code] INTEGER,                         
 [c_assoc_nh_year] INTEGER, 
 [c_assoc_range] INTEGER, 
 [c_addr_id] INTEGER, 
 [c_litgenre_code] INTEGER, 
 [c_occasion_code] INTEGER, 
 [c_topic_code] INTEGER, 
 [c_inst_code] INTEGER, 
 [c_inst_name_code] INTEGER, 
 [c_text_title] CHAR(255), 
 [c_assoc_claimer_id] INTEGER, 
 [c_assoc_intercalary] BOOLEAN NOT NULL, 
 [c_assoc_month] INTEGER, 
 [c_assoc_day] INTEGER, 
 [c_assoc_day_gz] INTEGER, 
 [c_created_by] CHAR(255),                          
 [c_created_date] CHAR(255), 
 [c_modified_by] CHAR(255), 
 [c_modified_date] CHAR(255))
:)
    
    (:count($ASSOC_DATA//c_assoc_id[. > 0][. < 500]) = 1726
whats up with $assoc_codes//c_assoc_role_type ?:)
    
    for $individual in $global:ASSOC_DATA//c_personid[. = $ego]
    let $friends := $individual/../c_assoc_id
    
    let $code := $global:ASSOC_CODES//c_assoc_code[. = $individual/../c_assoc_code]
    let $type-rel := $global:ASSOC_CODE_TYPE_REL//c_assoc_code[. = $individual/../c_assoc_code]
    let $type := $global:ASSOC_TYPES//c_assoc_type_id[. = $type-rel/../c_assoc_type_id]
    
    return        
        element relation {
            if ($code/text() = $code/../c_assoc_pair/text())
            then (attribute mutual {concat('#BIO', $friends/text(), ' ', 
                                       concat('#BIO', $individual/text()))})
            else (
                if (ends-with($code/../c_assoc_desc/text(), ' for')
                or ends-with($code/../c_assoc_desc/text(), ' to')
                or ends-with($code/../c_assoc_desc/text(), ' was)')
                or ends-with($code/../c_assoc_desc/text(), ' of')
                or ends-with($code/../c_assoc_desc/text(), 'ed')
                or ends-with($code/../c_assoc_desc/text(), ' with')
                or ends-with($code/../c_assoc_desc/text(), ' from')                
                or $code/../c_assoc_desc/text() eq 'Knew')
                then (attribute active {concat('#BIO', $individual/text())},
                       attribute passive {concat('#BIO', $friends/text())})
                else (attribute active {concat('#BIO', $friends/text())},
                       attribute passive {concat('#BIO', $individual/text())})
                ),
                       
            if (empty($type-rel/../c_assoc_type_id))
            then ()
            else (attribute key {$type-rel/../c_assoc_type_id/text()}),
            
            if (empty($type/../c_assoc_type_sortorder))
            then ()
            else (attribute sortKey {$type/../c_assoc_type_sortorder/text()}),
            
            if (empty($type/../c_assoc_type_short_desc))
            then ()
            else (attribute name {lower-case(translate($type/../c_assoc_type_short_desc/text(), ' ', '-'))}),         
           
            if ($individual/../c_source[. > 0])
            then (attribute source {concat('#BIB', $individual/../c_source/text())})
            else (),
            
            if (empty($code/../c_assoc_role_type))
            then ()
            else (
            element desc {
                if ($code/../c_assoc_role_type/text())
                then (attribute type {$code/../c_assoc_role_type/text()})
                else (),
                
                if ($individual/../c_notes)
                then (element label {$individual/../c_notes/text()})
                else (),
                                              
                element desc { attribute xml:lang {"zh-Hant"},
                    $code/../c_assoc_desc_chn/text(),
                    element label {$type/../c_assoc_type_desc_chn/text()}
                },
                
                 element desc { attribute xml:lang {"en"},
                    $code/../c_assoc_desc/text(),
                    element label {$type/../c_assoc_type_desc/text()}
                }
            })
        }

};

declare function local:pers-add-new ($resident as node()*) as node()* {
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


for $address in $global:BIOG_ADDR_DATA//c_personid[. = $resident][. > 0]
let $code := $global:BIOG_ADDR_CODES//c_addr_type[. = $address/../c_addr_type]
order by $address/../c_sequence

return 
    if ($address/../c_addr_id[. < 1] or empty($address/../c_addr_id) )
    then ()
    else (

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
             string-join((cal:isodate($address/../c_firstyear),
             functx:pad-integer-to-length($address/../c_fy_month, 2),
             functx:pad-integer-to-length($address/../c_fy_day, 2)), '-')})
            else if  ($address/../c_firstyear != 0 and $address/../c_fy_month != 0)
                then (attribute from {string-join((cal:isodate($address/../c_firstyear),
                        functx:pad-integer-to-length($address/../c_fy_month, 2)), '-')})
                else (attribute from {cal:isodate($address/../c_firstyear)}),
        
       if (empty($address/../c_lastyear) or $address/../c_lastyear = 0)
       then ()
       else if ($address/../c_lastyear != 0 and $address/../c_ly_month != 0 and $address/../c_ly_day != 0)
            then (attribute to {
             string-join((cal:isodate($address/../c_lastyear),
             functx:pad-integer-to-length($address/../c_ly_month, 2),
             functx:pad-integer-to-length($address/../c_ly_day, 2)), '-')})
            else if  ($address/../c_lastyear != 0 and $address/../c_ly_month != 0)
                then (attribute to {string-join((cal:isodate($address/../c_lastyear),
                        functx:pad-integer-to-length($address/../c_ly_month, 2)), '-')})
                else (attribute to {cal:isodate($address/../c_lastyear)}),        
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
    })
};

let $test := $global:BIOG_MAIN//c_personid[. = 38988]
return
(:    $test/..:)

<fix>
    <old>{biog:pers-add($test)}</old>
    <new>{local:pers-add-new($test)}</new>
</fix>