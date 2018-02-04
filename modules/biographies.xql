xquery version "3.0";

(:~
: The biographies module transforms core person, and relationship data from CBDB in TEI. 
: The data is stored inside a nested heirarchy of collections  and sub-collections linked by xInclude statements. 
: 
: @author Duncan Paterson
: @version 0.7
: 
: @return 370k person elements stored individualiy as ``/listPerson/chunk-XX/block-XXXX/cbdb-XXXXXXX.xml``:)

module namespace biog="http://exist-db.org/apps/cbdb-data/biographies";

import module namespace functx="http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";


(:NAMES:)
declare 
    %test:pending("fragment")    
    %test:assertExists("$result/persName/forename")    
function biog:name ($names as node()*, $lang as xs:string?) as node()* {
(:~
: biog:name reads extended name parts from BIOG_MAIN.
: To avoid duplication biog:name checks if sure-/forename components can be fully identified,
: and returns the respective elements, otherwise persName takes a single string value. 
:
: @param $names variations of ``c_name`` from different tables. 
: @param $lang can take 4 values:
:    *   'py' for pinyin, 
:    *   'hz' for hanzi, 
:    *   'proper', or 
:    *   'rm' for names other then Chinese.
:
: @return ``<persName>...</persName>``:)

let $choro := $global:CHORONYM_CODES//no:c_choronym_code[. = $names/../no:c_choronym_code]

let $py :=
    for $name in $names/../no:c_name    
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
    return
        if ($name/text() eq concat($name/../no:c_surname_chn/text(), $name/../no:c_mingzi_chn/text()))
        then (<persName xml:lang="zh-Hant">
                    <surname>{$name/../no:c_surname_chn/text()}</surname>
                    <forename>{$name/../no:c_mingzi_chn/text()}</forename>
                    {if (empty($choro) or $choro[. < 1])
                    then ()
                    else (<addName type="choronym">{$choro/../no:c_choronym_chn/text()}</addName>)
                    }
                </persName>)
        else (<persName xml:lang="zh-Hant">
                {$name/text()}
                {if (empty($choro) or $choro[. < 1])
                    then ()
                    else (<addName type="choronym">{$choro/../no:c_choronym_chn/text()}</addName>)
                    }
                </persName>)

let $proper :=
    for $name in $names/../no:c_name_proper
    return
        if ($name/text() eq concat($name/../no:c_surname_proper/text(), ' ', $name/../no:c_mingzi_proper/text()))
        then (<persName type="original">
                    <surname>{xmldb:decode($name/../no:c_surname_proper/string())}</surname>
                    <forename>{xmldb:decode($name/../no:c_mingzi_proper/string())}</forename>
               </persName>)
        else (<persName type="original">{xmldb:decode($name/string())}</persName>)
        
let $rm :=
    for $name in $names/../no:c_name_rm
    return
        if ($name/text() eq concat($name/../no:c_surname_rm/text(), ' ', $name/../no:c_mingzi_rm/text()))
        then (<persName type="original">
                    <surname>{xmldb:decode($name/../no:c_surname_rm/string())}</surname>
                    <forename>{xmldb:decode($name/../no:c_mingzi_rm/string())}</forename>
               </persName>)
        else (<persName type="original">{xmldb:decode($name/string())}</persName>)
        
                

return
    switch($lang)
        case 'py' return $py 
        case 'hz' return $hz
        case 'proper' return $proper
        case 'rm' return $rm
        default return ()
}; 

declare 
    %test:pending("fragment")
    %test:assertEquals("xxx")
function biog:alias ($person as node()*) as node()* {
(:~ 
: biog:alias outputs aliases, such as pen-names, reign titles, from ALTNAME_DATA, and ALTNAME_CODES. 
:
: @param $person is a ``c_personid``
: @return ``<persName type = "alias">...<person>``:)

for $person in $global:ALTNAME_DATA//no:c_personid[. =$person]
let $code := $global:ALTNAME_CODES//no:c_name_type_code[. = $person/../no:c_alt_name_type_code]

return 
    if (empty($person)) 
    then ()
    else (element persName { attribute type {'alias'},          
    
        for $att in $person/../*[. != '0']
        order by local-name($att) 
        return 
            typeswitch ($att)
                case element (no:c_alt_name_type_code) return attribute key {concat('AKA', $att/text())}
                case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
                default return (),
                
        for $n in $person/../* 
        order by local-name($n) descending
        return     
            typeswitch ($n)
                case element (no:c_alt_name_chn) 
                    return if ($code[. > 1])
                            then (element addName {attribute xml:lang {'zh-Hant'},
                                        $n/text()},
                                    element term {$code/../no:c_name_type_desc_chn/text()})
                            else (element addName {attribute xml:lang {'zh-Hant'},
                                        $n/text()})    
                case element (no:c_alt_name)
                    return if ($code[. > 1]) 
                            then (element addName {attribute xml:lang {'zh-Latn-alalc97'},                        
                                        $n/text()},
                                    element term {$code/../no:c_name_type_desc/text()})
                            else (element addName {attribute xml:lang {'zh-Latn-alalc97'},                        
                                $n/text()})
                case element (no:c_notes) return element note {$n/text()}
            default return ()})       
};

(:RELATIONS:)
declare 
    %test:pending("fragment")
    %test:assertXPath("$result/relation/@name")
function biog:kin ($self as node()*) as node()* {
(:~ 
: biog:kin  constructs an egocentric network of kinship relations from: KING_DATA, KING_CODES and Kin_Mourning.
: The output's structure should match biog:asso's.
:
: The list on page 13f of the *CBDB User's Guide* is incomplete. ``$tie`` includes values not mentioned in the documentation.
:
: @param $self is a ``c_personid`` 
: @param $tie undocumented values:
:    *   ``(male)`` -> ``♂``
:    *   ``(female)`` -> ``♀``
:    *   ``©`` -> ``of concubine`` alt ``⚯``?
:    *   ``(claimed)`` ->
:    *   ``(eldest surviving son)`` ->
:    *   ``(only ...)`` ->
:    *   ``(apical)`` ->
: @see #asso
: @see http://projects.iq.harvard.edu/files/cbdb/files/cbdb_users_guide.pdf
: @see http://www.unicode.org/L2/L2003/03364-n2663-gender-rev.pdf
:
: @return ``<relation>...</relation>``:)
    
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
                for $att in $tie/../*[. != '0']
                order by local-name($att)
                return 
                    typeswitch ($att)
                        case element (no:c_kincode) return attribute key {$att/text()}
                        case element (no:c_pick_sorting) return attribute sortKey{$att/text()}
                        case element (no:c_kinrel) return attribute name {
                            if (contains($att/text(), ' ('))
                            then (substring-before($att/text(), ' ('))
                            else if (contains($att/text(), 'male)'))
                                then (replace(replace($att/text(), '\(male\)', '♂'), '\(female\)', '♀'))
                                else (translate($att/text(), '#', '№'))}
                        case element (no:c_source) return attribute source {$att/text()}
                        case element (no:c_autogen_notes) return attribute type {'auto-generated'}
                      default return (),
                
                if (empty($tie/../no:c_kinrel_chn) and empty ($tie/../no:c_kinrel_alt))
                then ()
                else (element desc { attribute type {'kin-tie'}, 
                        
                        (: jing doesn like note here during validation :)
                        if ($kin/../no:c_notes)
                        then (element label {$kin/../no:c_notes/text()})
                        else (), 
                        
                        for $x in $tie/../*
                        order by local-name($x) descending
                        return 
                            typeswitch($x)
                                case element (no:c_kinrel_chn) return element desc { attribute xml:lang {'zh-Hant'},
                                    $x/text()}
                                case element (no:c_kinrel_alt) return element desc { attribute xml:lang {'en'},
                                    $x/text()}
                            default return (),                               
                        
                        if (empty($mourning))
                        then ()
                        else (element trait {
                                    attribute type {'mourning'},
                                    attribute subtype {$mourning/../no:c_kintype/text()},
                                    
                            for $y in $mourning/../*
                            order by local-name($y) descending
                            return
                                typeswitch($y)
                                    case element (no:c_mourning_chn) 
                                        return element label { attribute xml:lang {"zh-Hant"},
                                            $y/text()}
                                    case element (no:c_kintype_desc_chn) 
                                        return element desc { attribute xml:lang {"zh-Hant"},
                                            $y/text()}        
                                    case element (no:c_kintype_desc)
                                        return element desc {attribute xml:lang {"en"},
                                            $y/text()}
                                    default return ()                             
                               })     
                    })
                )
        }
};

declare 
    %test:pending("compare with biog:kin")
    %test:assertEquals("?")
function biog:asso ($ego as node()*) as node()* {
(:~
: biog:asso constructs a network of association relations from: ASSOC_DATA, ASSOC_CODES, 
: ASSOC_TYPES, and ASSOC_CODE_TYPE_REL. The distance measured by ``c_assoc_range`` is dropped.  
:
: Annotations from: SCHOLARLYTOPIC_CODES, OCCASION_CODES, and LITERARYGENRE_CODES.
:
: The output's structure should match biog:kin's.
:
: @param $ego is a ``c_personid``
: @see #kin
: @return ``<relation>...</relation>``:)

(:
: Because TEI declares  active/passive relations more strictly then CBDB, the following relations
: remain problematic:
:let $passive := ('Executed at the order of', 'Killed by followers of',
:                'was served by the medical arts of',
:                'Funerary stele written (for a third party) at the request of',
:                'Killed by followers of', 'His coalition attacked', 'Was claimed kin with')
:                
: let $active :=  ('Knew','Tried and found guilty'
:       ,'Fought against the rebel','Hired to teach in lineage school' 
:       ,'proceeded with (friendship)','Defeated in battle'
:       ,'Treated with respect','Served as lady-in-waiting' 
:       ,'friend to Y when Y was heir-apparent','recruited Y to be instructor at school,academy' 
:       ,'saw off on journey','took as foster daughter'
:       ,'Memorialized concerning','Took as foster son'
:       ,'opposed militarily','Toady to Y'
:       ,'Relied on book by','Refused affinal relation offered by'
:       ,'Requested Funerary stele be written by','Requested Tomb stone (mubiao) be written by'
:       ,'opposed assertion of emperorship by'):)

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
        (: determin mutual or active/passive pairing       :)
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
                
        (: DESC :)
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
                    
            (: STATE :)
                     if ($individual/../no:c_addr_id[. > 0] or $individual/../no:c_inst_code[. > 0]
                        or exists($individual/../no:c_assoc_year) or $individual/../no:c_occasion_code[. > 0]
                        or $individual/../no:c_topic_code[. > 0] or $individual/../no:c_litgenre_code[. > 0]
                        or $individual/../no:c_tertiary_personid[. > 0] or $individual/../no:c_kin_id[. > 0]
                        or $individual/../no:c_assoc_kin_id[. > 0])
                        
                     then (element state {              
                        
                        for $add in $individual/../no:c_addr_id[. > 0] 
                        for $org in  $individual/../no:c_inst_code[. > 0]                               
                        return
                           attribute ref {concat('#PL', $add/text()), concat('#ORG', $org/text())},
                        
                        for $att in $individual/../*[. != '0']
                        order by local-name($att)
                        return 
                            typeswitch($att)
                                case element (no:c_assoc_year) return attribute when {cal:isodate($att)}
                                case element (no:c_occasion_code) return attribute ana {$att/text()}
                                case element (no:c_topic_code) return attribute type {$att/text()}
                                case element (no:c_litgenre_code) return attribute subtype {$att/text()}
                            default return (),
                        
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
                                       }})
                        })
                     else()
                 })
             )
        }
};

(:GENERAL STATUS / STATE:)
declare 
    %test:pending("not essential right now")
    %test:assertEmpty("$result//label")
function biog:status ($achievers as node()*) as node()* {

(:~
: biog:status reads STATUS_DATA, and STATUS_CODES and transforms them into state.
:
: Two tables are currently empty: STATUS_TYPES, and  STATUS_CODE_TYPE_REL.
:
: This function drops ``c_notes``, and ``c_supplement`` from ``STATUS_DATA``.
: @param $achievers is a ``c_personid``
:
: @return ``<state type = "status">...</state>``:)

(:
: Should STATUS_TYPES, and  STATUS_CODE_TYPE_REL be updated with a future release, the following lines can be added 
: to the return clause of the $x variable.
: This will add label elements which need to be wrapped inside a general desc element:
: 
: let $type := $global:STATUS_TYPES//no:c_status_type_code[. =$type-rel/../no:c_status_type_code]
: let $type-rel := $global:STATUS_CODE_TYPE_REL//no:c_status_code[. = $status/../no:c_status_code]
: ...
: case element (no:c_status_type_desc_chn) return element label {attribute xml:lang {'zh-Hant'}, $x/text()}
: case element (no:c_status_type_desc) return element label {attribute xml:lang {'en'}, $x/text()}
:)

for $status in $global:STATUS_DATA//no:c_personid[. = $achievers]

let $code := $global:STATUS_CODES//no:c_status_code[. = $status/../no:c_status_code]

return 
    if ($status/../no:c_status_code[. > 0]) 
    then (element state { attribute type {'status'},
          for $att in $status/../*[. != '0']
          order by local-name($att)
          return 
            typeswitch ($att)
            case element (no:c_status_code) return attribute subtype {$att/text()}
                case element (no:c_firstyear) return attribute from {cal:isodate($att/text())}
                case element (no:c_lastyear) return attribute to {cal:isodate($att/text())}
                case element (no:c_sequence) return attribute n {$att/text()}
                case element (no:source) return attribute source {concat('#BIB', $att/text())}                
            default return (),
            
          for $x in $code/../*
          order by local-name($x) descending
          return
            typeswitch ($x)
                case element (no:c_status_desc_chn) return element desc { attribute xml:lang {'zh-Hant'}, 
                (:  filter '[', ']' from description but return without trailing whitespace  :)
                    normalize-space(string-join(tokenize($x/text(), '\W+')))}
                case element (no:c_status_desc) return element desc { attribute xml:lang {'en'}, $x/text()}
            default return ()     
          })
    else ()
};

(:GENERAL EVENTS:)
declare 
    %test:pending("easy")
    %test:assertXPath("$result//@type[. = 'general']")
function biog:event ($participants as node()*) as node()* {
(:~
: biog:event reads EVENTS_DATA, EVENT_CODES, EVENTS_ADDR to generate an event element. 
: The structure of biog:event is mirrored by biog:entry. 
: 
: Currently, there are no 'py' or 'en' descriptions in the source data,
: hence we define a single xml:lang attribute on the parent element. 
: 
: @param $participants is a ``c_personid``
: @see #entry
:
: @return ``<event>...</event>``:)

for $event in $global:EVENTS_DATA//no:c_personid[. = $participants]
let $code := $global:EVENT_CODES//no:c_event_code[. = $event/../no:c_event_code]
let $event-add := $global:EVENTS_ADDR//no:c_event_record_id[. = $event/../no:c_event_record_id]

return             
    element event { attribute xml:lang {'zh-Hant'},
        for $att in $event/../*[. != '0']
        order by local-name($att)
        return
            typeswitch($att)
                case element (no:c_year) return attribute when {cal:isodate($att)}
                case element (no:c_addr_id) return attribute where {concat('#PL', $att/text())}
                case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
                case element (no:c_sequence) return attribute sortKey {$att/text()}
            default return (),
        
        attribute type{'general'},
        
        if (empty($event/../no:c_event) and empty($event/../no:c_role) and empty($code))
        then (element desc {'unkown'})
        else if (empty($event/../no:c_event) and empty($event/../no:c_role) and $code[. > 0])
              then (element desc {$code/../no:c_event_name_chn/text()})
              else (if ($code[. > 0])
                    then (element head {$code/../no:c_event_name_chn/text()})
                    else (), 
            (: some funky spaces make the normalization necessary here :)
                    for $n in $event/../*[. != '0']
                    order by local-name($n)
                    return 
                        typeswitch($n)
                            case element (no:c_event) return element label {normalize-space($n/text())}
                            case element (no:c_role) return element desc {normalize-space($n/text())}
                            case element (no:c_notes) return element note {normalize-space($n/text())}
                        default return ())
    }        
};

(:EXAMINATIONS and OFFICES:)
declare   
    %test:pending("needs fragment $global:BIOG_MAIN//no:c_personid[. = 914]")
    %test:assertXPath('$result//event[type =16]/../event[type = 13]')
    function biog:entry ($initiates as node()?) as node()* {
(:~
: biog:entry transforms ENTRY_DATA, ENTRY_CODES, ENTRY_TYPES, ENTRY_CODE_TYPE_REL, and PARENTAL_STATUS_CODES
: into a typed and annotated event. Currently, ``c_inst_code``, and ``c_exam_field`` are empty.
: It's output should match the structure of biog:event.
:
: @param $initiates is a ``c_personid``
: @see #event
:
: @return ``<event>...</event>``:)



for $initiate in $global:ENTRY_DATA//no:c_personid[. =$initiates]

let $code := $global:ENTRY_CODES//no:c_entry_code[. = $initiate/../no:c_entry_code]
let $type-rel := $global:ENTRY_CODE_TYPE_REL//no:c_entry_code[ . = $initiate/../no:c_entry_code]
let $type :=  $global:ENTRY_TYPES//no:c_entry_type[. = $type-rel/../no:c_entry_type]
let $parent-stat := $global:PARENTAL_STATUS_CODES//no:c_parental_status_code[. = $initiate/../no:c_parental_status/text()]


return
    element event{
    (: about 100 entries are tagede both by '7 specials' and other (id =90) hence this awkward filter :)
        for $att in $initiate/../*[. != '0']
        order by local-name($att)
        return
            typeswitch ($att)
                case element (no:c_entry_type) return if (count($type) > 1)
                                                            then (attribute type {$type[. < 90][1]/text()})
                                                            else if (empty($type))
                                                                  then (attribute type {'00'})
                                                                  else (attribute type {$att/text()})
                case element (no:c_entry_code) return attribute subtype {$att/text()}
                case element (no:c_inst_code) return attribute ref {concat('#ORG', $att/text())}
                case element (no:c_year) return attribute when {cal:isodate($att)}
                case element (no:c_addr_id) return attribute where {concat('#PL', $att/text())}
                case element (no:c_sequence) return attribute sortKey {$att/text()}
                case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
            default return (),
        
        for $sponsor in $initiate
        return 
            if ($sponsor/../no:c_kin_id[. > 0] or $sponsor/../no:c_assoc_id[. > 0])
            then (attribute role {concat('#BIO', $sponsor/text())})
            else (),             
        
        (: HEAD :)
            element head {'entry'},
            
        (: LABEL :)
            if ($code[. < 1])
            then (element label {'unkown'})
            else (element label {attribute xml:lang {'zh-Hant'},
                    $code/../no:c_entry_desc_chn/text()},
                element label {attribute xml:lang{'en'},
                    $code/../no:c_entry_desc/text()}),   
         (: DESC :)         
            if ($type[. < 1] or empty($type))
            then ()
            else if (count($type) > 1) 
            
                  then (element desc { attribute type {$type[. < 90][1]/../no:c_entry_type_level/text()},
                            attribute subtype {$type[. < 90][1]/../no:c_entry_type_sortorder/text()},
                        element desc {attribute xml:lang {'zh-Hant'},
                            if ($type = 16)
                            then (attribute ana {'七色補官門'})
                            else (),
                            
                            $type[. < 90][1]/../no:c_entry_type_desc_chn/text()},
                            
                        element desc {attribute xml:lang{'en'},
                            if ($type = 16)
                            then (attribute ana {'7specials'})
                            else (),
                            
                            $type[. < 90][1]/../no:c_entry_type_desc/text()}})
                            
                  else (element desc { attribute type {$type/../no:c_entry_type_level/text()},
                            attribute subtype {$type/../no:c_entry_type_sortorder/text()},
                        element desc {attribute xml:lang {'zh-Hant'},
                            $type/../no:c_entry_type_desc_chn/text()},
                        element desc {attribute xml:lang{'en'},
                            $type/../no:c_entry_type_desc/text()}}), 
                    
            for $n in $initiate/../*[. != '0']
            order by local-name($n)
            return
                typeswitch ($n)
                    case element (no:c_exam_field) return element note { attribute type {'field'}, $n/text()}
                    case element (no:c_attempt_count) return element note { attribute type {'attempts'}, $n/text()}
                    case element (no:c_exam_rank) return element note { attribute type {'rank'}, $n/text()}
                    case element (no:c_notes) return element note {$n/text()}
                    case element (no:c_parental_status) 
                        return element note { attribute type {'parental-status'}, 
                                    element trait {
                                        attribute type {'parental-status'},
                                        attribute key {$n/text()},
                                      element label {attribute xml:lang {'zh-Hant'},
                                            $parent-stat/../no:c_parental_status_desc_chn/text()}, 
                                      element label { attribute xml:lang {'zh-Latn-alalc97'},
                                            $parent-stat/../no:c_parental_status_desc/text()}}}
                default return ()
    }                             
};

declare 
    %test:pending("fragment")
function biog:new-post ($appointees as node()*) as node()* {
(:~ 
: biog:new-post reads POSTED_TO_OFFICE_DATA, POSTED_TO_ADDR_DATA, OFFICE_CATEGORIES, 
: APPOINTMENT_TYPE_CODES, and ASSUME_OFFICE_CODES to generate socecStatus pointing to the office taxonomy. 
: The precise role of POSTED_TO_ADDR_DATA is somewhat unclear. 
:
: @param $appointees is a ``c_personid``
:
: @return ``<socecStatus scheme="#office">...</socecStatus>``:)

for $post in $global:POSTED_TO_OFFICE_DATA//no:c_personid[. = $appointees]/../no:c_posting_id

let $addr := $global:POSTED_TO_ADDR_DATA//no:c_posting_id[. = $post]
let $cat := $global:OFFICE_CATEGORIES//no:c_office_category_id[. = $post/../no:c_office_category_id]
let $appt := $global:APPOINTMENT_TYPE_CODES//no:c_appt_type_code[. = $post/../no:c_appt_type_code]
let $assu := $global:ASSUME_OFFICE_CODES//no:c_assume_office_code[. = $post/../no:c_assume_office_code]

order by $post/../no:c_sequence

return
    element socecStatus{ attribute scheme {'#office'}, 
        attribute code {concat('#OFF', $post/../no:c_office_id)},
        
        element state {attribute type {'posting'},
        
            if ($addr/../no:c_addr_id[. = 0])
            then ()
            else (attribute ref {concat('#PL', $addr/../no:c_addr_id/text())}),
            
            for $att in $post/../*[. != '0']
            order by local-name($att)
            return
                typeswitch($att)
                    case element (no:c_posting_id) return attribute n {$att/text()}
                    case element (no:c_sequence) return attribute key {$att/text()}
                    case element (no:c_firstyear) return attribute notBefore {cal:isodate($att)}
                    case element (no:c_lastyear) return attribute notAfter {cal:isodate($att)}
                    case element (no:c_source) return attribute source {concat('#BIB', $att/text())}                    
               default return (),
         (: Desc:)
            for $n in $post/../*
            order by local-name($n)
            return
                typeswitch($n)
                    case element (no:c_appt_type_code) 
                        return element desc { 
                                    element label {'appointment'},
                                    element desc { attribute xml:lang {'zh-Hant'},
                                        $appt/../no:c_appt_type_desc_chn/text()},
                                        
                                if (empty($appt/../no:c_appt_type_desc))
                                then ()
                                else (element desc { attribute xml:lang {'en'}, 
                                    $appt/../no:c_appt_type_desc/text()})}
                                    
                    case element (no:c_assume_office_code) 
                        return element desc { 
                                    element label {'assumes'},
                                    element desc { attribute xml:lang {'zh-Hant'},
                                        $assu/../no:c_assume_office_desc_chn/text()}, 
                                    element desc { attribute xml:lang {'en'}, 
                                        $assu/../no:c_assume_office_desc/text()}}                                        
                    case element (no:c_notes) return element note {$n/text()}
                default return ()},
                
                if ($cat[. = 0])
                then ()
                else (element state { attribute type {'office-type'},
                    attribute n {$cat/text()}, 
                    for $x in $cat/../*
                    order by local-name($x) descending
                    return
                        typeswitch ($x)
                            case element (no:c_category_desc_chn) return element desc { attribute xml:lang {'zh-Hant'}, $x/text()}
                            case element (no:c_category_desc) return element desc { attribute xml:lang {'en'}, $x/text()}                            
                        default return (), 
                        
                    if (empty($cat/../no:c_notes))
                    then ()
                    else (element note {$cat/../no:c_notes/text()})
                })
        }
};

declare 
    %test:pending("fragment")
function biog:posses ($possessions as node()*) as node()* {
(:~ 
: biog:possess reads POSSESSION_DATA, POSSESSION_ACT_CODES, POSSESSION_ADDR, 
: and MEASURE_CODES. It produces a state element.
:
: There is barely any data in here so future version will undoubtedly see changes. 
:
: @param $possessions is a ``c_personid``
:
: @return ``<state type="possession">...</state>``:)

for $stuff in $global:POSSESSION_DATA//no:c_personid[. = $possessions][. > 0]

let $act := $global:POSSESSION_ACT_CODES//no:c_possession_act_code[ . = $stuff/../no:c_possession_act_code]
let $where := $global:POSSESSION_ADDR//no:c_possession_row_id[. = $stuff/../no:c_possession_row_id]
let $unit := $global:MEASURE_CODES//no:c_measure_code[. = $stuff/../no:c_measure_code]

order by $stuff/../no:c_sequence

return 
    element state{        
        attribute type {'possession'},       
            
        for $att in $stuff/../*[. != '0']
        order by local-name($att)
        return
            typeswitch($att)
                case element (no:c_possession_row_id) return attribute xml:id {concat('POS', $att/text())}
                (:     in the future the return for $units needs to be tokenized  :)
                case element (no:c_measure_code) return attribute unit {$unit/../no:c_measure_desc/text()}
                case element (no:c_quantity) return attribute quantity {number($att/text())}
                case element (no:c_sequence) return attribute n {$att/text()}
                case element (no:c_possession_yr) return attribute when {cal:isodate($att)}
                case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
                case element (no:c_possession_act_code) return attribute subtype {$act/../no:c_possession_act_desc/text()}
            default return (),            
    (: DESC  :)
        element desc {
            for $n in $stuff/../*[. != '0']
            order by local-name($n) descending
            return
                typeswitch($n)
                    case element (no:c_possession_desc_chn) return element desc { attribute xml:lang {'zh-Hant'}, $n/text()}
                    case element (no:c_possession_desc) return element desc { attribute xml:lang {'en'}, $n/text()}
                    case element (no:c_addr_id) return element placeName { attribute ref { concat('#PL', $n/text())}}
                default return (), 
            
            if (empty($stuff/../no:c_notes))
            then ()
            else (element note { $stuff/../no:c_notes/text() })      
         }       
    }
};

(:PLACES:)
declare 
    %test:pending("fragment")
function biog:pers-add ($resident as node()*) as node()* {
(:~
: biog:pers-add reads the BIOG_ADDR_DATA, and BIOG_ADDR_CODES to generate residence. 
: BIOG_ADDR_CODES//no:c_addr_note would be a good addition to the ODD.
: @param $resident is a ``c_personid``:
: @return ``<residence>...</residence>``:)


for $address in $global:BIOG_ADDR_DATA//no:c_personid[. = $resident][. > 0]

let $code := $global:BIOG_ADDR_CODES//no:c_addr_type[. = $address/../no:c_addr_type]

order by $address/../no:c_sequence

return 
    element residence { 
        for $att in $address/../*[. != '0']
        
        order by local-name($att)        
        return
            typeswitch($att)
                case element (no:c_addr_id) return attribute ref {concat('#PL', $att/text())}
                case element (no:c_addr_type) return attribute key {$att/text()}
                case element (no:c_sequence) return attribute n {$att/text()}
                case element (no:c_firstyear) 
                    return attribute from {string-join((cal:isodate($att/text()),
                        if ($address/../no:c_fy_month[. > 0])
                        then (functx:pad-integer-to-length($address/../no:c_fy_month, 2),
                            if (empty($address/../no:c_fy_day) or $address/../no:c_fy_day = 0)
                            then ()
                            else (functx:pad-integer-to-length($address/../no:c_fy_day, 2)))
                        else ()), '-')}
                case element (no:c_lastyear) 
                    return attribute to {string-join((cal:isodate($att/text()),
                        if ($address/../no:c_ly_month[. > 0])
                        then (functx:pad-integer-to-length($address/../no:c_ly_month, 2),
                           if (empty($address/../no:c_ly_day) or $address/../no:c_ly_day = 0)
                           then ()
                           else (functx:pad-integer-to-length($address/../no:c_ly_day, 2)))
                        else ()), '-')}
                case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
            default return (),
       
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
               $code/../no:c_addr_desc/text()}}),
       
       for $n in $address/../*[. != '0']
       
       order by local-name($n)       
       return
            typeswitch($n)
                case element (no:c_fy_nh_code) 
                    return element date { 
                        attribute calendar {'#chinTrad'},
                        attribute period {concat('#R', $n/text())},
                    if ($address/../no:c_fy_nh_year > 0)
                    then (concat($address/../no:c_fy_nh_year/text(), '年'))
                    else (),
                    
                    if ($address/../no:c_fy_day_gz > 0)
                    then (concat('-', $address/../no:c_fy_day_gz/text(), '日'))
                    else ()}
                case element (no:c_ly_nh_code) 
                    return element date { 
                        attribute calendar {'#chinTrad'},
                        attribute period {concat('#R', $n/text())},
                    if ($address/../no:c_ly_nh_year > 0)
                    then (concat($address/../no:c_ly_nh_year/text(), '年'))
                    else (),
                    
                    if ($address/../no:c_ly_day_gz > 0)
                    then (concat('-', $address/../no:c_ly_day_gz/text(), '日'))
                    else ()}
               case element (no:c_notes) return element note {$n/text()}
            default return ()       
    }
};

declare 
    %test:pending("fragment")
function biog:inst-add ($participant as node()*) as node()* {
(:~
: biog:inst-add reads the BIOG_INST_DATA, and BIOG_INST_CODES generating an event.
: Time and place data are in ``where``, and ``when-custorm`` respectively. 
: The main location of institutions is as in listOrg.xml
:
: Currently there are no dates in this table?
:
: @param $participant is a ``c_personid``
: @see #org
:
: @return ``<event>...</event>``:)

for $address in $global:BIOG_INST_DATA//no:c_personid[. = $participant][. > 0]
let $code := $global:BIOG_INST_CODES//no:c_bi_role_code[. = $address/../no:c_bi_role_code]

let $dy_by := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $address/../no:c_bi_by_nh_code]/../no:c_dy]/../no:c_sort
let $dy_ey := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $address/../no:c_bi_ey_nh_code]/../no:c_dy]/../no:c_sort

let $re_by := count($cal:path/category[@xml:id = concat('R', $address/../no:c_bi_by_nh_code/text())]/preceding-sibling::category) +1
let $re_ey := count($cal:path/category[@xml:id = concat('R', $address/../no:c_bi_ey_nh_code/text())]/preceding-sibling::category) +1

return 
    element event {
        for $att in $address/../*[. != '0']
        order by local-name($att)
        return
            typeswitch($att)
                case element (no:c_inst_code) return attribute where {concat('#ORG', $att/text())}
                case element (no:c_bi_role_code) return attribute key {$att/text()}
                case element (no:c_bi_begin_year) return attribute from {cal:isodate($att)}
                case element (no:c_bi_end_year) return attribute to {cal:isodate($att)}
                case element (no:c_bi_by_nh_code) 
                    return attribute from-custom {
                        if ($address/../no:c_bi_by_nh_year > 0)
                        then (string-join(
                                (concat('D', $dy_by), concat('R',$re_by), concat('Y', $address/../no:c_bi_by_nh_year)),'-')
                              )
                        else (string-join((concat('D', $dy_by), concat('R',$re_by)),'-'))}
                case element (no:c_bi_ey_nh_code) 
                    return attribute to-custom {
                        if ($address/../no:c_bi_ey_nh_year > 0)
                        then (string-join(
                                (concat('D', $dy_by), concat('R',$re_ey), concat('Y', $address/../no:c_bi_ey_nh_year)),'-')
                              )
                        else (string-join((concat('D', $dy_by), concat('R',$re_ey)),'-'))}
                case element (no:c_source) return attribute source {concat('#BIB', $att/text())}
            default return (),
            
            if ((empty($address/../no:c_bi_by_nh_code) or $address/../no:c_bi_by_nh_code = 0)
                and (empty($address/../no:c_bi_ey_nh_code) or $address/../no:c_bi_ey_nh_code = 0))
            then ()
            else (attribute datingMethod {'#chinTrad'}),          
       
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

declare 
    %test:pending("validation as test")
function biog:biog ($persons as node()*, $mode as xs:string?) as item()* {
(:~
: biog:biog reads the main data table of cbdb: BIOG_MAIN. 
: By calling all previous functions in this module, it performs a large join 
: but it doesn't perform the write operation. In addition to the tables from previous functions,
: it also reads HOUSEHOLD_STATUS_CODES, ETHNICITY_TRIBE_CODES, and BIOG_SOURCE_DATA.
:
: biog:biog generates a person element for each unique person in BIOG_MAIN.
:
: @param $persons is a ``c_personid``
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output, aborts on validation errors. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest, does NOT abort upon encountering validation errors.. 
:
: @return ``<person ana="historical">...</person>``:)

let $output := 
    for $person in $persons
    
    let $choro := $global:CHORONYM_CODES//no:c_choronym_code[. = $person/../no:c_choronym_code]
    let $household := $global:HOUSEHOLD_STATUS_CODES//no:c_household_status_code[. = $person/../no:c_household_status_code]
    let $ethnicity := $global:ETHNICITY_TRIBE_CODES//no:c_ethnicity_code[. = $person/../no:c_ethnicity_code]
    
    let $association := $global:ASSOC_DATA//no:c_personid[. = $person]
    let $kin := $global:KIN_DATA//no:c_personid[. = $person]
    let $status := $global:STATUS_DATA//no:c_personid[. = $person]
    let $post := $global:POSTED_TO_OFFICE_DATA//no:c_personid[. = $person]
    let $possession := $global:POSSESSION_DATA//no:c_personid[. = $person]
    
    let $event := $global:EVENTS_DATA//no:c_personid[. = $person]
    let $entry := $global:ENTRY_DATA//no:c_personid[. = $person]
    
    let $source := $global:BIOG_SOURCE_DATA//no:c_personid[. = $person]    
    
    let $bio-add := $global:BIOG_ADDR_DATA//no:c_personid[. = $person]
    let $bio-inst := $global:BIOG_INST_DATA//no:c_personid[. = $person]

    
    let $dy_by := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_by_nh_code]/../no:c_dy]/../no:c_sort
    let $dy_dy := $global:DYNASTIES//no:c_dy[. = $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_dy_nh_code]/../no:c_dy]/../no:c_sort
    
    let $re_by := count($cal:path/category[@xml:id = concat('R', $person/../no:c_by_nh_code/text())]/preceding-sibling::category) +1
    let $re_dy := count($cal:path/category[@xml:id = concat('R', $person/../no:c_dy_nh_code/text())]/preceding-sibling::category) +1
    
    return 
        element person {
            attribute ana {'historical'},               
            attribute xml:id {concat('BIO', $person/text())},
            
            if (empty($source))
            then ()
            else (attribute source{concat('#BIB', $source[1]/../no:c_textid/text())}),
            
            if (empty($person/../no:c_self_bio) or $person/../no:c_self_bio = 0)
            then ()
            else (attribute resp {'selfbio'}),
            
            if (empty($person/../no:tts_sysno) or $person/../no:tts_sysno[. = 0])
            then ()
            else (element idno { attribute type {'TTS'}, 
                $person/../no:tts_sysno/text()}), 
    (: NAMES :)
            element persName {attribute type {'main'},
                for $nom in $person/../*[. != '0']
                order by local-name($nom) descending
                return
                    typeswitch($nom)
                        case element (no:c_name_chn) return biog:name($nom, 'hz')
                        case element (no:c_name) return biog:name($nom, 'py')
                        case element (no:c_name_proper) return biog:name($nom, 'proper')
                        case element (no:c_name_rm) return biog:name($nom, 'rm')
                    default return ()
                    },
    (: ALIAS :)        
            
            biog:alias($person),
            
            if ($person/../no:c_female = 1) 
            then (<sex value="2">f</sex>) 
            else (<sex value ="1">m</sex>),
            
    (: BIRTH :)
            if ((empty($person/../no:c_birthyear) or $person/../no:c_birthyear[. = 0]) 
                and (empty($person/../no:c_by_nh_code) or $person/../no:c_by_nh_code[. = 0]))
            then ()
            else (element birth { 
                    for $birth in $person/../*[. != '0']
                    return
                        typeswitch($birth)
                            case element (no:c_birthyear) 
                                return attribute when {string-join((cal:isodate($birth),
                                    if ($person/../no:c_by_month[. > 0])
                                    then (functx:pad-integer-to-length($person/../no:c_by_month/text(), 2),
                                        if (empty($person/../no:c_by_day) or $person/../no:c_by_day = 0)
                                        then ()
                                        else (functx:pad-integer-to-length($person/../no:c_by_day/text(), 2)))            
                                    else ()), '-')}
                            case element (no:c_by_nh_code) 
                                return (attribute datingMethod {'#chinTrad'}, 
                                    attribute when-custom {
                                    if ($person/../no:c_by_nh_year[.  > 0])
                                    then (string-join(
                                            (concat('D', $dy_by), concat('R',$re_by), concat('Y', $person/../no:c_by_nh_year)),'-'))
                                    else (string-join(
                                            (concat('D', $dy_by), concat('R',$re_by)),'-'))
                                    })                            
                            default return (),
                            
                            if ($person/../no:c_by_nh_code > 0 or $person/../no:c_by_nh_year or $person/../no:c_by_day_gz > 0)
                            then (element date { attribute calendar {'#chinTrad'},
                               attribute period{concat('#R',$person/../no:c_by_nh_code/text())},
                            $dy_by/../no:c_dynasty_chn/text(), $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_by_nh_code]/../no:c_nianhao_chn/text(), 
                            string-join(($person/../no:c_by_nh_year/text(), $person/../no:c_by_day_gz/text()), ':')
                            })
                            else ()
                        }),
    (: DEATH :)
            if ((empty($person/../no:c_deathyear) or $person/../no:c_deathyear[. = 0]) 
                and (empty($person/../no:c_dy_nh_code) or $person/../no:c_dy_nh_code[. = 0]))
            then ()
            else (element death {
                    for $death in $person/../*[. != '0']
                    return
                        typeswitch($death)
                            case element (no:c_deathyear)
                                return attribute when {string-join((cal:isodate($death),
                                    if ($person/../no:c_dy_month[. > 0])
                                    then (functx:pad-integer-to-length($person/../no:c_dy_month/text(), 2),
                                        if (empty($person/../no:c_dy_day) or $person/../no:c_dy_day = 0)
                                        then ()
                                        else (functx:pad-integer-to-length($person/../no:c_dy_day/text(), 2)))            
                                    else ()), '-')}
                            case element (no:c_dy_nh_code) 
                                return (attribute datingMethod {'#chinTrad'},
                                    attribute when-custom {
                                    if ($person/../no:c_dy_nh_year[.  > 0])
                                    then (string-join(
                                            (concat('D', $dy_dy), concat('R',$re_dy), concat('Y', $person/../no:c_dy_nh_year)),'-'))
                                    else (string-join(
                                            (concat('D', $dy_dy), concat('R',$re_dy)),'-'))
                                    })
                            default return (),        

                     if ($person/../no:c_dy_nh_code > 0 or $person/../no:c_dy_nh_year or $person/../no:c_dy_day_gz > 0)
                     then (
                     element date { attribute calendar {'#chinTrad'},
                        attribute period{concat('#R',$person/../no:c_dy_nh_code/text())},
                     $dy_dy/../no:c_dynasty_chn/text(), $global:NIAN_HAO//no:c_nianhao_id[. = $person/../no:c_dy_nh_code]/../no:c_nianhao_chn/text(), 
                     string-join(($person/../no:c_dy_nh_year/text(), $person/../no:c_dy_day_gz/text()), ':')
                     })
                     else ()
                }),
    (: FLORUIT :)
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
                
                for $age in $person/../*[. != '0']
                return 
                    typeswitch($age)
                        case element (no:c_death_age_approx) return element age { attribute cert {'medium'}, $age/text()}
                        case element (no:c_death_age) return element age {$age/text()}
                    default return (),
                
    (: HOUSEHOLD / ETHNICITY / TRIBE :)
                for $ethno in $person/../*[. != '0']
                return 
                    typeswitch ($ethno)
                        case element (no:c_household_status_code) 
                            return element trait { attribute type {'household'},
                                attribute key {$household/../no:c_household_status_code/text()},
                                for $house in $household/../*
                                order by local-name($house) descending
                                return 
                                    typeswitch ($house)
                                        case element (no:c_household_status_desc_chn) return element label { attribute xml:lang {'zh-Hant'}, $house/text()}
                                        case element (no:c_household_status_desc) return element label { attribute xml:lang {'en'}, $house/text()}
                                    default return ()}
                        case element (no:c_ethnicity_code) 
                            return element trait { attribute type {'ethnicity'}, 
                                attribute key {$ethnicity/../no:c_group_code/text()}, 
                                for $n in $ethnicity/../*
                                order by local-name($n) descending
                                return
                                 typeswitch ($n)
                                     case element (no:c_ethno_legal_cat) return element label {$n/text()}
                                     case element (no:c_name_chn) return element desc { attribute xml:lang {'zh-Hant'}, $n/text()}
                                     case element (no:c_name) return element desc { attribute xml:lang {'zh-Latn-alalc97'}, $n/text()}
                                     case element (no:c_romanized) return element desc { attribute xml:lang {'en'}, $n/text()}
                                     case element (no:c_notes) return element note {$n/text()}
                                 default return ()                            
                            }
                       case element (no:c_tribe) return element trait { attribute type {'tribe'}, 
                        element label {$ethno/text()}}
    (: NOTES :)
                       case element (no:c_notes) return element note {$ethno/text()}
                    default return (),                    
    (: AFFILIATION :)
                if (empty($kin) and empty($association))
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
    (: SOCECSTATUS :)
                if (empty($status) and empty($possession)) 
                then ()
                else(<socecStatus>
                        {if ($status) 
                        then (biog:status($person))
                        else (),
                        
             (: POSSESSION :)
                         if ($possession) 
                         then (biog:posses($person))
                         else ()                        
                        }
                     </socecStatus>),
                
                if (empty($post))
                then ()
                else (biog:new-post($person)),
                
    (: EVENTS :)                            
                if (empty($event) and empty($entry))
                then ()
                else (<listEvent>
                        {if ($event)
                        then (biog:event($person))
                        else (),
                        
                        if ($entry)
                        then (biog:entry($person))
                        else (),
                        
                        if (empty($bio-inst))
                        then ()
                        else (biog:inst-add($person))
                        }
                    </listEvent>),
    (: ADDRESS :)
                if (empty($bio-add))
                then ()
                else (biog:pers-add($person)),                 
               
    (: LINKS :)                
                if (empty($person/../no:TTSMQ_db_ID) and empty($person/../no:MQWWLink) and empty($person/../no:KyotoLink))
                then ()
                else (<linkGrp>
                        {let $links := ($person/../no:TTSMQ_db_ID, $person/../no:MQWWLink, $person/../no:KyotoLink)
                         for $n in $links
                         return
                            typeswitch ($n)
                                case element (no:TTSMQ_db_ID) return <ptr target="{concat('ttsmq:', $n/text())}"/>
                                case element (no:MQWWLink) return <ptr target="{concat('mqww:', $n/text())}"/>
                                case element (no:KyotoLink) return <ptr target="{concat('idtf:', $n/text())}"/>
                                default return ()
                         }        
                     </linkGrp>),
                      
               global:create-mod-by($person/../no:c_created_by, $person/../no:c_modified_by)       
        }
return 
    switch($mode)
        case 'v' return global:validate-fragment($output, 'person')
        case 'd' return global:validate-fragment($output, 'person')[1]
    default return $output
};

(:~
: Because of the large number (>370k) of individuals
: the write operation of biographies.xql is slightly more complex. 
: Instead of putting its data into a single file or collection, 
: it creates a single listPerson directory inside the target folder, 
: which is populated by further subdirectories and ultimately the person records. 
:
: Currently, cbdbTEI.xml includes links to 37 listPerson files 
: covering chunks of $chunk-size persons each (10k).  
:
: "chunk" collections contain a single list.xml file and $block-size (50) sub-collections. 
: This file contains xInclude statements to 1 listPerson.xml file per "block" sub-collection.
: Each block contains a single listPerson.xml file on the same level as the individual
: $ppl-per-block (200) person records .

: @param $test set to c_personid that requires further testing
: @param $full all c_personid sgreater then 0 (unkown)
: @param $count how many c_personids there are

: @param $chunk-size determines the sum of person records within the top level directories, 
:    each contains subdirectories and a single list-X.xml file.
: @param $block-size determines the number of subdirectories per chunk.
: @param $ppl-per-block the number of person records per block
:
: @return Files and Folders for person data:
:    *   Directories:
:        *   creates nested directories listPerson, chunk, and block using the respective parameters.
:    *   Files:
:        *   creates list-X.xml and listPerson.xml files that include xInclude statements linking individual person records back to the main tei file. 
:        *   populates the previously generated directories with individual person records by calling biog:biog.    
:        *   Error reports from failed write attempts, as well as validations errors will be stored in the reports directory.:)

declare function biog:write ($item as item()*) as item()* {
let $test := $global:BIOG_MAIN//no:c_personid[. = 927]
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
let $person := biog:biog($individual, 'v') 
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
};

