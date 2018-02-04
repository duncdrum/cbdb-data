xquery version "3.1";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog="http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";
import module namespace org="http://exist-db.org/apps/cbdb-data/institutions" at "institutions.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $suffix := ('_dy', ('_nh_year', '_nh_yr'), '_nh_code', ('_day_gz', '_day_ganzhi'), '_range', ('_year', '_yr', 'year'), '_month', '_day', '_intercalary', '_date'); 

(:~
 This file imports all modules present in the database for easy testing. 
:)

(:
How little input can we give this to still function, and how much do i need to make it usable in any cases where there are dates. 
What is the best form for the output date element, or string to be used in values
Can the function determine when/notBefore/... based on switch
Should the date element alwys have @when?
:)

(: TODO
- shorten the whole sequnce of $startL - $startL - $prefix 
    - refactor using => and ! syntax
    - refactor the conditional into a better expression
    _ fix the D\n value when it comes from Reign period data in $strings switch statement
:)

declare 
    %test:pending("later")
function local:zh-dates ($nodes as item()*) as item()* {
    
(:~ 
: 1.1 we test source element's suffix to see if it the sequence of date related suffixes
: 1.2 we prepare normalised strings based on the matched suffixes 
: 2.1-3 we iterate over the beginning parts until we have map of the prefixes that accounts for irregularities 
:  3. generate a intermediate lookup xml necessary for grouping 
:
: Applying the filter for '0' in the for-clause is most efficient for the data of CBDB, but could lead to errors with other sources. 
:
: @param $nodes the siblings of a candidate element containing a date. 
: 
: @return an intermediate xml fragment containing properly formatted and joined date elements.:)

<root>{
for $node in $nodes/../*[. != '0']

let $name := node-name($node) (: local-name() ? :)
let $reign := $cal:path/category[@xml:id = concat('R', $node)]


(: First, we find all the date related nodes from a given row... :)

let $match :=  map:new (    
    for $m at $pos in $suffix
    return
        if (ends-with($name, $m))
        then (map:entry($name, $pos))
    else()
    )
                
(: and  apply preprocessing to generate properly formated date strings to work with. :)
let $strings := 
    switch($match($name))
        case 1 return concat('D', $global:DYNASTIES//no:c_dy[. = $node]/../no:c_sort)
        case 2 case 3 return concat('Y', $node)
        case 4 return concat("D", $global:DYNASTIES//no:c_dy[. = substring-after(data($reign/parent::category/@xml:id), 'D')]/../no:c_sort, '-',
            'R', count($reign/preceding-sibling::category) +1)
        case 5 case 6 return concat('GZ', $node/text())
        case 7 return           (:this case needs a break:)
            switch($node/text())
                case ('-1') return attribute notAfter {$node}
                case ('1') return attribute notBefore {$node}
                case ('2') return (attribute when {$node}, attribute cert {'medium'})
                case ('300') return (attribute from {'0960'}, attribute to {'1082'})
                case ('301') return (attribute from {'1082'}, attribute to {'1279'})
            default return attribute when {$node} 
        case 8 case 9 case 10 return 
            if (ends-with($name, ('_nh_year', '_nh_yr'))) 
            then (concat('Y', $node)) (: should this also be padded? :)
            else (cal:isodate($node))
        case 11 case 12 return functx:pad-integer-to-length($node, 2)         
        case 13 return  
            if ($node = 1) 
            then ('i') 
            else ()                       
        case 14 return cal:sqldate($node)       
    default return ()
 
(: now we bind the name of the date elements to a (long) prefix to not loose ubiquitous 'c_dy'... :)
let $startL :=  map:new (
    for $part in map:keys($match)   
    return       
        for $p at $pos in $suffix       
        return
            if (ends-with($name, $p))
            then (map:entry($name, substring-before($part, $p))) (::)
            else ()
    )

(: ...to account for special case that in BIOG_MAIN c_dy = deathyear, but everywhere else c_dy = dynasty ... :)
let $startS := map:new (
    for $s in $startL($name)
    return
        if ($s ='c')
        then (map:entry($name, 'c_dy'))
        else (map:entry($name, substring-after($s, 'c_')))
    ) 
(:...finally :)
let $prefix :=  map:new (
    for $str in $startS($name)
    return
        if (contains($startS($name), substring($str, 1, 2))) (: increase to substring($str, 1, 3) for greater accuracy :)
        then (map:entry($name, substring($str, 1, 2)))
        else (map:entry($name, $str))
    )

let $lookup := 
    for $l in $startL($name)
    return
        <date>
            <name>{$name}</name>
            <group>{$prefix($name)}</group>
            <string>{$strings}</string>
        </date>
        
(: The next line  allows the whole autojoin trickery :)
group by $group := distinct-values($lookup//group)


return
    switch(count($lookup//group))
        case 0 return ()
        case 1 return <ab n="{$name}">{$strings}</ab> (:element{$name}{$strings}:)
    default return <ab n="{$name}">{string-join($strings, '-')}</ab>
}</root>
};

declare 
    %test:pending("get combined strings to work via contains and tokenize")
function local:new-date($node as node(), $att-name as xs:string)  as item()* {

(:All of this razzmatazz is necessary because of ``c_dy``'s double meaning.
We now get ``c_dy`` and ``c_dy_nh_code``, but not c_dy_nh_year, which is good
since we ll be calling longest timespan column and that  works. 

:)

let $look := local:zh-dates($node)
let $code := $node/text()
let $reign := $global:NIAN_HAO//no:c_nianhao_id[. = $code]
let $dynasty := $global:DYNASTIES//no:c_dy[. = $code]


for $n in $look//ab
(:This makes sure we can match against attributes with multiple values:)
let $seq := tokenize($n/@n, "\s")
where $seq[1][. = local-name($node)]
return
    (:Every Western dates start with a numeral, all Chinese dates start with 'D' now.:)
    if (starts-with($n/string(), "D"))
    then (attribute datingMethod {'#chinTrad'}, attribute {xs:QName($att-name)} {$n}, 
        element date { attribute calendar {'#chinTrad'}, 
            if (contains($n, 'R'))
            then (attribute period {'#R' || $code}, $reign/../no:c_dynasty_chn || $reign/../no:c_nianhao_chn || substring-after($n, 'Y'))
            else (attribute period {'#D' || $code}, $dynasty/../no:c_dynasty_chn/text()) 
        })
    else (attribute {xs:QName($att-name)} {$n})        
};


let $test := $global:BIOG_MAIN//no:c_personid[. = 1]

(:
c_dy_nh_code
c_dy_nh_year
:)

return
    <root>
        <old>{biog:biog($test, "")//floruit}</old>
        <new>
            <floruit>{for $n in $test/../*[. != '0']
                    return
                        typeswitch($n)
                            case element (no:c_index_year)  return local:new-date($n, 'when')
                            case element (no:c_fl_latest_year)  return local:new-date($n, 'notAfter')
                            case element (no:c_fl_earliest_year)  return local:new-date($n, 'notBefore')
                            case element (no:c_dy) return local:new-date($n, 'when-custom')
                        default return ()
            }</floruit> 
        </new>
        
    </root>



