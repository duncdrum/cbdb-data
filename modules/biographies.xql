xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare namespace biog= "http://exist-db.org/apps/cbdb-data/biographies";

declare default element namespace "http://www.tei-c.org/ns/1.0";


(:This is the main Transformation of Biographical data from CBDB.
 biog:biog strores person data as tei:persList.
 
 The following variable declarations were auto-generated via gitify.xpl
:)



(:TODO:
- split the biogmain transformation into two files one for biog main and aliases on fore event n stuff?
- consider tei:occupation, tei:education, tei:faith to sort through the whole entry office posting mess
- create a taxonony for offices
- clean up variables prolog 

:)

(:NAMES:)
declare function biog:name ($names as node()*, $lang as xs:string?) as node()* {
(:This function checks the different name components and languages to retun persNames.
It expects valid c_name, or c_cname_chn nodes, and 'py' or'hz' as arguments.
:)


let $py :=
    for $name in $names/../no:c_name
    let $choro := $global:CHORONYM_CODES//no:c_choronym_code[. = $name/../no:c_choronym_code]
    
    return
        if ($name/text() eq concat($name/../no:c_surname/text(), ' ', $name/../no:c_mingzi/text()))
        then (<persName xml:lang="zh-Latn-alalc97">
                    <surname>{$name/../no:c_surname/text()}</surname>
                    <forename>{$name/../no:c_mingzi/text()}</forename>
                    {if (empty($choro) or $choro[. < 1])
                    then ()
                    else (<addName type="choronym">{$choro/../no:c_choronym_desc/text()}</addName>)
                    }
                </persName>)
        else (<persName xml:lang="zh-Latn-alalc97">
                {$name/text()}
                {if (empty($choro) or $choro[. < 1])
                    then ()
                    else (<addName type="choronym">{$choro/../no:c_choronym_desc/text()}</addName>)
                    }
                </persName>)

let $hz := 
    for $name in $names/../no:c_name_chn
    let $choro := $global:CHORONYM_CODES//no:c_choronym_code[. = $name/../no:c_choronym_code]
    
    return
        if ($name/text() eq concat($name/../no:c_surname_chn/text(), $name/../no:c_mingzi_chn/text()))
        then (<persName xml:lang="zh-Hant">
                    <surname>{$name/../no:c_surname_chn/text()}</surname>
                    <forename>{$name/../no:c_mingzi_chn/text()}</forename>
                    {if (empty($choro) or $choro[. < 1])
                    then ()
                    else (<addName type="choronym">{$choro/../no:c_choronym_chn/text()}</addName>)
                    }
                </persName>
                )
        else (<persName xml:lang="zh-Hant">
                {$name/text()}
                {if (empty($choro) or $choro[. < 1])
                    then ()
                    else (<addName type="choronym">{$choro/../no:c_choronym_chn/text()}</addName>)
                    }
                </persName>
                )

let $proper :=
    for $name in $names/../no:c_name_proper
    return
        if ($name/text() eq concat($name/../no:c_surname_proper/text(), ' ', $name/../no:c_mingzi_proper/text()))
        then (<persName type="original">
                    <surname>{xmldb:decode($name/../no:c_surname_proper/string())}</surname>
                    <forename>{xmldb:decode($name/../no:c_mingzi_proper/string())}</forename>
               </persName>)
        else(<persName type="original">{xmldb:decode($name/string())}</persName>)
        
let $rm :=
    for $name in $names/../no:c_name_rm
    return
        if ($name/text() eq concat($name/../no:c_surname_rm/text(), ' ', $name/../no:c_mingzi_rm/text()))
        then (<persName type="original">
                    <surname>{xmldb:decode($name/../no:c_surname_rm/string())}</surname>
                    <forename>{xmldb:decode($name/../no:c_mingzi_rm/string())}</forename>
               </persName>)
        else(<persName type="original">{xmldb:decode($name/string())}</persName>)
        
                

return
    switch($lang)
        case 'py' return $py 
        case 'hz' return $hz
        case 'proper' return $proper
        case 'rm' return $rm
        default return ()
}; 

declare function biog:alias ($person as node()*) as node()* {
(:This function resolves aliases in zh and py.
It checks ALTNAME_DATA for the c_personid and returns persName elements.
:)

(: d= drop                                  
[tts_sysno] INTEGER,                    d
 [c_personid] INTEGER,                  x
 [c_alt_name] CHAR(255),               x
 [c_alt_name_chn] CHAR(255),           x
 [c_alt_name_type_code] INTEGER,      x
 [c_source] INTEGER,                    x
 [c_pages] CHAR(255),                   d
 [c_notes] CHAR,                         x
 [c_created_by] CHAR(255),             x
 [c_created_date] CHAR(255),           x
 [c_modified_by] CHAR(255),            x
 [c_modified_date] CHAR(255),          x
:)

for $person in $global:ALTNAME_DATA//no:c_personid[. =$person]
let $code := $global:ALTNAME_CODES//no:c_name_type_code[. = $person/../no:c_alt_name_type_code]

return 
    if (empty($person)) then ()
    else if (empty($person/../no:c_source)) 
        then (<persName type = "alias" 
                  key="{concat('AKA', $code/text())}">
                    <addName>{$person/../no:c_alt_name_chn/text()}</addName>
                    {if ($code[. > 1]) 
                     then (<term>{$code/../no:c_name_type_desc_chn/text()}</term>)
                     else()
                     }                
                    <addName xml:lang="zh-Latn-alalc97">{$person/../no:c_alt_name/text()}</addName>
                    {if ($code[. > 1]) 
                     then (<term>{$code/../no:c_name_type_desc/text()}</term>)
                     else()
                    }                
                {if (empty($person/../no:c_notes)) 
                then ()
                else (<note>{$person/../no:c_notes/text()}</note>)                
                }                
            </persName>)
    else (<persName type = "alias" 
            key="{concat('AKA', $code/text())}"
            source="{concat('#BIB', $person/../no:c_source/text())}">
                <addName xml:lang="zh-Hant">{$person/../no:c_alt_name_chn/text()}</addName>
                {if ($code[. > 1]) 
                 then (<term>{$code/../no:c_name_type_desc_chn/text()}</term>)
                 else()
                 }                
                <addName xml:lang="zh-Latn-alalc97">{$person/../no:c_alt_name/text()}</addName>
                {if ($code[. > 1]) 
                 then (<term>{$code/../no:c_name_type_desc/text()}</term>)
                 else()
                }                
                {if (empty($person/../no:c_notes)) 
                then ()
                else (<note>{$person/../no:c_notes/text()}</note>)                
                }      
            </persName>)            
};

(:RELATIONS:)
declare function biog:kin ($self as node()*) as node()* {
    
    (:This function takes persons via c_personid and returns a list kin group  relations.
It's structure is tied to biog:asso and changes should be made to both functions in concert.:)
    
    (: KIN_DATA                                            KINSHIP_CODES 
[tts_sysno] INTEGER,                    x                [c_kincode] INTEGER PRIMARY KEY,   x
 [c_personid] INTEGER,                  x                [c_kin_pair1] INTEGER,              d
 [c_kin_id] INTEGER,                    x                [c_kin_pair2] INTEGER,              d
 [c_kin_code] INTEGER,                  x                [c_kin_pair_notes] CHAR(50),       d
 [c_source] INTEGER,                    x                [c_kinrel_chn] CHAR(255),           x
 [c_pages] CHAR(255),                   d                [c_kinrel] CHAR(255),               x
 [c_notes] CHAR,                         x                [c_kinrel_alt] CHAR(255),          x
 [c_autogen_notes] CHAR,                x               [c_pick_sorting] INTEGER,           x
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
    
    
    for $kin in $global:KIN_DATA//no:c_personid[. = $self]
    let $tie := $global:KINSHIP_CODES//no:c_kincode[. = $kin/../no:c_kin_code]
    let $mourning := $global:KIN_Mourning//no:c_kinrel[. = $tie/../no:c_kinrel]
    

    
    return
        element relation {
            attribute active {concat('#BIO', $kin/../no:c_personid/text())},
            attribute passive {concat('#BIO', $kin/../no:c_kin_id/text())},
            
            if (empty($tie/../no:c_kincode) and empty($tie/../no:c_kinrel))
            then (attribute name {'unkown'})
            else (
                if (empty($tie/../no:c_kincode))
                then ()
                else (attribute key {$tie/../no:c_kincode/text()}),
                
                if (empty($tie/../no:c_pick_sorting))
                then ()
                else (attribute sortKey {$tie/../no:c_pick_sorting/text()}),
                
                if (empty($tie/../no:c_kinrel))
                then ()
                else (attribute name {
                        if (contains($tie/../no:c_kinrel/text(), ' ('))
                        then (substring-before($tie/../no:c_kinrel/text(), ' ('))
                        else if (contains($tie/../no:c_kinrel/text(), 'male)'))
                            then (replace(replace($tie/../no:c_kinrel/text(), '\(male\)', '♂'), '\(female\)', '♀'))
                            else(translate($tie/../no:c_kinrel/text(), '#', '№'))}),
                            
                if ($kin/../no:c_source[. > 0])
                then (attribute source {concat('#BIB', $kin/../no:c_source/text())})
                else (),
                
                if (empty($kin/../no:c_autogen_notes))
                then ()
                else (attribute type {'auto-generated'}),
                
                if (empty($tie/../no:c_kinrel_chn) and empty ($tie/../no:c_kinrel_alt))
                then ()
                else (element desc { attribute type {'kin-tie'}, 
                
                        if ($kin/../no:c_notes)
                        then (element label {$kin/../no:c_notes/text()})
                        else (),
                        
                        element desc { attribute xml:lang {"zh-Hant"},
                            $tie/../no:c_kinrel_chn/text()},    
                        element desc {attribute xml:lang {"en"},
                            $tie/../no:c_kinrel_alt/text()},                     
                        
                        if (empty($mourning))
                        then ()
                        else (element trait{ attribute type {'mourning'},
                               attribute subtype {$mourning/../no:c_kintype/text()},
                               element label { attribute xml:lang {"zh-Hant"},
                               $mourning/../no:c_mourning_chn/text()}, 
                               element desc { attribute xml:lang {"zh-Hant"},
                                    $mourning/../no:c_kintype_desc_chn/text()},
                               element desc {attribute xml:lang {"en"},
                                    $mourning/../no:c_kintype_desc/text()}
                               })     
                    })
                )
        }
};

declare function biog:asso ($ego as node()*) as node()* {
    
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


:)

(: REPORT
let $symmetry :=
    for $symmetric in $ASSOC_CODES//no:row
    where $symmetric/no:c_assoc_code = $symmetric/no:c_assoc_pair
    return
        $symmetric
    
let $assymetry := 
    for $assymetric in $ASSOC_CODES//no:row
    where $assymetric/no:c_assoc_code != $assymetric/no:c_assoc_pair
    return
        $assymetric
        
let $bys :=
(\: filters all */by pairs :\)
    for $by in $ASSOC_CODES//no:c_assoc_desc
    where contains($by/text(), ' by')
    return 
        $by
    
let $was :=
(\: filter all  was/of pairs:\)
    for $was in $ASSOC_CODES//no:c_assoc_desc
    where contains($was/text(), ' was')
    return
        $was
let $to :=
(\: filter all from/to pairs :\)
    for $to in $ASSOC_CODES//no:c_assoc_desc
    where contains($to/text(), ' to')
    return
        $to
    
let $report := 
    <report>
        <total>{count(//no:row)}</total>
        <unaccounted>{count(//no:row) - (count($assymetry) + count($symmetry))}</unaccounted>
        <symmetric>
            <sym_sum>{count($symmetry)}</sym_sum>
            <rest>{count(//no:row) - count($symmetry)}</rest>
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
 [tts_sysno] INTEGER,                             d
 [c_assoc_code] INTEGER,                          x
 [c_personid] INTEGER,                            x
 [c_kin_code] INTEGER,                            d
 [c_kin_id] INTEGER,                              x
 [c_assoc_id] INTEGER,                            x
 [c_assoc_kin_code] INTEGER,                     d 
 [c_assoc_kin_id] INTEGER,                       x  
 [c_tertiary_personid] INTEGER,                 x 
 [c_assoc_count] INTEGER,                        d  
 [c_sequence] INTEGER,                            x 
 [c_assoc_year] INTEGER,                          x 
 [c_source] INTEGER,                              x
 [c_pages] CHAR(255),                             d
 [c_notes] CHAR,                                   x
 [c_assoc_nh_code] INTEGER,                         
 [c_assoc_nh_year] INTEGER,                        
 [c_assoc_range] INTEGER,                        !!!
 [c_addr_id] INTEGER,                             x
 [c_litgenre_code] INTEGER,                      x
 [c_occasion_code] INTEGER,                      x
 [c_topic_code] INTEGER,                          x                    
 [c_inst_code] INTEGER,                           x
 [c_inst_name_code] INTEGER,                     d 
 [c_text_title] CHAR(255),                          
 [c_assoc_claimer_id] INTEGER,                      
 [c_assoc_intercalary] BOOLEAN NOT NULL,         
 [c_assoc_month] INTEGER,                           
 [c_assoc_day] INTEGER,                             
 [c_assoc_day_gz] INTEGER,                          
 [c_created_by] CHAR(255),                       d
 [c_created_date] CHAR(255),                     d
 [c_modified_by] CHAR(255),                      d
 [c_modified_date] CHAR(255))                    d
:)

(:TO DO 
- consider chal-ZH dates for state
- c assoc claimer could get a @role somewhere around state
- litgenre codes are empty?
:)

    (:count($ASSOC_DATA//no:c_assoc_id[. > 0][. < 500]) = 1726
whats up with $assoc_codes//no:c_assoc_role_type ?:)
    
    for $individual in $global:ASSOC_DATA//no:c_personid[. = $ego]
    let $friends := $individual/../no:c_assoc_id
    
    let $code := $global:ASSOC_CODES//no:c_assoc_code[. = $individual/../no:c_assoc_code]
    let $type-rel := $global:ASSOC_CODE_TYPE_REL//no:c_assoc_code[. = $individual/../no:c_assoc_code]
    let $type := $global:ASSOC_TYPES//no:c_assoc_type_id[. = $type-rel/../no:c_assoc_type_id]
    
    let $scholarly := $global:SCHOLARLYTOPIC_CODES//no:c_topic_code[. = $individual/../no:c_topic_code]
    let $occcasion := $global:OCCASION_CODES//no:c_occasion_code[. = $individual/../no:c_occasion_code]
    let $genre := $global:LITERARYGENRE_CODES//no:c_lit_genre_code[. = $individual/../no:c_litgenre_code/text()]
    
    return        
        element relation {
            if ($code/text() = $code/../no:c_assoc_pair/text())
            then (attribute mutual {concat('#BIO', $friends/text(), ' ', 
                                       concat('#BIO', $individual/text()))})
            else (
                if (ends-with($code/../no:c_assoc_desc/text(), ' for')
                or ends-with($code/../no:c_assoc_desc/text(), ' to')
                or ends-with($code/../no:c_assoc_desc/text(), ' was)')
                or ends-with($code/../no:c_assoc_desc/text(), ' of')
                or ends-with($code/../no:c_assoc_desc/text(), 'ed')
                or ends-with($code/../no:c_assoc_desc/text(), ' with')
                or ends-with($code/../no:c_assoc_desc/text(), ' from')                
                or $code/../no:c_assoc_desc/text() eq 'Knew')
                then (attribute active {concat('#BIO', $individual/text())},
                       attribute passive {concat('#BIO', $friends/text())})
                else (attribute active {concat('#BIO', $friends/text())},
                       attribute passive {concat('#BIO', $individual/text())})
                ),
            
            if (empty($type-rel/../no:c_assoc_type_id) and empty($type/../no:c_assoc_type_short_desc))
            then (attribute name {'unkown'})
            else (            
                if (empty($type-rel/../no:c_assoc_type_id))
                then ()
                else (attribute key {$type-rel/../no:c_assoc_type_id/text()}),
                
                if ($individual/../no:c_sequence > 0)
                then (attribute sortKey {$individual/../no:c_sequence/text()})
                else (),
                
                if (empty($type/../no:c_assoc_type_short_desc))
                then ()
                else (attribute name {lower-case(translate($type/../no:c_assoc_type_short_desc/text(), ' ', '-'))}),         
               
                if ($individual/../no:c_source[. > 0])
                then (attribute source {concat('#BIB', $individual/../no:c_source/text())})
                else (),
        (:     DESC           :)
                if (empty($code/../no:c_assoc_role_type))
                then ()
                else (element desc {
                     if ($code/../no:c_assoc_role_type/text())
                     then (attribute type {$code/../no:c_assoc_role_type/text()})
                     else (),
                     
                     if (empty($type/../no:c_assoc_type_sortorder))
                     then ()
                     else (attribute n {$type/../no:c_assoc_type_sortorder/text()}),
                     
                     if ($individual/../no:c_notes)
                     then (element label {$individual/../no:c_notes/text()})
                     else (),
                                                   
                     element desc { attribute xml:lang {"zh-Hant"},
                         $code/../no:c_assoc_desc_chn/text(),
                         element label {$type/../no:c_assoc_type_desc_chn/text()}
                     },
                     
                      element desc { attribute xml:lang {"en"},
                         $code/../no:c_assoc_desc/text(),
                         element label {$type/../no:c_assoc_type_desc/text()}
                     },
                    
            (:      STATE         :)
                     if ($individual/../no:c_addr_id[. > 0] or $individual/../no:c_inst_code[. > 0]
                        or exists($individual/../no:c_assoc_year) or $individual/../no:c_occasion_code[. > 0]
                        or $individual/../no:c_topic_code[. > 0] or $individual/../no:c_litgenre_code[. > 0]
                        or $individual/../no:c_tertiary_personid[. > 0] or $individual/../no:c_kin_id[. > 0]
                        or $individual/../no:c_assoc_kin_id[. > 0])
                     then (   
                     element state {              
                     
                     for $add in $individual/../no:c_addr_id[. > 0] 
                     for $org in  $individual/../no:c_inst_code[. > 0]                               
                     return
                        attribute ref {concat('#PL', $add/text()), concat('#ORG', $org/text())},
                     
                     if (empty($individual/../no:c_assoc_year))
                     then ()
                     else (attribute when {cal:isodate($individual/../no:c_assoc_year)}),
                     
                     if ($individual/../no:c_occasion_code > 0)
                     then (attribute ana {$individual/../no:c_occasion_code/text()})
                     else (),
                     
                     if ($individual/../no:c_topic_code > 0)
                     then (attribute type {$individual/../no:c_topic_code/text()})
                     else (),
                     
                     if ($individual/../no:c_litgenre_code > 0)
                     then (attribute subtype {$individual/../no:c_litgenre_code/text()})
                     else (),
                     
                     if (empty($occcasion) or $occcasion[. = 0])
                     then ()
                     else (element label { attribute xml:lang {'zh-Hant'},
                                $occcasion/../no:c_occasion_desc_chn/text()},
                            element label { attribute xml:lang {'zh-Latn-alalc97'},
                                $occcasion/../no:c_occasion_desc/text()}),
                    (:   desc and desc_chn are reversed in source for type [sic.]   :)
                     if (empty($scholarly) or $scholarly[. = 0])
                     then ()
                     else (element desc {attribute ana {'topic'},
                                attribute type {$scholarly/../no:c_topic_type_code/text()},
                                element desc {attribute xml:lang {'zh-Hant'},
                                    $scholarly/../no:c_topic_desc_chn/text(),
                                    element label {$scholarly/../no:c_topic_type_desc/text()}},
                                element desc { attribute xml:lang {'en'},
                                    $scholarly/../no:c_topic_desc/text(),
                                    element label {$scholarly/../no:c_topic_type_desc_chn/text()}
                                    }
                            }),
                            
                     if (empty($genre) or $genre[. = 0])
                     then ()
                     else (element desc {attribute ana {'genre'},                                
                                element label {attribute xml:lang {'zh-Hant'},
                                $genre/../no:c_lit_genre_desc_chn/text()}, 
                                element label { attribute xml:lang {'en'}, 
                                $genre/../no:c_lit_genre_desc/text()}
                            }),
                     
                     let $third := $individual/../no:c_tertiary_personid[. > 0]
                     let $own-kin := $individual/../no:c_kin_id[. > 0]
                     let $assoc-kin := $individual/../no:c_assoc_kin_id[. > 0]
                     
                     return 
                        if (empty($third) and empty($own-kin) and empty($assoc-kin))
                        then ()
                        else (element desc{
                                for $n in ($third, $own-kin, $assoc-kin)
                                return
                                    element persName { attribute role {'mediator'},
                                        attribute ref {concat('#BIO', $n/text())}
                                    }
                        })
                     })
                     else()
                 })
             )
        }
};

(:STATUS / STATE:)
declare function biog:status ($achievers as node()*) as node()* {


(:the following lines can be added ones status types are linked to status codes to add a label child element to the language specific desc elements
 : 
 : let $statt := doc("/db/apps/cbdb/source/CBDB/code/STATUS_TYPES.xml")
 : let $statctr := doc("/db/apps/cbdb/source/CBDB/relations/STATUS_CODE_TYPE_REL.xml")
 : 
 : if ($statt//no:c_status_type_code[. = $statctr//no:c_status_type_code[. = $code]]) 
 : then (<label>$statt//no:c_status_type_code[. = $statctr//no:c_status_type_code[. = $code]]/../no:c_status_type_desc/text()</label>) else()    
 : if ($statt//no:c_status_type_code[. = $statctr//no:c_status_type_code[. = $code]]) 
 : then (<label>$statt//no:c_status_type_code[. = $statctr//no:c_status_type_code[. = $code]]/../no:c_status_type_desc_chn/text()</label>) else()
 :)

for $status in $global:STATUS_DATA//no:c_personid[. = $achievers]

let $code := $global:STATUS_CODES//no:c_status_code[. = $status/../no:c_status_code]
let $first := $status/../no:c_firstyear
let $last := $status/../no:c_lastyear
return 
    if ($status/../no:c_status_code[. < 1]) 
    then ()
    else ( element state { attribute type {'status'},
          if ($first/text() and $last/text() != 0)
          then ( attribute from {cal:isodate($first/text())}, 
                attribute to {cal:isodate($last/text())})
          else if ($first/text() != 0)
               then (attribute from {cal:isodate($first/text())})
               else if ($last/text() != 0)
                    then ( attribute to {cal:isodate($last/text())})
                    else (' '),
          element desc { attribute xml:lang {'zh-Hant'}, $code/../no:c_status_desc_chn/text()},          
          element desc { attribute xml:lang {'en'}, $code/../no:c_status_desc/text()}          
          }
          )
};

(:EVENTS:)
declare function biog:event ($participants as node()*) as node()* {
(: no py or en name for events:)

for $event in $global:EVENTS_DATA//no:c_personid[. = $participants]
let $code := $global:EVENT_CODES//no:c_event_code[. = $event/../no:c_event_code]
let $event-add := $global:EVENTS_ADDR//no:c_event_record_id[. = $event/../no:c_event_record_id]
        return
             
                element event { 
                    if ($event/../no:c_year != 0)
                    then (attribute when {cal:isodate($event/../no:c_year/text())})
                    else (),
                    if (empty($event-add))
                    then ()
                    else (attribute where {concat('#PL', $event-add/../no:c_addr_id/text())}),
                    if ($code[. > 0])
                    then (element head {$code/../no:c_event_name_chn/text()})
                    else (), 
                    if (empty($event/../no:c_event)) 
                    then ()
                    else (element label {$event/../no:c_event/text()}), 
                    if (empty($event/../no:c_role))
                    then()
                    else (element desc {$event/../no:c_role/text()}),
                    if (empty($event/../no:c_notes))
                    then()
                    else(element note {$event/../no:c_notes/text()})    
                } 
             
};

(:exam and office related data:)
declare function biog:entry ($initiates as node()*) as node()* {
(: biog:entry expects persons from BIOG_MAIN and returns tei:event for entries into social institutions.
the output of biog:entry should match the structure of biog:event's ouput.

Note about 100 entries are tagede both by 7 specials and other (id =90) hence the filter for 
count($types) > 1 below. 
:)

(: TODO
- what does c_exam_field point to A: nothing its a string zh-Hant only
- see c_personid 914 for dual @type entries
- c_inst_code only points to '0' no links to org to be written

institutional addressess via biog:inst-add
switch to tei:education | tei:faith for entry type data
:)

for $initiate in $global:ENTRY_DATA//no:c_personid[. =$initiates]

let $code := $global:ENTRY_CODES//no:c_entry_code[. = $initiate/../no:c_entry_code]
let $type-rel := $global:ENTRY_CODE_TYPE_REL//no:c_entry_code[ . = $initiate/../no:c_entry_code]
let $type :=  $global:ENTRY_TYPES//no:c_entry_type[. = $type-rel/../no:c_entry_type]
let $parent-stat := $global:PARENTAL_STATUS_CODES//no:c_parental_status_code[. = $initiate/../no:c_parental_status/text()]

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
 [c_inst_code] INTEGER NOT NULL,             x
 [c_inst_name_code] INTEGER NOT NULL,        d
 [c_exam_field] CHAR(255),                     x
 [c_addr_id] INTEGER,                           x
 [c_parental_status] INTEGER,                 x
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
              then (attribute type {'00'})
              else (attribute type {$type/text()}),
        
        if (empty($code/text()))
        then ()
        else(attribute subtype {$code/text()}), 
        
        if ($initiate/../no:c_inst_code > 0)
        then (attribute ref {concat('#ORG', $initiate/../no:c_inst_code)})
        else(),
        
        if ($initiate/../no:c_year[. = 0] or empty($initiate/../no:c_year)) 
        then ()
        else (attribute when {cal:isodate($initiate/../no:c_year/text())}),
        
        if ($initiate/../no:c_addr_id[. = 0] or empty($initiate/../no:c_addr_id))
        then ()
        else (attribute where {concat('#PL', $initiate/../no:c_addr_id/text())}),
        
        attribute sortKey {$initiate/../no:c_sequence/text()},
        
        for $sponsor in $initiate
        return 
            if ($sponsor/../no:c_kin_id[. > 0] or $sponsor/../no:c_assoc_id[. > 0])
            then (attribute role {concat('#BIO', $sponsor/text())})
            else (),    
            
        if ($initiate/../no:c_source[. = 0] or empty($initiate/../no:c_source))
        then ()
        else (attribute source{concat('#BIB', $initiate/../no:c_source/text())}),
            element head {'entry'}, 
            if ($code[. < 1])
            then ()
            else(
                element label {attribute xml:lang {'zh-Hant'},
                    $code/../no:c_entry_desc_chn/text()},
                element label {attribute xml:lang{'en'},
                    $code/../no:c_entry_desc/text()}),   
                    
            if ($type[. < 1] or empty($type) )
            then ()
            else if (count($type) > 1) 
                  then (element desc { attribute type {$type[. < 90]/../no:c_entry_type_level/text()},
                            attribute subtype {$type[. < 90]/../no:c_entry_type_sortorder/text()},
                        element desc {attribute xml:lang {'zh-Hant'},
                            $type[. < 90]/../no:c_entry_type_desc_chn/text()},
                        element desc {attribute xml:lang{'en'},
                            $type[. < 90]/../no:c_entry_type_desc/text()}})
                  else (element desc { attribute type {$type/../no:c_entry_type_level/text()},
                            attribute subtype {$type/../no:c_entry_type_sortorder/text()},
                        element desc {attribute xml:lang {'zh-Hant'},
                            $type/../no:c_entry_type_desc_chn/text()},
                        element desc {attribute xml:lang{'en'},
                            $type/../no:c_entry_type_desc/text()}}), 
                    
            if ($initiate/../no:c_exam_field)
            then (element note{ attribute type {'field'},
                $initiate/../no:c_exam_field/text()})
            else (),
            
            if ($initiate/../no:c_attempt_count[. > 0]) 
            then (element note{ attribute type{'attempts'},
                $initiate/../no:c_attempt_count/text()})
            else (),
            
            if ($initiate/../no:c_exam_rank[. != '0']) 
            then (element note{ attribute type{'rank'},
                $initiate/../no:c_exam_rank/text()})
            else (),  
            
            if ($initiate/../no:c_parental_status > 0)
            then (element note { attribute type {'parental-status'}, 
                    element trait { attribute type {'parental-status'},
                        attribute key {$parent-stat/text()},
                    element label {attribute xml:lang {'zh-Hant'},
                        $parent-stat/../no:c_parental_status_desc_chn/text()}, 
                    element label { attribute xml:lang {'zh-Latn-alalc97'},
                        $parent-stat/../no:c_parental_status_desc/text()}
                    }
                  })
            else (),        
            
            if ($initiate/../no:c_notes)
            then (element note {$initiate/../no:c_notes/text()})
            else ()
    }                              
};

declare function biog:new-post ($appointees as node()*) as node()* {

(: we need to ascertian a few things about dates and POST_DATA here:
are there any instances where one conatins data that is not isodate or in POSTED_TO_OFFICE_DATA? :)

(: TODO:
- Turn postings into tei:event
- check zh and western dates to make sure no dates are missing !!
:)

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
 [c_assume_office_code] INTEGER,              x
 [c_inst_code] INTEGER,                         !
 [c_inst_name_code] INTEGER,                    !
 [c_source] INTEGER,                             x
 [c_pages] CHAR(255),                            d
 [c_notes] CHAR,                                  x
 [c_office_id_backup] INTEGER,                  d
 [c_office_category_id] INTEGER,               x
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


for $post in $global:POSTED_TO_OFFICE_DATA//no:c_personid[. = $appointees]/../no:c_posting_id
let $addr := $global:POSTED_TO_ADDR_DATA//no:c_posting_id[. = $post]
let $cat := $global:OFFICE_CATEGORIES//no:c_office_category_id[. = $post/../no:c_office_category_id]
let $appt := $global:APPOINTMENT_TYPE_CODES//no:c_appt_type_code[. = $post/../no:c_appt_type_code]
let $assu := $global:ASSUME_OFFICE_CODES//no:c_assume_office_code[. =$post/../no:c_assume_office_code]

order by $post/../no:c_sequence
return
    element socecStatus{ attribute scheme {'#office'}, 
        attribute code {concat('#OFF', $post/../no:c_office_id)},
        element state {
            attribute type {'posting'},
            attribute n {$post/text()},
            if (empty($post/../no:c_sequence) or $post/../no:c_sequence = 0)
            then ()
            else (attribute key {$post/../no:c_sequence/text()}),        
            if (empty($post/../no:c_firstyear) or $post/../no:c_firstyear = 0) 
            then ()
            else (attribute notBefore {cal:isodate($post/../no:c_firstyear/text())}),
            if (empty($post/../no:c_lastyear) or $post/../no:c_lastyear = 0) 
            then ()
            else (attribute notAfter {cal:isodate($post/../no:c_lastyear/text())}),
            if (empty($post/../no:c_source) or $post/../no:c_source = 0)
            then ()
            else (attribute source {concat('#BIB', $post/../no:c_source/text())}),        
                           
           if (empty($post/../no:c_appt_type_code))
           then ()
           else (element desc { element label {'appointment'},
            element desc {attribute xml:lang {'zh-Hant'},
                $appt/../no:c_appt_type_desc_chn/text()}, 
            if (empty($appt/../no:c_appt_type_desc))
            then ()
            else (element desc {attribute xml:lang {'en'}, 
                $appt/../no:c_appt_type_desc/text()})
          }),
          
          if (empty($post/../no:c_assume_office_code))
          then ()
          else (element desc {element label {'assumes'},
            element desc {attribute xml:lang {'zh-Hant'},
                $assu/../no:c_assume_office_desc_chn/text()}, 
            element desc {attribute xml:lang {'en'}, 
                $assu/../no:c_assume_office_desc/text()}
          }),
          
          if (empty($post/../no:c_notes))
          then ()
          else (element note {$post/../no:c_notes/text()})
        },
        
        if ($cat[. < 1] or empty($cat))
        then ()
        else (element state { attribute type {'office-type'},
            if (empty($cat))
            then ()
            else (attribute n {$cat/text()}),
            
            if (empty($cat/../no:c_category_desc_chn))
            then ()
            else ( element desc {attribute xml:lang {'zh-Hant'},
                $cat/../no:c_category_desc_chn/text()}),
            if (empty($cat/../no:c_category_desc))
            then ()
            else ( element desc {attribute xml:lang {'en'},
                $cat/../no:c_category_desc/text()}),
                
        if (empty($cat/../no:c_notes)) 
        then ()
        else(<note>{$cat/../no:c_notes/text()}</note>)        
        })
    }
};

declare function biog:posses ($possessions as node()*) as node()* {
(: This function reads possession data and creates a tei:state[@type = 'possession'] element

So far there are only five entries (18332, 13550, 45279, 45518, 3874) in CBDB, with whole columns as NULL.

:)

(:[c_personid] INTEGER,                                 x
 [c_possession_record_id] INTEGER PRIMARY KEY,       x
 [c_sequence] INTEGER,                                  x                                      
 [c_possession_act_code] INTEGER,                       x
 [c_possession_desc] CHAR(50),                          x
 [c_possession_desc_chn] CHAR(50),                      x
 [c_quantity] CHAR(50),                                  x
 [c_measure_code] INTEGER,                               x   
 [c_possession_yr] INTEGER,                             x
 [c_possession_nh_code] INTEGER,                        !
 [c_possession_nh_yr] INTEGER,                          !
 [c_possession_yr_range] INTEGER,                       !
 [c_addr_id] INTEGER,                                     x
 [c_source] INTEGER,                                      x      
 [c_pages] CHAR(50),                                      d
 [c_notes] CHAR,                                           x
 [c_created_by] CHAR(255),                               d
 [c_created_date] CHAR(255),                            d
 [c_modified_by] CHAR(255),                             d
 [c_modified_date] CHAR(255))                           d
 
 :)

for $stuff in $global:POSSESSION_DATA//no:c_personid[. = $possessions][. > 0]
let $act := $global:POSSESSION_ACT_CODES//no:c_possession_act_code[ . = $stuff/../no:c_possession_act_code]
let $where := $global:POSSESSION_ADDR//no:c_possession_row_id[. = $stuff/../no:c_possession_row_id]
let $unit := $global:MEASURE_CODES//no:c_measure_code[. = $stuff/../no:c_measure_code]

return 
    element state{ 
        attribute xml:id {concat('POS', $stuff/../no:c_possession_row_id/text())},
        attribute type {'possession'}, 
        switch ($act)
            case '0' return ()
            default return attribute subtype {$act/../no:c_possession_act_desc/text()},
            
(:     in the future the return for $units needs to be tokenized    :)
        if (empty($stuff/../no:c_measure_code))
        then ()
        else ( attribute unit {$unit/../no:c_measure_desc/text()}),
        
        if (empty($stuff/../no:c_quantity))
        then ()
        else (attribute quantity {$stuff/../no:c_quantity/text()}), 
        
        if (empty($stuff/../no:c_sequence))
        then ()
        else (attribute n {$stuff/../no:c_sequence/text()}),
        
        if (empty($stuff/../no:c_possession_yr))
        then ()
        else (attribute when {cal:isodate($stuff/../no:c_possession_yr)}),
        
        if (empty($stuff/../no:c_source))
        then ()
        else (attribute source {concat('#BIB',$stuff/../no:c_source/text())}),
        
(:      Back to normal  :)
        element desc {
            if (empty($stuff/../no:c_possession_desc_chn))
            then ()
            else (element desc {attribute xml:lang {'zh-Hant'},
                            $stuff/../no:c_possession_desc_chn/text()}),
                            
            if (empty($stuff/../no:c_possession_desc))
            then ()
            else (element desc {attribute xml:lang {'en'},
                            $stuff/../no:c_possession_desc/text()}),
            
            if (empty($stuff/../no:c_addr_id))
            then ()
            else (element placeName { 
                attribute ref { concat('#PL', $stuff/../no:c_addr_id/text())}})
                },
        if (empty($stuff/../no:c_notes)) 
        then ()
        else (element note {$stuff/../no:c_notes/text()})
        
    }
};

(:PLACES:)
declare function biog:pers-add ($resident as node()*) as node()* {
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


for $address in $global:BIOG_ADDR_DATA//no:c_personid[. = $resident][. > 0]
let $code := $global:BIOG_ADDR_CODES//no:c_addr_type[. = $address/../no:c_addr_type]
order by $address/../no:c_sequence

return 
    if ($address/../no:c_addr_id[. < 1] or empty($address/../no:c_addr_id) )
    then ()
    else (

    element residence { 
       attribute ref {concat('#PL', $address/../no:c_addr_id/text())},
       
       if ($code > 0)
       then (attribute key {$code/text()})
       else (),
       
       if (empty($address/../no:c_sequence) or $address/../no:c_sequence = 0)
       then ()
       else (attribute n {$address/../no:c_sequence/text()}), 
       
   (:   Dates ISO :)
       if (empty($address/../no:c_firstyear) or $address/../no:c_firstyear = 0)
       then ()
       else if ($address/../no:c_firstyear != 0 and $address/../no:c_fy_month != 0 and $address/../no:c_fy_day != 0)
            then (attribute from {
             string-join((cal:isodate($address/../no:c_firstyear),
             functx:pad-integer-to-length($address/../no:c_fy_month, 2),
             functx:pad-integer-to-length($address/../no:c_fy_day, 2)), '-')})
            else if  ($address/../no:c_firstyear != 0 and $address/../no:c_fy_month != 0)
                then (attribute from {string-join((cal:isodate($address/../no:c_firstyear),
                        functx:pad-integer-to-length($address/../no:c_fy_month, 2)), '-')})
                else (attribute from {cal:isodate($address/../no:c_firstyear)}),
        
       if (empty($address/../no:c_lastyear) or $address/../no:c_lastyear = 0)
       then ()
       else if ($address/../no:c_lastyear != 0 and $address/../no:c_ly_month != 0 and $address/../no:c_ly_day != 0)
            then (attribute to {
             string-join((cal:isodate($address/../no:c_lastyear),
             functx:pad-integer-to-length($address/../no:c_ly_month, 2),
             functx:pad-integer-to-length($address/../no:c_ly_day, 2)), '-')})
            else if  ($address/../no:c_lastyear != 0 and $address/../no:c_ly_month != 0)
                then (attribute to {string-join((cal:isodate($address/../no:c_lastyear),
                        functx:pad-integer-to-length($address/../no:c_ly_month, 2)), '-')})
                else (attribute to {cal:isodate($address/../no:c_lastyear)}),        
   (: Source   :)
       if (empty($address/../no:c_source) or $address/../no:c_source = 0)
       then ()
       else (attribute source {concat('#BIB', $address/../no:c_source/text())}),
       
    (: Desc :)
    
       if ($code < 1)
       then ()
       else (element state {
         if ($address/../no:c_natal = 0)
         then ()
         else (attribute type {'natal'}),
         
         element desc { attribute xml:lang {'zh-Hant'},
         $code/../no:c_addr_desc_chn/text()},
         element desc {attribute xml:lang {'en'},
        $code/../no:c_addr_desc/text()}
            }),
        
       (:     Date ZH     :)
       if (empty($address/../no:c_fy_nh_code) or $address/../no:c_fy_nh_code = 0) 
       then ()
       else (element date { 
                attribute calendar {'#chinTrad'},
                attribute period {concat('#R', $address/../no:c_fy_nh_code/text())},
                if ($address/../no:c_fy_nh_year > 0)
                then (concat($address/../no:c_fy_nh_year/text(), '年'))
                else (),
                
                if ($address/../no:c_fy_day_gz > 0)
                then (concat('-', $address/../no:c_fy_day_gz/text(), '日'))
                else ()
                }),
                
       if (empty($address/../no:c_ly_nh_code) or $address/../no:c_ly_nh_code = 0) 
       then ()
       else (element date { attribute calendar {'#chinTrad'},
                attribute period {concat('#R', $address/../no:c_ly_nh_code/text())},
                if ($address/../no:c_ly_nh_year > 0)
                then (concat($address/../no:c_ly_nh_year/text(), '年'))
                else (),
                
                if ($address/../no:c_ly_day_gz > 0)
                then (concat('-', $address/../no:c_ly_day_gz/text(), '日'))
                else ()
                }),
                    
       if (empty($address/../no:c_notes))
       then ()
       else (element note {$address/../no:c_notes/text()})
    })
};

declare function biog:inst-add ($participant as node()*) as node()* {
(:This function reads the BIOG_INST_DATA for a given c_personid and outputs tei:event.
the location data for the event is inside @where, the time takes when-custorm format as in listOrg.xml

Currently there are no dates in this table?
Desc contents come from $code
:)

(: TODO
- 
:)

(:
 [c_personid] INTEGER,                     x                   [c_bi_role_code] INTEGER PRIMARY KEY,        x                                                              
 [c_inst_name_code] INTEGER,              d                   [c_bi_role_desc] CHAR(255),                    
 [c_inst_code] INTEGER,                    x                   [c_bi_role_chn] CHAR(255),                                                                 
 [c_bi_role_code] INTEGER,                x                   [c_notes] CHAR(255))
 [c_bi_begin_year] INTEGER,               x
 [c_bi_by_nh_code] INTEGER,               x
 [c_bi_by_nh_year] INTEGER,               x
 [c_bi_by_range] INTEGER,                 d
 [c_bi_end_year] INTEGER,                 x
 [c_bi_ey_nh_code] INTEGER,               x
 [c_bi_ey_nh_year] INTEGER,               x
 [c_bi_ey_range] INTEGER,                 d
 [c_source] INTEGER,                       x
 [c_pages] CHAR(255),                      d
 [c_notes] CHAR,                            x
 [c_created_by] CHAR(255),                d  
 [c_created_date] CHAR(255),              d  
 [c_modified_by] CHAR(255),               d  
 [c_modified_date] CHAR(255),             d  
:)


for $address in $global:BIOG_INST_DATA//no:c_personid[. = $participant][. > 0]
let $code := $global:BIOG_INST_CODES//no:c_bi_role_code[. = $address/../no:c_bi_role_code]

let $dy_by := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $address/../no:c_bi_by_nh_code]/../no:c_dy]/../no:c_sort
let $dy_ey := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $address/../no:c_bi_ey_nh_code]/../no:c_dy]/../no:c_sort

let $re_by := count($cal:path/category[@xml:id = concat('R', $address/../no:c_bi_by_nh_code/text())]/preceding-sibling::tei:category) +1
let $re_ey := count($cal:path/category[@xml:id = concat('R', $address/../no:c_bi_ey_nh_code/text())]/preceding-sibling::tei:category) +1

return 
    element event { 
       attribute where {concat('#ORG', $address/../no:c_inst_code/text())},
       
       if ($code > 0)
       then (attribute key {$code/text()})
       else (),    
       
   (:   DATES-ISO :)
       if (empty($address/../no:c_bi_begin_year) or $address/../no:c_bi_begin_year = 0)
       then ()
       else (attribute from {cal:isodate($address/../no:c_firstyear)}),
        
       if (empty($address/../no:c_bi_end_year) or $address/../no:c_bi_end_year = 0)
       then ()
       else (attribute to {cal:isodate($address/../no:c_lastyear)}),
 
 (:     DATES zh  :)
       if ((empty($address/../no:c_bi_by_nh_code) or $address/../no:c_bi_by_nh_code = 0)
          and (empty($address/../no:c_bi_ey_nh_code) or $address/../no:c_bi_ey_nh_code = 0))
       then ()
       else (attribute datingMethod {'#chinTrad'}),       

       if (empty($address/../no:c_bi_by_nh_code) or $address/../no:c_bi_by_nh_code = 0) 
       then ()
       else (attribute from-custom {
                if ($address/../no:c_bi_by_nh_year > 0)
                then (string-join(
                        (concat('D', $dy_by), concat('R',$re_by), concat('Y', $address/../no:c_bi_by_nh_year)),'-')
                      )
                else (string-join((concat('D', $dy_by), concat('R',$re_by)),'-'))}),
       
       if (empty($address/../no:c_bi_ey_nh_code) or $address/../no:c_bi_ey_nh_code = 0) 
       then ()
       else (attribute to-custom {
                if ($address/../no:c_bi_ey_nh_year > 0)
                then (string-join(
                        (concat('D', $dy_by), concat('R',$re_ey), concat('Y', $address/../no:c_bi_ey_nh_year)),'-')
                      )
                else (string-join((concat('D', $dy_by), concat('R',$re_ey)),'-'))}),
       
   (: Source   :)
       if (empty($address/../no:c_source) or $address/../no:c_source = 0)
       then ()
       else (attribute source {concat('#BIB', $address/../no:c_source/text())}),
       
    (: Desc :)
       if ($code > 0)
       then (element desc { attribute xml:lang {'zh-Hant'},
                $code/../no:c_bi_role_chn/text()},
              element desc {attribute xml:lang {'en'},
                $code/../no:c_bi_role_desc/text()})
       else (),
       
                    
       if (empty($address/../no:c_notes))
       then ()
       else (element note {$address/../no:c_notes/text()})
    }
};

declare function biog:biog ($persons as node()*) as item()* {

(: TODO
c_self_bio from $source is dropped change to attribute when refactoring query syntax?
:)

(: 
[tts_sysno] INTEGER,                            x
 [c_personid] INTEGER PRIMARY KEY,            x
 [c_name] CHAR(255),                            x
 [c_name_chn] CHAR(255),                       x
 [c_index_year] INTEGER,                       x
 [c_female] BOOLEAN NOT NULL,                  x
 [c_ethnicity_code] INTEGER,                   x
 [c_household_status_code] INTEGER,           x
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
 [c_death_age_approx] INTEGER,                 x
 [c_fl_earliest_year] INTEGER,                 x
 [c_fl_ey_nh_code] INTEGER,                    x
 [c_fl_ey_nh_year] INTEGER,                    x
 [c_fl_ey_notes] CHAR,                          x
 [c_fl_latest_year] INTEGER,                   x
 [c_fl_ly_nh_code] INTEGER,                    x
 [c_fl_ly_nh_year] INTEGER,                    x
 [c_fl_ly_notes] CHAR,                          x
 [c_surname] CHAR(255),                         x
 [c_surname_chn] CHAR(255),                    x
 [c_mingzi] CHAR(255),                          x
 [c_mingzi_chn] CHAR(255),                     x
 [c_dy] INTEGER,                                 x
 [c_choronym_code] INTEGER,                    x
 [c_notes] CHAR,                                 x
 [c_by_intercalary] BOOLEAN NOT NULL,         x
 [c_dy_intercalary] BOOLEAN NOT NULL,         x
 [c_by_month] INTEGER,                          x
 [c_dy_month] INTEGER,                          x
 [c_by_day] INTEGER,                            x
 [c_dy_day] INTEGER,                            x
 [c_by_day_gz] INTEGER,                        x
 [c_dy_day_gz] INTEGER,                        x
 [TTSMQ_db_ID] CHAR(255),                      x
 [MQWWLink] CHAR(255),                         x
 [KyotoLink] CHAR(255),                        x
 [c_surname_proper] CHAR(255),                x
 [c_mingzi_proper] CHAR(255),                 x
 [c_name_proper] CHAR(255),                   x
 [c_surname_rm] CHAR(255),                    x
 [c_mingzi_rm] CHAR(255),                     x
 [c_name_rm] CHAR(255),                       x
 [c_created_by] CHAR(255),                    x
 [c_created_date] CHAR(255),                 x
 [c_modified_by] CHAR(255),                  x
 [c_modified_date] CHAR(255),                x
 [c_self_bio] BOOLEAN NOT NULL)              d
 :)


for $person in $persons

let $choro := $global:CHORONYM_CODES//no:c_choronym_code[. = $person/../no:c_choronym_code]
let $household := $global:HOUSEHOLD_STATUS_CODES//no:c_household_status_code[. = $person/../no:c_household_status_code]
let $ethnicity := $global:ETHNICITY_TRIBE_CODES//no:c_ethnicity_code[. = $person/../no:c_ethnicity_code]

let $association := $global:ASSOC_DATA//no:c_personid[. = $person]
let $kin := $global:KIN_DATA//no:c_personid[. = $person]
let $status := $global:STATUS_DATA//no:c_personid[. = $person]
let $post := $global:POSTED_TO_OFFICE_DATA//no:c_personid[. = $person]
let $posssession := $global:POSSESSION_DATA//no:c_personid[. = $person]

let $event := $global:EVENTS_DATA//no:c_personid[. = $person]
let $entry := $global:ENTRY_DATA//no:c_personid[. = $person]

let $source := $global:BIOG_SOURCE_DATA//no:c_personid[. = $person]


let $bio-add := $global:BIOG_ADDR_DATA//no:c_personid[. = $person]
let $bio-inst := $global:BIOG_INST_DATA//no:c_personid[. = $person]
let $bio-src := $global:BIOG_SOURCE_DATA//no:c_personid[. = $person]

let $dy_by := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_by_nh_code]/../no:c_dy]/../no:c_sort
let $dy_dy := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_dy_nh_code]/../no:c_dy]/../no:c_sort

let $re_by := count($cal:path/category[@xml:id = concat('R', $person/../no:c_by_nh_code/text())]/preceding-sibling::tei:category) +1
let $re_dy := count($cal:path/category[@xml:id = concat('R', $person/../no:c_dy_nh_code/text())]/preceding-sibling::tei:category) +1

return 
    global:validate-fragment(element person {
        attribute ana {'historical'}, 
        attribute xml:id {concat('BIO', $person/text())},
        if (empty($source))
        then ()
        else (attribute source{concat('#BIB', $source[1]/../no:c_textid/text())}), 
        if (empty($person/../no:c_self_bio) or $person/../no:c_self_bio = 0)
        then ()
        else (attribute resp {'selfbio'}),
        element idno { attribute type {'TTS'}, 
            $person/../no:tts_sysno/text()}, 
(:      NAMES      :)
        element persName {attribute type {'main'},
            if (empty($person/../no:c_name_chn))
            then()
            else (biog:name($person, 'hz')),
            
            if (empty($person/../no:c_name))
            then()
            else (biog:name($person, 'py'))                   
        },
(:      ALIAS  :)
        if (empty($person/../no:c_name_proper))
        then()
        else (biog:name($person, 'proper')),
        
        if (empty($person/../no:c_name_rm))
        then ()
        else (biog:name($person, 'rm')),
        
        biog:alias($person),
        
        if ($person/../no:c_female = 1) 
        then (<sex value="2">f</sex>) 
        else (<sex value ="1">m</sex>),
        
(:      DATES  :)
        if ((empty($person/../no:c_birthyear) or $person/../no:c_birthyear[. = 0]) 
            and (empty($person/../no:c_by_nh_code) or $person/../no:c_by_nh_code[. = 0]))
        then ()
        else (element birth { 
                if (empty($person/../no:c_birthyear) or $person/../no:c_birthyear[. = 0])
                then ()
                else (
                attribute when {string-join((cal:isodate($person/../no:c_birthyear),
                    if ($person/../no:c_by_month[. > 0])
                    then (functx:pad-integer-to-length($person/../no:c_by_month/text(), 2))
                    else (),
                    if ($person/../no:c_by_day[. > 0])
                    then (functx:pad-integer-to-length($person/../no:c_by_day/text(), 2))
                    else ()), '-')}
                 ),
                 if  ($person/../no:c_by_nh_code[.  > 0])
                 then (attribute datingMethod {'#chinTrad'},
                        attribute when-custom {
                        if ($person/../no:c_by_nh_year[.  > 0])
                        then (string-join(
                                (concat('D', $dy_by), concat('R',$re_by), concat('Y', $person/../no:c_by_nh_year)),'-')
                              )
                        else (string-join(
                                (concat('D', $dy_by), concat('R',$re_by)),'-')
                              )
                        })
                 else (),
                 if ($person/../no:c_by_nh_code > 0 or $person/../no:c_by_nh_year or $person/../no:c_by_day_gz > 0)
                 then (element date { attribute calendar {'#chinTrad'},
                    attribute period{concat('#R',$person/../no:c_by_nh_code/text())},
                 $dy_by/../no:c_dynasty_chn/text(), $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_by_nh_code]/../no:c_nianhao_chn/text(), 
                 string-join(($person/../no:c_by_nh_year/text(), $person/../no:c_by_day_gz/text()), ':')
                 })
                 else ()
            }),
        if ((empty($person/../no:c_deathyear) or $person/../no:c_deathyear[. = 0]) 
            and (empty($person/../no:c_dy_nh_code) or $person/../no:c_dy_nh_code[. = 0]))
        then ()
        else (element death { 
                if (empty($person/../no:c_deathyear) or $person/../no:c_deathyear[. = 0])
                then ()
                else (
                attribute when {string-join((cal:isodate($person/../no:c_deathyear),
                    if ($person/../no:c_dy_month [. > 0])
                    then (functx:pad-integer-to-length($person/../no:c_dy_month/text(), 2))
                    else (),
                    if ($person/../no:c_dy_day[. > 0])
                    then (functx:pad-integer-to-length($person/../no:c_dy_day/text(), 2))
                    else ()), '-')}
                 ),
                 if  ($person/../no:c_dy_nh_code[.  > 0])
                 then (attribute datingMethod {'#chinTrad'},
                        attribute when-custom {
                        if ($person/../no:c_dy_nh_year[.  > 0])
                        then (string-join(
                                (concat('D', $dy_dy), concat('R',$re_dy), concat('Y', $person/../no:c_dy_nh_year)),'-')
                              )
                        else (string-join(
                                (concat('D', $dy_dy), concat('R',$re_dy)),'-')
                              )
                        })
                 else (), 
                 if ($person/../no:c_dy_nh_code > 0 or $person/../no:c_dy_nh_year or $person/../no:c_dy_day_gz > 0)
                 then (
                 element date { attribute calendar {'#chinTrad'},
                    attribute period{concat('#R',$person/../no:c_dy_nh_code/text())},
                 $dy_dy/../no:c_dynasty_chn/text(), $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_dy_nh_code]/../no:c_nianhao_chn/text(), 
                 string-join(($person/../no:c_dy_nh_year/text(), $person/../no:c_dy_day_gz/text()), ':')
                 })
                 else ()
            }),
            let $earliest := $person/../no:c_fl_earliest_year
            let $latest := $person/../no:c_fl_latest_year
            let $index := $person/../no:c_index_year
            let $dy := $person/../no:c_dy
            return
                if ($earliest or $latest or $index or $dy > 0) 
                then (element floruit 
                            { if ($earliest/text() and $latest/text() != 0) 
                              then ( attribute notBefore {cal:isodate($earliest/text())}, 
                                      attribute notAfter {cal:isodate($latest/text())})
                              else if ($earliest/text() != 0)
                                    then (attribute notBefore {cal:isodate($earliest/text())})
                                    else if ($latest/text() != 0)
                                          then ( attribute notAfter {cal:isodate($latest/text())})
                                          else (),     
                                          
                                    if ($index = 0 or $dy < 1)
                                    then ()
                                    else (element date {
                                            if ($index != 0)
                                            then (attribute when {cal:isodate($index)}) 
                                            else (),  
                                    
                                            if ($dy > 0)
                                            then (attribute datingMethod {'#chinTrad'}, 
                                                   attribute period {concat('#D', $dy/text())}, 
                                                    $global:DYNASTIES//no:c_dy[. =$dy]/../no:c_dynasty_chn/text())
                                            else ()
                            }), 
                            if (empty($person/../no:c_fl_ey_notes) and empty($person/../no:c_fl_ly_notes))
                            then ()
                            else (element note {$person/../no:c_fl_ey_notes/text() , $person/../no:c_fl_ly_notes/text()})                                
                       })
               else(),
               
            if ($person/../no:c_death_age_approx > 0)
            then (<age cert="medium">
                    {$person/../no:c_death_age_approx/text()}</age>)
            else (), 
            
            if ($person/../no:c_death_age > 0)
            then (<age>{$person/../no:c_death_age/text()}</age>)
            else (), 
            
(:          Ethniciy, Tribe etc  :)
            if ($person/../no:c_household_status_code > 0) 
            then (<trait type="household">                
                <label xml:lang="zh-Hant">{$household/../no:c_household_status_desc_chn/text()}</label>
                <label xml:lang="en">{$household/../no:c_household_status_desc/text()}</label>
            </trait>)
            else(), 
            
            if ($person/../no:c_ethnicity_code > 0) 
            then (<trait type="ethnicity" key="{$ethnicity/../no:c_group_code/text()}">
                <label>{$ethnicity/../no:c_ethno_legal_cat/text()}</label>
                        <desc xml:lang="zh-Hant">{$ethnicity/../no:c_name_chn/text()}</desc>
                        <desc xml:lang="zh-Latn-alalc97">{$ethnicity/../no:c_name/text()}</desc>
                        <desc xml:lang="en">{$ethnicity/../no:c_romanized/text()}</desc>
                        {if ($ethnicity/../no:c_notes) 
                        then (<note>{$ethnicity/../no:c_notes/text()}</note>)
                        else()
                        }
               </trait>)
            else(), 
            
            if ($person/../no:c_tribe) 
            then (<trait type="tribe">
                <desc>{$person/../no:c_tribe/text()}</desc>
            </trait>)
            else(), 
            
            if ($person/../no:c_notes)
            then (<note>{$person/../no:c_notes/text()}</note>)
            else (), 
            
            if (empty($kin) and empty ($association))
            then ()
            else (element affiliation {
                    if (empty($kin))
                    then ()
                    else (element note {
                            element listPerson {
                                element personGrp { attribute role {'kin'}},
                                element listRelation { attribute type {'kinship'},
                                    biog:kin($person)}
                                }
                            }),
                        
                    if (empty($association))
                    then ()
                    else (element note {
                            element listPerson { 
                                element personGrp { attribute role {'associates'}},
                                element listRelation { attribute type {'associations'},
                                    biog:asso($person)}
                                }
                            })
                    }),
            if (empty($status)) 
            then ()
            else(<socecStatus>
                    {if ($status) 
                    then(biog:status($person))
                    else()}
                 </socecStatus>),
            
            if (empty($post))
            then ()
            else (biog:new-post($person)),
                        
            if (empty($event) and empty($entry))
            then ()
            else (<listEvent>
                    {if ($event)
                    then (biog:event($person))
                    else ()
                    }
                    {if ($entry)
                    then (biog:entry($person))
                    else()
                    }                      
                </listEvent>),
            
            if (empty($posssession)) 
            then ()
            else (biog:posses($person)), 
            
            if (empty($bio-add))
            then ()
            else (biog:pers-add($person)), 
            
            if (empty($bio-inst))
            then ()
            else (biog:inst-add($person)),
            
            if (empty($person/../no:TTSMQ_db_ID) and empty($person/../no:MQWWLink) and empty($person/../no:KyotoLink))
            then ()
            else (<linkGrp>
                    {let $links := ($person/../no:TTSMQ_db_ID, $person/../no:MQWWLink, $person/../no:KyotoLink)
                    for $link in $links[. != '']
                    return
                    <ptr target="{$link/text()}"/>}        
                  </linkGrp>),
                  
           global:create-mod-by($person/../no:c_created_by, $person/../no:c_modified_by)       
    }, 'person')
    
};

(:Because of the large number (>370k) of individuals
the write operation of biographies.xql is slighlty more complex. 
Instead of putting its data into a single file or collection, 
it creates a tree of collections (chunks) and subcollections (blocks).

In additions to the person records themselves it also creates a listPerson file 
at each level. 

As a result cbdbTEI.xml includes links to 37 listPerson files 
covering chunks of $chunk-size persons each (10k).  

"chunk" collections contain a single list.xml file and $block-size (50) subcollectoins. 
This file contains xi:include statments to 1 listPerson.xml file per "block" subcollection.
Each block contains a single listPerson.xml file on the same level as the individual
$ppl-per-block (200) person records .
:)

let $test := $global:BIOG_MAIN//no:c_personid[. = 914]
let $full := $global:BIOG_MAIN//no:c_personid[. > 0]

let $count := count($full)

let $chunk-size := 10000
let $block-size := 50
let $ppl-per-block := 200

for $i in 1 to $count idiv $chunk-size + 1 
let $chunk := xmldb:create-collection("/db/apps/cbdb-data/target/listPerson", 
    concat('chunk-', functx:pad-integer-to-length($i, 2)))
  

for $j in subsequence($full, ($i - 1) * $block-size, $block-size)
let $collection := xmldb:create-collection($chunk, concat('block-', 
    functx:pad-integer-to-length($j, 4)))    
    

for $individual in subsequence($full, ($j - 1) * $ppl-per-block, $ppl-per-block)
let $person := biog:biog($individual)
let $file-name := concat('cbdb-', 
    functx:pad-integer-to-length(substring-after(data($person/@xml:id), 'BIO'), 7), '.xml')

return 
    try {(xmldb:store($collection, $file-name, $person), 

         xmldb:store($collection, 'listPerson.xml', 
            <listPerson>{
                    for $files in collection($collection)
                    let $n := functx:substring-after-last(base-uri($files), '/')
                    where $n != 'listPerson.xml'
                    order by $n
                    return 
                        <xi:include href="{$n}" parse="xml"/>}
                    </listPerson>), 
            
        xmldb:store($chunk, concat('list-', $i, '.xml'), 
            <listPerson>{                
                    for $lists in collection($chunk)
                    let $m := functx:substring-after-last(base-uri($lists), '/') 
                    where $m  = 'listPerson.xml'
                    order by base-uri($lists)
                    return
                        <xi:include href="{substring-after(base-uri($lists), 
                            concat('/chunk-', functx:pad-integer-to-length($i, 2), '/'))}" parse="xml"/>}
                    </listPerson>))}
                    
    catch * {xmldb:store($collection, 'error.xml', 
             <error>Caught error {$err:code}: {$err:description}.  Data: {$err:value}.</error>)}


