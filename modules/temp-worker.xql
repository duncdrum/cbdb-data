xquery version "3.1";


(:~
: Temporary working module.
: Replace local with name of target module
:
: @author Duncan Paterson
: @version 0.8.0
:)

import module namespace functx = "http://www.functx.com";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace global = "http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";

(:declare default element namespace "http://www.tei-c.org/ns/1.0";:)


   
declare %private function local:get-src-name ($nodes as document-node()?) as item()* {

let $names := for $node in $nodes//no:row/*
    return
        local-name($node)
return
    distinct-values ($names)
};    

(:create a map of unique table_name:; column_name values to be passed around:)
let $src-files := 
    for $files in collection($config:src-data)
    let $name := util:document-name($files)
    order by $name
return
    ($name) 

for $n in $src-files
let $doc := doc($config:src-data || $n)

return
map {$n := local:get-src-name ($doc)}


