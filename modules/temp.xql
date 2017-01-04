xquery version "3.0";

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace functx = "http://www.functx.com";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $BIOG_MAIN := doc(concat($src, 'BIOG_MAIN.xml'));
declare variable $ALTNAME_CODES := doc(concat($src, 'ALTNAME_CODES.xml'));
declare variable $ALTNAME_DATA := doc(concat($src, 'ALTNAME_DATA.xml'));
declare variable $ASSOC_CODES := doc(concat($src, 'ASSOC_CODES.xml'));
declare variable $ASSOC_CODE_TYPE_REL := doc(concat($src, 'ASSOC_CODE_TYPE_REL.xml'));
declare variable $ASSOC_DATA := doc(concat($src, 'ASSOC_DATA.xml'));
declare variable $ASSOC_TYPES := doc(concat($src, 'ASSOC_TYPES.xml'));



declare variable $KINSHIP_CODES := doc(concat($src, 'KINSHIP_CODES.xml'));
declare variable $KIN_DATA := doc(concat($src, 'KIN_DATA.xml'));
declare variable $KIN_MOURNING_STEPS := doc(concat($src, 'KIN_MOURNING_STEPS.xml'));
declare variable $KIN_Mourning := doc(concat($src, 'KIN_Mourning.xml'));



declare function local:kin($family as node()*) as node()* {
    
    (:This function takes persons via c_personid and returns a list kin group  relations.
It's structure is tied to local:asso and changes should be made to both functions in concert.:)
    
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
none of these is symmetrical hence there is no need for mutuality checks as in local:asso
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
    
    for $kin in $KIN_DATA//c_personid[. = $family]
    let $tie := $KINSHIP_CODES//c_kincode[. = $kin/../c_kin_code]
    
    (:let basic :=
 for $:)
    
    return
        element relation {
            attribute active {concat('#BIO', $kin/../c_personid/text())},
            attribute passive {concat('#BIO', $kin/../c_kin_id/text())},
            attribute key {$tie/../c_kincode/text()},
            if (empty($tie/../c_pick_sorting))
            then
                ()
            else
                (attribute sortKey {$tie/../c_pick_sorting/text()}),
            attribute name {
                if (contains($tie/../c_kinrel/text(), ' ('))
                then (substring-before($tie/../c_kinrel/text(), ' ('))
                else if (contains($tie/../c_kinrel/text(), 'male)'))
                    then (replace(replace($tie/../c_kinrel/text(), '\(male\)', '♂'), '\(female\)', '♀'))
                    else(translate($tie/../c_kinrel/text(), '#', '№'))},
            if ($kin/../c_source[. > 0])
            then
                (attribute source {concat('#BIB', $kin/../c_source/text())})
            else
                (),
            if (empty($kin/../c_autogen_notes))
            then
                ()
            else
                (attribute type {'auto-generated'}),
            element desc {
                if ($kin/../c_notes)
                then
                    (element label {$kin/../c_notes/text()})
                else
                    (),
                element desc {
                    attribute xml:lang {"en"},
                    $tie/../c_kinrel_alt/text()
                },
                element desc {
                    attribute xml:lang {"zh-Hant"},
                    $tie/../c_kinrel_chn/text()
                }
            }
        }
};

declare function local:asso($ego as node()*) as node()* {
    
    (: This function records association data in Tei. It expects a person as input, 
to generate a list relations. 

The structure of its output should match the output of local:kin

ASSOC_CODES contains both symmetrical and assymetrical relations, 
these are converted into tei:relation/@active || @passive  || @mutual
these are still dubious:
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
merge all events which have the same ASSOC_CODE right now 1 element per preface written, 
better 1 element for all X prefaces written? 
yet unused mediated relations , tei handles this quite easily
go over remaining assoc_data fields and see which ones can be included
:)
    
    (:count($ASSOC_DATA//c_assoc_id[. > 0][. < 500]) = 1726
whats up with $assoc_codes//c_assoc_role_type ?:)
    
    for $individual in $ASSOC_DATA//c_personid[. = $ego]
    let $friends := $individual/../c_assoc_id
    
    let $code := $ASSOC_CODES//c_assoc_code[. = $individual/../c_assoc_code]
    let $type-rel := $ASSOC_CODE_TYPE_REL//c_assoc_code[. = $individual/../c_assoc_code]
    let $type := $ASSOC_TYPES//c_assoc_type_id[. = $type-rel/../c_assoc_type_id]
    
    return        
        element relation {
            if ($code/text() = $code/../c_assoc_pair/text())
            then
                (attribute mutual {
                    concat('#BIO', $friends/text(), ' ', concat('#BIO', $individual/text()))
                })
            else
                (
                if (ends-with($code/../c_assoc_desc/text(), ' for')
                or ends-with($code/../c_assoc_desc/text(), ' to')
                or ends-with($code/../c_assoc_desc/text(), ' was)')
                or ends-with($code/../c_assoc_desc/text(), ' of')
                or ends-with($code/../c_assoc_desc/text(), 'ed')
                or ends-with($code/../c_assoc_desc/text(), ' with')
                or ends-with($code/../c_assoc_desc/text(), ' from')
                or $code/../c_assoc_desc/text() eq 'visited'
                or $code/../c_assoc_desc/text() eq 'Knew')
                then
                    (attribute active {concat('#BIO', $individual/text())},
                    attribute passive {
                        concat('#BIO', $friends/text())
                    })
                else
                    (attribute active {
                        concat('#BIO', $friends/text())
                    },
                    attribute passive {concat('#BIO', $individual/text())})),
            attribute key {$type-rel/../c_assoc_type_id/text()},
            attribute sortKey {$type/../c_assoc_type_sortorder/text()},
            attribute name {
                lower-case(
                translate($type/../c_assoc_type_short_desc/text(), ' ', '-'))
            },
            if ($individual/../c_source[. > 0])
            then
                (attribute source {concat('#BIB', $individual/../c_source/text())})
            else
                (),
            element desc {
                if ($code/../c_assoc_role_type/text())
                then
                    (attribute type {$code/../c_assoc_role_type/text()})
                else
                    (),
                if ($individual/../c_notes)
                then
                    (element label {$individual/../c_notes/text()})
                else
                    (),
                element desc {
                    attribute xml:lang {"en"},
                    $code/../c_assoc_desc/text(),
                    element label {$type/../c_assoc_type_desc/text()}
                },
                element desc {
                    attribute xml:lang {"zh-Hant"},
                    $code/../c_assoc_desc_chn/text(),
                    element label {$type/../c_assoc_type_desc_chn/text()}
                }
            }
        }

};


declare function local:biog($persons as node()*) as node()* {
    
    (: 
[tts_sysno] INTEGER,                            x
 [c_personid] INTEGER PRIMARY KEY,            x
 [c_name] CHAR(255),                            x
 [c_name_chn] CHAR(255),                        x
 [c_index_year] INTEGER,                        x
 [c_female] BOOLEAN NOT NULL,                   x
 [c_ethnicity_code] INTEGER,                    x
 [c_household_status_code] INTEGER,             x
 [c_tribe] CHAR(255),                           x
 [c_birthyear] INTEGER,                         x
 [c_by_nh_code] INTEGER,                        x
 [c_by_nh_year] INTEGER,                        x
 [c_by_range] INTEGER,                          d  
 [c_deathyear] INTEGER,                         x
 [c_dy_nh_code] INTEGER,                        x
 [c_dy_nh_year] INTEGER,                        x
 [c_dy_range] INTEGER,                          d
 [c_death_age] INTEGER,                         x
 [c_death_age_approx] INTEGER,                  x
 [c_fl_earliest_year] INTEGER,                  x
 [c_fl_ey_nh_code] INTEGER,                     x
 [c_fl_ey_nh_year] INTEGER,                     x
 [c_fl_ey_notes] CHAR,                          x
 [c_fl_latest_year] INTEGER,                    x
 [c_fl_ly_nh_code] INTEGER,                     x
 [c_fl_ly_nh_year] INTEGER,                     x
 [c_fl_ly_notes] CHAR,                          x
 [c_surname] CHAR(255),                         x
 [c_surname_chn] CHAR(255),                     x
 [c_mingzi] CHAR(255),                          x
 [c_mingzi_chn] CHAR(255),                      x
 [c_dy] INTEGER,                                 x
 [c_choronym_code] INTEGER,                     x
 [c_notes] CHAR,                                    x
 [c_by_intercalary] BOOLEAN NOT NULL,           x
 [c_dy_intercalary] BOOLEAN NOT NULL,           x
 [c_by_month] INTEGER,                            x
 [c_dy_month] INTEGER,                            x
 [c_by_day] INTEGER,                               x
 [c_dy_day] INTEGER,                                x
 [c_by_day_gz] INTEGER,                           x
 [c_dy_day_gz] INTEGER,                            x
 [TTSMQ_db_ID] CHAR(255),                           x
 [MQWWLink] CHAR(255),                              x
 [KyotoLink] CHAR(255),                         x
 [c_surname_proper] CHAR(255),                  x
 [c_mingzi_proper] CHAR(255),                   x
 [c_name_proper] CHAR(255),                     x
 [c_surname_rm] CHAR(255),                      x
 [c_mingzi_rm] CHAR(255),                       x
 [c_name_rm] CHAR(255),                         x
 [c_created_by] CHAR(255),                      x
 [c_created_date] CHAR(255),                    x
 [c_modified_by] CHAR(255),                     x
 [c_modified_date] CHAR(255),                   x
 [c_self_bio] BOOLEAN NOT NULL)                 x
 :)
    
    
    for $person in $persons
    
    let $association := $ASSOC_DATA//c_personid[. = $person]
    let $kin := $KIN_DATA//c_personid[. = $person]
    
    
    
    return
        <person
            ana="historical"
            xml:id="{concat('BIO', $person/text())}">
            <idno
                type="TTS">{$person/../tts_sysno/text()}</idno>
            
            {
                if (empty($kin) and empty($association))
                then
                    ()
                else
                    (<affiliation>
                        {
                            if (empty($kin))
                            then
                                ()
                            else
                                (<note>
                                    <listPerson
                                        type="kin">
                                        <listRelation
                                            type="kinship">{local:kin($person)}</listRelation>
                                    </listPerson>
                                </note>)
                        }
                        {
                            if (empty($association))
                            then
                                ()
                            else
                                (<note>
                                    <listPerson
                                        type="associates">
                                        <listRelation
                                            type="associations">{local:asso($person)}</listRelation>
                                    </listPerson>
                                </note>)
                        }
                    </affiliation>)
            }
        
        </person>
};

let $test := $BIOG_MAIN//c_personid[. > 0][. < 500]
let $full := $BIOG_MAIN//c_personid[. > 0]

return
    local:biog($test)

(:for $n in distinct-values($KINSHIP_CODES//c_kinrel/text())
where contains($n, 'male)')
return $n:)


