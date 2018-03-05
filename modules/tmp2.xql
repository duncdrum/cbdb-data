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
let $codes := $config:OFFICE_CODES//no:row
let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row

let $office-06 := doc($config:target-office || 'office-06.xml')
let $office-15 := doc($config:target-office || 'office-15.xml')
let $office-18 := doc($config:target-office || 'office-18.xml')

return
    <report>
        <links>
            <code-no-type>{count(distinct-values($codes/no:c_office_id)) - count(distinct-values($type-rel/no:c_office_id))}</code-no-type>
            <type-no-code>{count(distinct-values($offices/no:c_office_type_node_id)) - count(distinct-values($type-rel/no:c_office_tree_id))}</type-no-code>
        </links>
    </report>