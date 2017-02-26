xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';




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
    default return (),

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

(: Variables for c_personid use all for up to 376041, test for the first 100 persons :)
let $all := 1 to max((($BIOG_MAIN//no:c_personid)))
let $test := 1 to 100

return 
    $test