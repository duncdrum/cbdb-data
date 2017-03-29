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
        case "variable" return '*   *$' || data($n/@name) || '* - *missing description*'
        case "xxx" return '*   ' || $n || '&#xa;'
        case "function" return '```xQuery' || '&#xa;' || 'declare function ' || data($n/@name) || 
            "(" || string-join(
                 for $param in $n/argument
                 return
                     "$" || $param/@var/string()  || " as " || $param/@type/string() || docs:cardinality($param/@cardinality),
                 ", ") || 
             ")" || " as " || $n/returns/@type/string() || docs:cardinality($n/returns/@cardinality) || '&#xa;' || '```'
        case "argument" return '*   ' || '$' ||  data($n/@var) || ' - ' || $n/text()
        case "returns" return '*   ' || normalize-space($n/string())
        case "description" return normalize-space($n/string())
        case "calls" return 
            for $c in $n/function
            return
                '<' || data($c/@module) || '>' || '|[' || data($c/@name) || '](#' || data($c/@name) || ')'
        case "annotation" return ()
        case "value" return () 
        case "xml" return ()
        case "version" return '*   Version:' || normalize-space($n/text())
        case "author" return '*   Author:' || normalize-space($n/text())
        case "since" return '*   Since:' || normalize-space($n/text())
        case "control" return ()
        case "signature" return $n/text()
        case "deprecated" return '*   Depreceated:' || normalize-space($n/text())
        case "see" return '[see](' || normalize-space($n/text()) || ')&#xa;'
    default return ()
};


let $doc := app:make-func-doc(xs:anyURI("/db/apps/cbdb-data/modules/calendar.xql"))

return
(:H1 Heading:)
    ('# Function Documentation' || '&#xa;',

(:TOC goes here:)

    '## Module URI&#xa;' || '[' || data($doc/@uri) || '](' || data($doc/@location) || ')&#xa;',

    (: !! These are not captured by inspect needs PR !! :)
    if ($doc/description)
    then ('&#xa;' || '## Module Description',
            local:switch-report($doc/description),
            local:switch-report($doc/author),
            local:switch-report($doc/version),
            local:switch-report($doc/since),
            local:switch-report($doc/depreceated),
            local:switch-report($doc/see))
    else (),

(: Variables :)
    if ($doc/variable)
    then ('&#xa;' || '## Variables:')
    else (),

(: the table for variable calls is currently empty see    :)
    for $v in $doc/variable
        return
            (local:switch-report($v),

            if ($v/calls)
            then ('&#xa;' || '### Internal Functions that reference this Variable' || '&#xa;' ||
                  '*Module URI*|*Function Name*' || '&#xa;'|| ':----|:----' ||
                    local:switch-report($v/calls))
            else()),

(:  Functions :)
    if ($doc/function)
    then ('&#xa;' || '## Function Summary' || '&#xa;')
    else (),

    for $f in $doc/function
    return
    ('&#xa;' || '### ' || data($f/@name),

    local:switch-report($f),

    if ($f/description)
    then ('&#xa;' || '### Function Detail:',
            local:switch-report($f/description))
    else (),

    if ($f/argument)
    then ('&#xa;' || '#### Parameters:',
            local:switch-report($f/argument))
    else (),

    if ($f/returns)
    then ('&#xa;' || '#### Returns:',
            local:switch-report($f/returns))
    else(),

    if ($f/calls)
    then ('&#xa;' || '#### External Functions that are used by this Function' || '&#xa;' ||
          '*Module URI*|*Function Name*' || '&#xa;' || ':----|:----' || '&#xa;' ||
            local:switch-report($f/calls))
    else())
)

(:    $sample:)
(:$doc:)
