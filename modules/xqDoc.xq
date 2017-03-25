xquery version "3.1";
import module namespace app="http://exist-db.org/apps/cbdb-data/templates" at "app.xql";

declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:declare variable $xqdoc_config := map {
    "module": function($content) {<module uri="{$uri}" prefix="{$prefix}" location="{$location}">{$content}</module>} 
};:)

let $doc := app:make-func-doc(xs:anyURI("/db/apps/cbdb-data/modules/calendar.xql"))
for $n in $doc//*
return
    switch(local-name($n))
        case "module" return concat('## Module Uri', '&#xa;','[', data($doc/@uri), '](', data($doc/@location), ')')
        case "variable" return concat('$', data($n/@name))
        case "function" return concat('```xml', '&#xa;', 'declare function ', data($n/@name),  '&#xa;', '```', '&#xa;')
        case "argument" return concat('#### Parameters:', '&#xa;', '*   ','$', data($n/@var), ' - ', $n/text(), '&#xa;')
        case "returns" return concat('#### Returns:', '&#xa;', '*   ', $n/string(), '&#xa;') 
        case "description" return concat('### Function Detail:', '&#xa;', '*   ', $n/string(), '&#xa;') 
        case "calls" return concat('#### External Functions that are used by this Function', '&#xa;', '*   ', $n/text(),'&#xa;') 
        case "annotation" return () 
        case "value" return () 
        case "xml" return () 
        case "version" return concat('## Version:', $n/text(), '&#xa;') 
        case "author" return concat('## Author:', $n/text(), '&#xa;') 
        case "control" return () 
        case "signature" return $n/text() 
        case "deprecated" return concat('## Depreceated:', $n/text(), '&#xa;') 
        case "see" return concat('[see](', $n/text(), ')&#xa;') 
    default return concat('## Module Uri', '&#xa;','[', data($doc/@uri), '](', data($doc/@location), ')')
    
    
(:app:make-func-doc(xs:anyURI("/db/apps/cbdb-data/modules/calendar.xql")):)
