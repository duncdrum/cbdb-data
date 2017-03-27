xquery version "3.1";
import module namespace app="http://exist-db.org/apps/cbdb-data/templates" at "app.xql";

declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:declare variable $xqdoc_config := map {
    "module": function($content) {<module uri="{$uri}" prefix="{$prefix}" location="{$location}">{$content}</module>} 
};:)

declare function local:switch-report ($nodes as node()*) as item()* {
for $n in $nodes
return
    switch(local-name($n))
       (: case "module" return concat('## Module Uri', '&#xa;','[', data($doc/@uri), '](', data($doc/@location), ')', '&#xa;'):)
        case "variable" return concat('*$', data($n/@name), '* | ')
        case "xxx" return concat('*   ', $n, '&#xa;')
        case "function" return concat('```xml', '&#xa;', 'declare function ', data($n/@name),  '&#xa;', '```', '&#xa;')
        case "argument" return concat('#### Parameters:', '&#xa;', '*   ','$', data($n/@var), ' - ', $n/text(), '&#xa;')
        case "returns" return concat('#### Returns:', '&#xa;', '*   ', $n/string(), '&#xa;') 
        case "description" return concat('### Function Detail:', '&#xa;', '*   ', $n/string(), '&#xa;') 
        case "calls" return concat('#### External Functions that are used by this Function', '&#xa;', '*   ', $n/text(),'&#xa;') 
        case "annotation" return () 
        case "value" return () 
        case "xml" return () 
        case "version" return concat('*   Version:', $n/text(), '&#xa;') 
        case "author" return concat('*   Author:', $n/text(), '&#xa;') 
        case "since" return concat('*   Since:', $n/text(), '&#xa;') 
        case "control" return () 
        case "signature" return $n/text() 
        case "deprecated" return concat('*   Depreceated:', $n/text(), '&#xa;') 
        case "see" return concat('[see](', $n/text(), ')&#xa;') 
    default return (local:switch-report($n))
};    

(:let $sample := inspect:inspect-module-uri(xs:anyURI("/db/apps/cbdb-data/doc/xqdoc-display.xqy")):)
let $doc := app:make-func-doc(xs:anyURI("/db/apps/cbdb-data/modules/calendar.xql"))
(:/db/apps/cbdb-data/modules/calendar.xql:)
return 
(:H1 Heading:)
    (concat('# Function Documentation', '&#xa;'),
    
(:TOC goes here:)
    
    concat('## Module URI&#xa;','[', data($doc/@uri), '](', data($doc/@location), ')', '&#xa;'),
    
    (: !! These are not captured by inspect needs PR !! :)
    if ($doc/description) 
    then (concat('## Module Description', '&#xa;'), 
            local:switch-report($doc/description),
            local:switch-report($doc/author), 
            local:switch-report($doc/version), 
            local:switch-report($doc/since), 
            local:switch-report($doc/depreceated),
            local:switch-report($doc/see))
    else (),
    
(: Module Variables (as table) misses variable descriptions:)
    if ($doc/variable)
    then (concat('## Variables:&#xa;',':----|:----'),
            local:switch-report($doc/variable)
    (: Missing from spec :)
            , 
            concat('### Internal Functions that reference this Variable', '&#xa;',
                '*Module URI* | *Function Name*', '&#xa;', ':----|:----'), 
                local:switch-report($doc/xxx)
                )
    else (), 
    
(:  Functions :)
    if ($doc/function)
    then (concat('## Function Summary', '&#xa;')
            local:switch-report($doc/function),
            
    
    
    )
(:    $sample:)


