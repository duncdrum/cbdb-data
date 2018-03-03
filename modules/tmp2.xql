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
(:import module namespace global = "http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
:)
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";

(:declare default element namespace "http://www.tei-c.org/ns/1.0";:)

declare variable $path := collection($config:app-root || '/src/');
declare variable $model := $path/model/.;
declare variable $tmpl := doc('/db/apps/cbdb-data/templates/tei/cbdbTEI-template.xml');

let $offices := $config:OFFICE_TYPE_TREE//no:row
let $codes := $config:TEXT_BIBLCAT_CODES//no:row
let $type-rel := $config:TEXT_BIBLCAT_CODE_TYPE_REL//no:row


(: There are three files with problematic IDs :)
let $office-06 := doc($config:target-office || 'office-06.xml')
let $office-15 := doc($config:target-office || 'office-15.xml')
let $office-18 := doc($config:target-office || 'office-18.xml')

(: There  is a bug with the updating extension in 4.0.0 once fixed run this:)

for $n at $p in $office-06//*
let $data := data($n/@xml:id)


order by $data
return
   (: check if there are multilpe IDs :)
   if (count($office-06//*[@xml:id = $data]) = 1)
   (: unique ids are britney, leave em alone :)
   then ()            
   (: see if the dupe is a top level child :)
   else if (data($n/../../tei:category/@xml:id)[1] = 'OFF06')
            then (<delete n="{$p}" at="{data($n/../../tei:category/@xml:id)[1]}">{$n}</delete>)
            else (<keep n="{$p}" at="{data($n/../../tei:category/@xml:id)[2]}">{$office-06//*[@xml:id = $data][2]}</keep>)
    
(:
if (data($n/../../tei:category/@xml:id)[1] = 'OFF06')
then (update delete $n)
else ()

if (data($n/../../tei:category/@xml:id)[1] != 'OFF06')
then ()
else (update replacee $n with <category sameAs="{concat('#', data($n/../../tei:category/@xml:id)[2])}">)
:)
  