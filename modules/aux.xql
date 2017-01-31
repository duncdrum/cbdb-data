xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:Aux.xql contains helper functions mostly for cleaning data and constructing functions.:)


declare function local:table-variables($f as node()*) as xs:string {

(:construct a variable declaration for each file in the collection:)
for $f in collection($global:src)
let $n := substring-after(base-uri($f), $global:src)
order by $n

return
     'declare variable' || ' $' || string($n) || ' := doc(concat($src, ' || "'" ||string($n) || "'));"
};

declare function local:write-chunk-includes($num as xs:integer?) as item()*{
(:This function inserts xinclude statemtns into the main TEI file for each chunk's list.xml file. 
As such $ipad, $num, and the return string depend on the main write operation in biographies.xql.
:)

for $i in 1 to $num
let $ipad := functx:pad-integer-to-length($i, 2)

return
    update insert
        <xi:include href="{concat('listPerson/chunk-', $ipad, '/list-', $i, '.xml')}" parse="xml"/>
    into doc(concat($global:target, $global:main))//body
};
(:local:write-chunk-includes(37):)

declare function local:upgrade-contents($nodes as node()*) as node()* {

(: !!! WARNING !!! Handle with monumental care !!!!

This function performs an inplace update off all person records. 
It expects $global:BIOG_MAIN//no:c_personid s. 
It is handy for patching large number of records. 
Using the structural index in the return clause is crucial for performance.
:)

for $n in $nodes
return
 update value collection(concat($global:target, 'listPerson/'))//person[id(concat('BIO', $n))] 
 with biog:biog($n)/*

(:update value doc('/db/apps/cbdb-data/samples/test.xml')//listPlace with biog:biog($n)/*:)

};
(:local:upgrade-contents($global:BIOG_MAIN//no:c_personid[. > 0][. < 2]):)


declare function local:validate-fragment($frag as node()*, $loc as xs:string?) as item()* {

(: This function validates $frag by inserting it into a minimal TEI template. 

This function cannot guarante that the final document is valid, 
but it can catch validation errors produced by other function early on.
This minimizes the number of validations necessary to produce the final output. 

Currently, $loc accepts the name of the root element rturned by the function producing the $frag.
For $loc use:
- category
- charDecl
- person
- org
- bibl
- place

For $frag use:
- biog:biog($global:BIOG_MAIN//no:c_personid[. = 12908])
- bib:bibliography($global:TEXT_CODES//no:c_textid[. = 2031])

:)

let $id := data($frag/@xml:id)
let $mini := 
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
      <fileDesc>
         <titleStmt>
            <title>cbdbTEI-mini</title>
         </titleStmt>
         <publicationStmt>
            <p>testing ouput of individual functions using this mini tei document </p>
         </publicationStmt>
         <sourceDesc>
            <p>cannot replace proper validation of final output</p>
         </sourceDesc>
      </fileDesc>
      <encodingDesc>
         <classDecl>
            {if ($loc = 'category')
             then (<taxonomy>{$frag}</taxonomy>)
             else (<taxonomy><category><catDesc>some category</catDesc></category></taxonomy>)}
         </classDecl>
            {if ($loc = 'charDecl')
            then ($frag)
            else (<charDecl><glyph><mapping>⿸虍⿻夂丷⿱目</mapping></glyph></charDecl>)}        
      </encodingDesc>
  </teiHeader>
  <text>
      <body>       
         {
         switch ($loc)
         case 'person' return <listPerson ana="chunk"><listPerson ana="block">{$frag}</listPerson></listPerson>
         case 'org' return <listOrg>{$frag}</listOrg>
         case 'place' return <listPlace>{$frag}</listPlace>
         case 'bibl' return <listBibl>{$frag}</listBibl>
         default return (<p>some text here {data($frag)}</p>)
         }         
      </body>
  </text>
</TEI>

return 
    if (validation:jing($mini, doc('../templates/tei/tei_all.rng')) = true())
    then ($frag)
    else (($frag, 
          xmldb:store($global:report,  concat('report-',$id,'.xml'),
          validation:jing-report($mini, doc('../templates/tei/tei_all.rng')))))
};

(:local:validate-fragment(bib:bibliography($global:TEXT_CODES//no:c_textid[. = 2031]), 'bibl'):)   
(:let $id := 12908
let $test := $global:BIOG_MAIN//no:c_personid[. > 12906][. < 12910]

for $n in $test
return

xmldb:store($global:samples, concat('cbdb-', data($n), '.xml'),
local:validate-fragment(biog:biog($global:BIOG_MAIN//no:c_personid[. = $n]), 'person')[1]):)

declare function local:asso ($ego as node()*) as node()* {
    
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
[tts_sysno] INTEGER,                                d
 [c_assoc_code] INTEGER,                            x
 [c_personid] INTEGER,                              x
 [c_kin_code] INTEGER,                              d
 [c_kin_id] INTEGER,                                d
 [c_assoc_id] INTEGER,                              x
 [c_assoc_kin_code] INTEGER,                      d 
 [c_assoc_kin_id] INTEGER,                        d  
 [c_tertiary_personid] INTEGER,                  x 
 [c_assoc_count] INTEGER,                         d  
 [c_sequence] INTEGER,                             x 
 [c_assoc_year] INTEGER,                           x 
 [c_source] INTEGER,                                x
 [c_pages] CHAR(255),                               d
 [c_notes] CHAR,                                     x
 [c_assoc_nh_code] INTEGER,                         
 [c_assoc_nh_year] INTEGER,                        
 [c_assoc_range] INTEGER,                          !!!
 [c_addr_id] INTEGER,                               x
 [c_litgenre_code] INTEGER,                        x
 [c_occasion_code] INTEGER,                        x
 [c_topic_code] INTEGER,                           x                    
 [c_inst_code] INTEGER,                             x
 [c_inst_name_code] INTEGER,                       d 
 [c_text_title] CHAR(255),                          
 [c_assoc_claimer_id] INTEGER,                      
 [c_assoc_intercalary] BOOLEAN NOT NULL,         
 [c_assoc_month] INTEGER,                           
 [c_assoc_day] INTEGER,                             
 [c_assoc_day_gz] INTEGER,                          
 [c_created_by] CHAR(255),                          d
 [c_created_date] CHAR(255),                        d
 [c_modified_by] CHAR(255),                         d
 [c_modified_date] CHAR(255))                       d
:)

(:TO DO 
- change state/@ref to point to both #org and #pl in one attribute
- add information from occasion, topic, and litgenre tables to state
- wrap state in conbditional to avoid <state/>
- consider chal-ZH dates for state
- c assoc claimer could get a @role somewhere around state

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
                     
                     element state {
                (:   change ref to point to both #pl and #org  separated by whitespace              :)
                     if (empty($individual/../no:c_addr_id) or $individual/../no:c_addr_id =  0)
                     then (attribute ref {concat('#ORG', $individual/../no:c_inst_code)})
                     else (attribute ref {concat('#PL', $individual/../no:c_addr_id)}),    
                     
                     if ($individual/../no:c_occasion_code > 0)
                     then (attribute ana {$individual/../no:c_occasion_code/text()})
                     else (),
                     
                     if ($individual/../no:c_topic_code > 0)
                     then (attribute type {$individual/../no:c_topic_code/text()})
                     else (),
                     
                     if ($individual/../no:c_litgenre_code > 0)
                     then (attribute subtype {$individual/../no:c_litgenre_code/text()})
                     else (),
                     
                     if (empty($individual/../no:c_assoc_year))
                     then ()
                     else (attribute when {cal:isodate($individual/../no:c_assoc_year)})
                     },
                     
                     if ($individual/../no:c_tertiary_personid > 0)
                     then (element desc {
                        element persName { attribute ref {concat('#BIO', $individual/../no:c_tertiary_personid/text())} }
                     })
                     else ()
                 })
             )
        }

};

let $test := $global:BIOG_MAIN//no:c_personid[. > 0][. = 1]
return 
(:biog:biog($test):)

local:asso($test)