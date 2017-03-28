xquery version "3.1";
import module namespace app="http://exist-db.org/apps/cbdb-data/templates" at "app.xql";
import module namespace docs="http://exist-db.org/xquery/docs" at "/db/apps/fundocs/modules/scan.xql";

declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:declare variable $xqdoc_config := map {
    "module": function($content) {<module uri="{$uri}" prefix="{$prefix}" location="{$location}">{$content}</module>} 
};:)

declare function local:switch-report ($nodes as node()*) as item()* {
for $n in $nodes
return
    switch(local-name($n))
       (: case "module" return concat('## Module Uri', '&#xa;','[', data($doc/@uri), '](', data($doc/@location), ')', '&#xa;'):)
        case "variable" return concat('*   *$', data($n/@name), '* - *missing description*')
        case "xxx" return concat('*   ', $n, '&#xa;')
        case "function" return concat('```xQuery', '&#xa;', 'declare function ', data($n/@name),  
             "(" || string-join(
             for $param in $n/argument
             return
                 "$" || $param/@var/string()  || " as " || $param/@type/string() || docs:cardinality($param/@cardinality),
             ", ") || ")" || " as " || $n/returns/@type/string() || docs:cardinality($n/returns/@cardinality) || '&#xa;', '```', '&#xa;')
        case "argument" return concat('*   ','$', data($n/@var), ' - ', $n/text(), '&#xa;')
        case "returns" return concat('*   ', normalize-space($n/string()), '&#xa;') 
        case "description" return concat(normalize-space($n/string()), '&#xa;') 
        case "calls" return for $c in $n/function
            return
                concat('<',data($c/@module), '>','|[', data($c/@name),'](#',data($c/@name), ')') 
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
    default return ()
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
    
(: Variables :)
    if ($doc/variable)
    then (concat('## Variables:','&#xa;'))
    else (),
    
(: the table for variable calls is currently empty see    :)
    for $v in $doc/variable
        return
            (local:switch-report($v),
            
            if ($v/calls)
            then (concat('### Internal Functions that reference this Variable', '&#xa;', 
                        '*Module URI*|*Function Name*',  '&#xa;', ':----|:----'), 
                    local:switch-report($v/calls))
            else()),
            
(:  Functions :)
    if ($doc/function)
    then (concat('&#xa;','## Function Summary', '&#xa;'))
    else (),
    
    for $f in $doc/function
    return
    (concat('### ', data($f/@name)),
    
    local:switch-report($f),
    
    if ($f/description)
    then (concat('### Function Detail:', '&#xa;'), 
            local:switch-report($f/description))
    else (),
    
    if ($f/argument)
    then (concat('#### Parameters:', '&#xa;'),
            local:switch-report($f/argument))
    else (),
    
    if ($f/returns)
    then (concat('#### Returns:', '&#xa;'),
            local:switch-report($f/returns))
    else(),
            
    if ($f/calls)
    then (concat('#### External Functions that are used by this Function', '&#xa;', 
                '*Module URI*|*Function Name*',  '&#xa;', ':----|:----'), 
            local:switch-report($f/calls))
    else())
)

(:    $sample:)
(:$doc:)


