xquery version "3.1";

(:~
: The odd module creates a a custom odd based on the exported CBDB source files
: 
: @author Duncan Paterson
: @version 0.8.0
:)

(:module namespace odd="http://exist-db.org/apps/cbdb-data/odd";:)

import module namespace functx="http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config="http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";
declare namespace odd="http://exist-db.org/apps/cbdb-data/odd";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $odd:ADDRESSES := doc($config:src-data || 'ADDRESSES.xml');

declare 
    %private
    function odd:test($max as xs:integer?) as xs:integer* {

for $n in 1 to $max
return 
    $n
};
(:~
 : TODO: make closed lists for all (sub-)type attributes 
 : settle on a date format for chinese dates
 :)

declare 
    %public
    function odd:table-variables($path as xs:string?) as xs:string* {

(:construct a variable declaration for each file in the collection:)
for $files in collection($path)
let $name := util:document-name($files)
let $var := substring-before($name, ".")
order by $name

return
     'declare variable' || ' $config:' || $var || ' := doc($config:src-data' || " || '" || $name || "');"
};

odd:table-variables($config:src-data)

