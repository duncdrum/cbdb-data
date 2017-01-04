xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $src := '/db/apps/cbdb-data/src/xml/';

declare function local:table_variables($f as node()*) as xs:string {

(:construct a variable declaration for each file in the collection:)
for $f in file:list-files($src)
let $n := file:get-name($f)
order by $n

return
     'declare variable' || ' $' || string($n) || ':= doc(concat($src, ' || "'" ||string($n) || "'));"

};

declare variable $ADDRESSES:= doc(concat($src, 'ADDRESSES.xml')); 
declare variable $ADDR_BELONGS_DATA:= doc(concat($src, 'ADDR_BELONGS_DATA.xml')); 
declare variable $ADDR_CODES:= doc(concat($src, 'ADDR_CODES.xml')); 
declare variable $ADDR_PLACE_DATA:= doc(concat($src, 'ADDR_PLACE_DATA.xml')); 
declare variable $ADDR_XY:= doc(concat($src, 'ADDR_XY.xml')); 
declare variable $ALTNAME_CODES:= doc(concat($src, 'ALTNAME_CODES.xml')); 
declare variable $ALTNAME_DATA:= doc(concat($src, 'ALTNAME_DATA.xml')); 
declare variable $APPOINTMENT_TYPE_CODES:= doc(concat($src, 'APPOINTMENT_TYPE_CODES.xml')); 
declare variable $ASSOC_CODES:= doc(concat($src, 'ASSOC_CODES.xml')); 
declare variable $ASSOC_CODE_TYPE_REL:= doc(concat($src, 'ASSOC_CODE_TYPE_REL.xml')); 
declare variable $ASSOC_DATA:= doc(concat($src, 'ASSOC_DATA.xml')); 
declare variable $ASSOC_TYPES:= doc(concat($src, 'ASSOC_TYPES.xml')); 
declare variable $ASSUME_OFFICE_CODES:= doc(concat($src, 'ASSUME_OFFICE_CODES.xml')); 
declare variable $BIOG_ADDR_CODES:= doc(concat($src, 'BIOG_ADDR_CODES.xml')); 
declare variable $BIOG_ADDR_DATA:= doc(concat($src, 'BIOG_ADDR_DATA.xml')); 
declare variable $BIOG_INST_CODES:= doc(concat($src, 'BIOG_INST_CODES.xml')); 
declare variable $BIOG_INST_DATA:= doc(concat($src, 'BIOG_INST_DATA.xml')); 
declare variable $BIOG_MAIN:= doc(concat($src, 'BIOG_MAIN.xml')); 
declare variable $BIOG_SOURCE_DATA:= doc(concat($src, 'BIOG_SOURCE_DATA.xml')); 
declare variable $CHORONYM_CODES:= doc(concat($src, 'CHORONYM_CODES.xml')); 
declare variable $COUNTRY_CODES:= doc(concat($src, 'COUNTRY_CODES.xml')); 
declare variable $CopyMissingTables:= doc(concat($src, 'CopyMissingTables.xml')); 
declare variable $CopyTables:= doc(concat($src, 'CopyTables.xml')); 
declare variable $DATABASE_LINK_CODES:= doc(concat($src, 'DATABASE_LINK_CODES.xml')); 
declare variable $DATABASE_LINK_DATA:= doc(concat($src, 'DATABASE_LINK_DATA.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 
declare variable $ENTRY_CODES:= doc(concat($src, 'ENTRY_CODES.xml')); 
declare variable $ENTRY_CODE_TYPE_REL:= doc(concat($src, 'ENTRY_CODE_TYPE_REL.xml')); 
declare variable $ENTRY_DATA:= doc(concat($src, 'ENTRY_DATA.xml')); 
declare variable $ENTRY_TYPES:= doc(concat($src, 'ENTRY_TYPES.xml')); 
declare variable $ETHNICITY_TRIBE_CODES:= doc(concat($src, 'ETHNICITY_TRIBE_CODES.xml')); 
declare variable $EVENTS_ADDR:= doc(concat($src, 'EVENTS_ADDR.xml')); 
declare variable $EVENTS_DATA:= doc(concat($src, 'EVENTS_DATA.xml')); 
declare variable $EVENT_CODES:= doc(concat($src, 'EVENT_CODES.xml')); 
declare variable $EXTANT_CODES:= doc(concat($src, 'EXTANT_CODES.xml')); 
declare variable $FIX_AUTHORS:= doc(concat($src, 'FIX_AUTHORS.xml')); 
declare variable $FormLabels:= doc(concat($src, 'FormLabels.xml')); 
declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $HOUSEHOLD_STATUS_CODES:= doc(concat($src, 'HOUSEHOLD_STATUS_CODES.xml')); 
declare variable $KINSHIP_CODES:= doc(concat($src, 'KINSHIP_CODES.xml')); 
declare variable $KIN_DATA:= doc(concat($src, 'KIN_DATA.xml')); 
declare variable $KIN_MOURNING_STEPS:= doc(concat($src, 'KIN_MOURNING_STEPS.xml')); 
declare variable $KIN_Mourning:= doc(concat($src, 'KIN_Mourning.xml')); 
declare variable $LITERARYGENRE_CODES:= doc(concat($src, 'LITERARYGENRE_CODES.xml')); 
declare variable $MEASURE_CODES:= doc(concat($src, 'MEASURE_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $NameAutoCorrectSaveFailures:= doc(concat($src, 'NameAutoCorrectSaveFailures.xml')); 
declare variable $OCCASION_CODES:= doc(concat($src, 'OCCASION_CODES.xml')); 
declare variable $OFFICE_CATEGORIES:= doc(concat($src, 'OFFICE_CATEGORIES.xml')); 
declare variable $OFFICE_CODES:= doc(concat($src, 'OFFICE_CODES.xml')); 
declare variable $OFFICE_CODES_CONVERSION:= doc(concat($src, 'OFFICE_CODES_CONVERSION.xml')); 
declare variable $OFFICE_CODE_TYPE_REL:= doc(concat($src, 'OFFICE_CODE_TYPE_REL.xml')); 
declare variable $OFFICE_TYPE_TREE:= doc(concat($src, 'OFFICE_TYPE_TREE.xml')); 
declare variable $PARENTAL_STATUS_CODES:= doc(concat($src, 'PARENTAL_STATUS_CODES.xml')); 
declare variable $PLACE_CODES:= doc(concat($src, 'PLACE_CODES.xml')); 
declare variable $POSSESSION_ACT_CODES:= doc(concat($src, 'POSSESSION_ACT_CODES.xml')); 
declare variable $POSSESSION_ADDR:= doc(concat($src, 'POSSESSION_ADDR.xml')); 
declare variable $POSSESSION_DATA:= doc(concat($src, 'POSSESSION_DATA.xml')); 
declare variable $POSTED_TO_ADDR_DATA:= doc(concat($src, 'POSTED_TO_ADDR_DATA.xml')); 
declare variable $POSTED_TO_OFFICE_DATA:= doc(concat($src, 'POSTED_TO_OFFICE_DATA.xml')); 
declare variable $POSTING_DATA:= doc(concat($src, 'POSTING_DATA.xml')); 
declare variable $PasteErrors:= doc(concat($src, 'PasteErrors.xml')); 
declare variable $SCHOLARLYTOPIC_CODES:= doc(concat($src, 'SCHOLARLYTOPIC_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_ADDR:= doc(concat($src, 'SOCIAL_INSTITUTION_ADDR.xml')); 
declare variable $SOCIAL_INSTITUTION_ADDR_TYPES:= doc(concat($src, 'SOCIAL_INSTITUTION_ADDR_TYPES.xml')); 
declare variable $SOCIAL_INSTITUTION_ALTNAME_CODES:= doc(concat($src, 'SOCIAL_INSTITUTION_ALTNAME_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_ALTNAME_DATA:= doc(concat($src, 'SOCIAL_INSTITUTION_ALTNAME_DATA.xml')); 
declare variable $SOCIAL_INSTITUTION_CODES:= doc(concat($src, 'SOCIAL_INSTITUTION_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_CODES_CONVERSION:= doc(concat($src, 'SOCIAL_INSTITUTION_CODES_CONVERSION.xml')); 
declare variable $SOCIAL_INSTITUTION_NAME_CODES:= doc(concat($src, 'SOCIAL_INSTITUTION_NAME_CODES.xml')); 
declare variable $SOCIAL_INSTITUTION_TYPES:= doc(concat($src, 'SOCIAL_INSTITUTION_TYPES.xml')); 
declare variable $STATUS_CODES:= doc(concat($src, 'STATUS_CODES.xml')); 
declare variable $STATUS_CODE_TYPE_REL:= doc(concat($src, 'STATUS_CODE_TYPE_REL.xml')); 
declare variable $STATUS_DATA:= doc(concat($src, 'STATUS_DATA.xml')); 
declare variable $STATUS_TYPES:= doc(concat($src, 'STATUS_TYPES.xml')); 
declare variable $TEXT_BIBLCAT_CODES:= doc(concat($src, 'TEXT_BIBLCAT_CODES.xml')); 
declare variable $TEXT_BIBLCAT_CODE_TYPE_REL:= doc(concat($src, 'TEXT_BIBLCAT_CODE_TYPE_REL.xml')); 
declare variable $TEXT_BIBLCAT_TYPES:= doc(concat($src, 'TEXT_BIBLCAT_TYPES.xml')); 
declare variable $TEXT_BIBLCAT_TYPES_1:= doc(concat($src, 'TEXT_BIBLCAT_TYPES_1.xml')); 
declare variable $TEXT_BIBLCAT_TYPES_2:= doc(concat($src, 'TEXT_BIBLCAT_TYPES_2.xml')); 
declare variable $TEXT_CODES:= doc(concat($src, 'TEXT_CODES.xml')); 
declare variable $TEXT_DATA:= doc(concat($src, 'TEXT_DATA.xml')); 
declare variable $TEXT_ROLE_CODES:= doc(concat($src, 'TEXT_ROLE_CODES.xml')); 
declare variable $TEXT_TYPE:= doc(concat($src, 'TEXT_TYPE.xml')); 
declare variable $TablesFields:= doc(concat($src, 'TablesFields.xml')); 
declare variable $TablesFieldsChanges:= doc(concat($src, 'TablesFieldsChanges.xml')); 
declare variable $YEAR_RANGE_CODES:= doc(concat($src, 'YEAR_RANGE_CODES.xml'));


(: Variables for c_personid use all for up to 376041, test for the first 100 persons :)
let $all := 1 to max((($BIOG_MAIN//c_personid)))
let $test := 1 to 100
(:
    Steps to setup cbdb git repo
    1) Complete Source mapping from csv to final tei xpath
    2) Run sanitize to delte all elements where "0" = NULL 
    3) Split large xml into individual rows with key as  @id
    4) Run teiall transform
        4.1 try typeswitch for each table resolving dependencies fixing problems
        4.2 run major transform  as higher order function
        4.3 output fragments not one giant file
        4.4 rejoice and mail HOngsu
    5.1) Design patcher to check for new tables and relations vias diff with existing
    5.2) check for changes values via last change date in tables
:)

declare function local:sanitize ($nodes as node()*) as node()* {

(: ::::: WARNING THIS FUNCTION WILL MODIFY AND PERMANENTLY DELETE DATA FROM IMPORTED SOURCE FILES ::::: :)

(:in CBDB NULL, " ", "0", "unkown" are often used interchangebly.  While '' are exluded on export from sql, 
fn:sanitize removes further elements with unknown values form  "_DATA" tables to reduce overhead.
The linked code tables are left unchanged for future upgradeability.
:)

(:ADDRESSES:)
(:skip:)

(:ADDR_BELONGS_DATA:)
(:skip:)

(:BIOG_MAIN:)
for $n in $BIOG_MAIN//*
return typeswitch ($n) 
    case element(c_dy) return if ($n[.  = 0]) then (update delete $n) else ()
    case element(c_deathyear) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_birthyear) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_self_bio) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_death_age) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_death_age_approx) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_choronym_code) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_fl_earliest_year) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_fl_ey_nh_code) return if ($n[. = 0]) then (update delete $n) else ()
    case element(c_fl_earliest_year) return if ($n[. = 0]) then (update delete $n) else ()
    default return ()

(:ALTNAME_DATA:)
for $b in $ALTNAME_DATA//*
return typeswitch ($b) 
    case element(c_dy) return if ($b[.  = 0]) then (update delete $b) else ()
     case element(c_choronym_code) return if ($b[. = 0]) then (update delete $b) else ()
     case element(c_birthyear) return if ($b[. = 0]) then (update delete $b) else ()
     case element(c_ethnicity_code) return if ($b[. = 0]) then (update delete $b) else ()
     case element(c_household_status_code) return if ($b[. = 0]) then (update delete $b) else ()
     case element(c_source) return if ($b[. = 0]) then (update delete $b) else ()
    default return ($b)
};

declare function local:change-root-namespace($in as element()*, 
    $new-namespace as xs:string, $prefix as xs:string) as element()? {

(:This function adds namespace declarations to the external files that are processes via xinclude:)

for $element in $in
   return
     element {QName($new-namespace,
         concat($prefix,
                if ($prefix = '')
                   then '' else ':',
                local-name($in)))}
           {$in/@*, $in/node()}
};

declare function local:cleanup-unicode ($nodes as xs:string?)  as xs:string*{
(:cbdb aint doing unicode the xml way, hence &amp;#22; -> &#x22;  &#38;
while we're at it we also normalize all strings

this function should run on the ouput files in target after conversion
:)
let $nodes := normalize-space($nodes)
for $n in $nodes
return
if (contains($n, '&amp;#([0-9]*);'))
then (replace($n, '&amp;#([0-9]*);', concat(' &#38;','#x$1')))
else  ($n)       

};