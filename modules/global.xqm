xquery version "3.0";
(:~
: A set of helper functions and variables called by other modules.
: @author Duncan Paterson
: @version 0.7:)

module namespace global="http://exist-db.org/apps/cbdb-data/global";

(:import module namespace functx="http://www.functx.com";:)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare variable $global:src := '/db/apps/cbdb-data/src/xml/';
declare variable $global:target := '/db/apps/cbdb-data/target/';
declare variable $global:report := '/db/apps/cbdb-data/reports/';
declare variable $global:patch := '/db/apps/cbdb-data/reports/patch/';
declare variable $global:samples := '/db/apps/cbdb-data/samples/';
declare variable $global:modules := '/db/apps/cbdb-data/modules/';
declare variable $global:doc := '/db/apps/cbdb-data/doc/';

(:THE TEI FILES IN TARGET:)
declare variable $global:genre := 'biblCat.xml';
declare variable $global:calendar := 'cal_ZH.xml';
declare variable $global:gaiji := 'charDecl.xml';
declare variable $global:bibliography := 'listBibl.xml';
declare variable $global:institution := 'listOrg.xml';
declare variable $global:place := 'listPlace.xml';
declare variable $global:office := 'office.xml';
declare variable $global:office-temp := 'officeA.xml';
declare variable $global:main := 'cbdbTEI.xml';
declare variable $global:person := 'listPerson';

(:THE ORIGINAL TABLES IN SOURCE:)

(:~
: To generate this list see the local:table-variables function inside the suppl module.:)
declare variable $global:ADDRESSES:= doc(concat($global:src, 'ADDRESSES.xml')); 
declare variable $global:ADDR_BELONGS_DATA:= doc(concat($global:src, 'ADDR_BELONGS_DATA.xml')); 
declare variable $global:ADDR_CODES:= doc(concat($global:src, 'ADDR_CODES.xml')); 
declare variable $global:ADDR_PLACE_DATA:= doc(concat($global:src, 'ADDR_PLACE_DATA.xml')); 
declare variable $global:ADDR_XY:= doc(concat($global:src, 'ADDR_XY.xml')); 
declare variable $global:ALTNAME_CODES:= doc(concat($global:src, 'ALTNAME_CODES.xml')); 
declare variable $global:ALTNAME_DATA:= doc(concat($global:src, 'ALTNAME_DATA.xml')); 
declare variable $global:APPOINTMENT_TYPE_CODES:= doc(concat($global:src, 'APPOINTMENT_TYPE_CODES.xml')); 
declare variable $global:ASSOC_CODES:= doc(concat($global:src, 'ASSOC_CODES.xml')); 
declare variable $global:ASSOC_CODE_TYPE_REL:= doc(concat($global:src, 'ASSOC_CODE_TYPE_REL.xml')); 
declare variable $global:ASSOC_DATA:= doc(concat($global:src, 'ASSOC_DATA.xml')); 
declare variable $global:ASSOC_TYPES:= doc(concat($global:src, 'ASSOC_TYPES.xml')); 
declare variable $global:ASSUME_OFFICE_CODES:= doc(concat($global:src, 'ASSUME_OFFICE_CODES.xml')); 
declare variable $global:BIOG_ADDR_CODES:= doc(concat($global:src, 'BIOG_ADDR_CODES.xml')); 
declare variable $global:BIOG_ADDR_DATA:= doc(concat($global:src, 'BIOG_ADDR_DATA.xml')); 
declare variable $global:BIOG_INST_CODES:= doc(concat($global:src, 'BIOG_INST_CODES.xml')); 
declare variable $global:BIOG_INST_DATA:= doc(concat($global:src, 'BIOG_INST_DATA.xml')); 
declare variable $global:BIOG_MAIN:= doc(concat($global:src, 'BIOG_MAIN.xml')); 
declare variable $global:BIOG_SOURCE_DATA:= doc(concat($global:src, 'BIOG_SOURCE_DATA.xml')); 
declare variable $global:CHORONYM_CODES:= doc(concat($global:src, 'CHORONYM_CODES.xml')); 
declare variable $global:COUNTRY_CODES:= doc(concat($global:src, 'COUNTRY_CODES.xml')); 
declare variable $global:CopyMissingTables:= doc(concat($global:src, 'CopyMissingTables.xml')); 
declare variable $global:CopyTables:= doc(concat($global:src, 'CopyTables.xml')); 
declare variable $global:DATABASE_LINK_CODES:= doc(concat($global:src, 'DATABASE_LINK_CODES.xml')); 
declare variable $global:DATABASE_LINK_DATA:= doc(concat($global:src, 'DATABASE_LINK_DATA.xml')); 
declare variable $global:DYNASTIES:= doc(concat($global:src, 'DYNASTIES.xml')); 
declare variable $global:ENTRY_CODES:= doc(concat($global:src, 'ENTRY_CODES.xml')); 
declare variable $global:ENTRY_CODE_TYPE_REL:= doc(concat($global:src, 'ENTRY_CODE_TYPE_REL.xml')); 
declare variable $global:ENTRY_DATA:= doc(concat($global:src, 'ENTRY_DATA.xml')); 
declare variable $global:ENTRY_TYPES:= doc(concat($global:src, 'ENTRY_TYPES.xml')); 
declare variable $global:ETHNICITY_TRIBE_CODES:= doc(concat($global:src, 'ETHNICITY_TRIBE_CODES.xml')); 
declare variable $global:EVENTS_ADDR:= doc(concat($global:src, 'EVENTS_ADDR.xml')); 
declare variable $global:EVENTS_DATA:= doc(concat($global:src, 'EVENTS_DATA.xml')); 
declare variable $global:EVENT_CODES:= doc(concat($global:src, 'EVENT_CODES.xml')); 
declare variable $global:EXTANT_CODES:= doc(concat($global:src, 'EXTANT_CODES.xml')); 
declare variable $global:FIX_AUTHORS:= doc(concat($global:src, 'FIX_AUTHORS.xml')); 
declare variable $global:FormLabels:= doc(concat($global:src, 'FormLabels.xml')); 
declare variable $global:GANZHI_CODES:= doc(concat($global:src, 'GANZHI_CODES.xml')); 
declare variable $global:HOUSEHOLD_STATUS_CODES:= doc(concat($global:src, 'HOUSEHOLD_STATUS_CODES.xml')); 
declare variable $global:KINSHIP_CODES:= doc(concat($global:src, 'KINSHIP_CODES.xml')); 
declare variable $global:KIN_DATA:= doc(concat($global:src, 'KIN_DATA.xml')); 
declare variable $global:KIN_MOURNING_STEPS:= doc(concat($global:src, 'KIN_MOURNING_STEPS.xml')); 
declare variable $global:KIN_Mourning:= doc(concat($global:src, 'KIN_Mourning.xml')); 
declare variable $global:LITERARYGENRE_CODES:= doc(concat($global:src, 'LITERARYGENRE_CODES.xml')); 
declare variable $global:MEASURE_CODES:= doc(concat($global:src, 'MEASURE_CODES.xml')); 
declare variable $global:NIAN_HAO:= doc(concat($global:src, 'NIAN_HAO.xml')); 
declare variable $global:NameAutoCorrectSaveFailures:= doc(concat($global:src, 'NameAutoCorrectSaveFailures.xml')); 
declare variable $global:OCCASION_CODES:= doc(concat($global:src, 'OCCASION_CODES.xml')); 
declare variable $global:OFFICE_CATEGORIES:= doc(concat($global:src, 'OFFICE_CATEGORIES.xml')); 
declare variable $global:OFFICE_CODES:= doc(concat($global:src, 'OFFICE_CODES.xml')); 
declare variable $global:OFFICE_CODES_CONVERSION:= doc(concat($global:src, 'OFFICE_CODES_CONVERSION.xml')); 
declare variable $global:OFFICE_CODE_TYPE_REL:= doc(concat($global:src, 'OFFICE_CODE_TYPE_REL.xml')); 
declare variable $global:OFFICE_TYPE_TREE:= doc(concat($global:src, 'OFFICE_TYPE_TREE.xml')); 
declare variable $global:PARENTAL_STATUS_CODES:= doc(concat($global:src, 'PARENTAL_STATUS_CODES.xml')); 
declare variable $global:PLACE_CODES:= doc(concat($global:src, 'PLACE_CODES.xml')); 
declare variable $global:POSSESSION_ACT_CODES:= doc(concat($global:src, 'POSSESSION_ACT_CODES.xml')); 
declare variable $global:POSSESSION_ADDR:= doc(concat($global:src, 'POSSESSION_ADDR.xml')); 
declare variable $global:POSSESSION_DATA:= doc(concat($global:src, 'POSSESSION_DATA.xml')); 
declare variable $global:POSTED_TO_ADDR_DATA:= doc(concat($global:src, 'POSTED_TO_ADDR_DATA.xml')); 
declare variable $global:POSTED_TO_OFFICE_DATA:= doc(concat($global:src, 'POSTED_TO_OFFICE_DATA.xml')); 
declare variable $global:POSTING_DATA:= doc(concat($global:src, 'POSTING_DATA.xml')); 
declare variable $global:PasteErrors:= doc(concat($global:src, 'PasteErrors.xml')); 
declare variable $global:SCHOLARLYTOPIC_CODES:= doc(concat($global:src, 'SCHOLARLYTOPIC_CODES.xml')); 
declare variable $global:SOCIAL_INSTITUTION_ADDR:= doc(concat($global:src, 'SOCIAL_INSTITUTION_ADDR.xml')); 
declare variable $global:SOCIAL_INSTITUTION_ADDR_TYPES:= doc(concat($global:src, 'SOCIAL_INSTITUTION_ADDR_TYPES.xml')); 
declare variable $global:SOCIAL_INSTITUTION_ALTNAME_CODES:= doc(concat($global:src, 'SOCIAL_INSTITUTION_ALTNAME_CODES.xml')); 
declare variable $global:SOCIAL_INSTITUTION_ALTNAME_DATA:= doc(concat($global:src, 'SOCIAL_INSTITUTION_ALTNAME_DATA.xml')); 
declare variable $global:SOCIAL_INSTITUTION_CODES:= doc(concat($global:src, 'SOCIAL_INSTITUTION_CODES.xml')); 
declare variable $global:SOCIAL_INSTITUTION_CODES_CONVERSION:= doc(concat($global:src, 'SOCIAL_INSTITUTION_CODES_CONVERSION.xml')); 
declare variable $global:SOCIAL_INSTITUTION_NAME_CODES:= doc(concat($global:src, 'SOCIAL_INSTITUTION_NAME_CODES.xml')); 
declare variable $global:SOCIAL_INSTITUTION_TYPES:= doc(concat($global:src, 'SOCIAL_INSTITUTION_TYPES.xml')); 
declare variable $global:STATUS_CODES:= doc(concat($global:src, 'STATUS_CODES.xml')); 
declare variable $global:STATUS_CODE_TYPE_REL:= doc(concat($global:src, 'STATUS_CODE_TYPE_REL.xml')); 
declare variable $global:STATUS_DATA:= doc(concat($global:src, 'STATUS_DATA.xml')); 
declare variable $global:STATUS_TYPES:= doc(concat($global:src, 'STATUS_TYPES.xml')); 
declare variable $global:TEXT_BIBLCAT_CODES:= doc(concat($global:src, 'TEXT_BIBLCAT_CODES.xml')); 
declare variable $global:TEXT_BIBLCAT_CODE_TYPE_REL:= doc(concat($global:src, 'TEXT_BIBLCAT_CODE_TYPE_REL.xml')); 
declare variable $global:TEXT_BIBLCAT_TYPES:= doc(concat($global:src, 'TEXT_BIBLCAT_TYPES.xml')); 
declare variable $global:TEXT_BIBLCAT_TYPES_1:= doc(concat($global:src, 'TEXT_BIBLCAT_TYPES_1.xml')); 
declare variable $global:TEXT_BIBLCAT_TYPES_2:= doc(concat($global:src, 'TEXT_BIBLCAT_TYPES_2.xml')); 
declare variable $global:TEXT_CODES:= doc(concat($global:src, 'TEXT_CODES.xml')); 
declare variable $global:TEXT_DATA:= doc(concat($global:src, 'TEXT_DATA.xml')); 
declare variable $global:TEXT_ROLE_CODES:= doc(concat($global:src, 'TEXT_ROLE_CODES.xml')); 
declare variable $global:TEXT_TYPE:= doc(concat($global:src, 'TEXT_TYPE.xml')); 
declare variable $global:TablesFields:= doc(concat($global:src, 'TablesFields.xml')); 
declare variable $global:TablesFieldsChanges:= doc(concat($global:src, 'TablesFieldsChanges.xml')); 
declare variable $global:YEAR_RANGE_CODES:= doc(concat($global:src, 'YEAR_RANGE_CODES.xml'));


declare 
    %test:pending("fragment")
function global:create-mod-by ($created as node()*, $modified as node()*) as node()*{
(:~ 
: This function takes the standardized entries for creation and modification of cbdb entries 
: and translates them into note elements.
:
: This data is distinct from the modifications of the TEI output recorded in the header.
: 
: @param $created is ``c_created_by``
: @param $modified is ``c_modified_by``
: 
: @return ``<note type="created | modified">...</note>``:)

for $creator in $created
return
    if (empty($creator)) 
    then ()
    else (<note type="created" target="{concat('#',$creator/text())}">
                <date when="{cal:sqldate($creator/../no:c_created_date)}"/>
           </note>),
              
for $modder in $modified
return
    if (empty($modder)) 
    then ()
    else (<note type="modified" target="{concat('#',$modder/text())}">
                <date when="{cal:sqldate($modder/../no:c_modified_date)}"/>
          </note>)   
        
};

declare function global:validate-fragment ($frag as node()*, $loc as xs:string?) as item()* {

(:~
: This function validates $frag by inserting it into a minimal TEI template. 
:
: This function cannot guarantee that the final document is valid, 
: but it can catch validation errors produced by other function early on.
: This minimizes the number of validations necessary to produce the final output. 
:
: @param $frag the fragment (usually some function's output) to be validated.
: @param $loc accepts the following element names as root to be used for validation: 
:    *   category
:    *   charDecl
:    *   person
:    *   org
:    *   bibl
:    *   place
:
: @return if validation succeeds then return the input, otherwise store a copy of the validation report 
: into the reports directory, including the ``xml:id`` of the root element of the processed fragment.:)

let $id := data($frag/@xml:id)
let $mini := 
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
      <fileDesc>
         <titleStmt>
            <title>cbdbTEI-mini</title>
         </titleStmt>
         <publicationStmt>
            <p>testing ouput of individual functions using this mini tei document.</p>
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