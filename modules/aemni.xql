xquery version "3.1";

(:~
: aemni working module.
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
import module namespace sparql = "http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

declare namespace output = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $test := element root {
    for $i in 1 to 500
    return
        element item {
            attribute xml:id {'i' || $i},
            $i
        }
};

declare %public function local:nest-categories($rows as node()*, $id as node()*, $id-prefix as xs:string) as element(category)* {
    
    (:~
 : recursive function for creating nested categories. 
 : Determines the langue of `catDesc` based on  element name in source file,
 : omitting missing information.
 : 
 : `TEXT_BIBLCAT_TYPES` and `OFFICE_TYPE_TREE` contain higher level groupings
 : `TEXT_BIBLCAT_CODES`, and `OFFICE_CODES` contain subdivisions. 
 : should this query result in a maxCauseCount error (1676) you ll need to 
 : increase this in a custom build of `lucene-core-4.10.4.jar`.
 :
 : @see https://sourceforge.net/p/exist/mailman/message/24540933/
 :
 : @param $rows **row** from `*_TYPES` table
 : @param $id the id child element of the row.
 : @param $id-prefix the string prefix of the output id attributes values
 : @param $codes the rows of the `*_CODES* table
 : @param $rel the rows of the types-2-codes relationship table
 :
 : returns nested category elements:)
    
    let $zh := $id/../*[ends-with(local-name(.), '_chn')]
    let $py := $id/../*[ends-with(local-name(.), '_pinyin')]
    let $en := $id/../*[ends-with(local-name(.), ('_desc', '_trans'))]
    
    let $zh-alt := $id/../*[ends-with(local-name(.), '_chn_alt')]
    let $py-alt := $id/../*[ends-with(local-name(.), '_pinyin_alt')]
    let $en-alt := $id/../*[ends-with(local-name(.), '_trans_alt')]
    
    let $sort := $id/../*[ends-with(local-name(.), '_sortorder')]
    let $parent := $rows/*[ends-with(local-name(.), '_parent_id')]
        
        order by number($sort)
    
    return
        element category {
            attribute xml:id {$id-prefix || $id},
            (: the main category:)
            element catDesc {
                attribute xml:lang {'zh-Hant'},
                normalize-space($zh)
            },
            
            if (empty($py)) then
                ()
            else
                (element catDesc {
                    attribute xml:lang {'zh-Latn-alalc97'},
                    normalize-space($py)
                }),
            (: prevent empty or meaningless elements :)
            if (lower-case($en) = ($zh, '[not yet translated]', '', '/')) then
                ()
            else
                if (ends-with($en, '(Hucker)'))
                then
                    (element catDesc {
                        attribute xml:lang {'en'},
                        attribute resp {'Hucker'}, normalize-space(substring-before($en, ' (Hucker)'))
                    })
                else
                    (element catDesc {
                        attribute xml:lang {'en'},
                        normalize-space($en)
                    }),
            
            (: alternative desriptions :)
            let $seq := ($zh-alt, $py-alt, $en-alt)
            for $alt in $seq
            let $lang := switch (index-of($seq, $alt))
                case 1
                    return
                        'zh-Hant'
                case 2
                    return
                        'zh-Latn-alalc97'
                default return
                    'en'
        return
            if (empty($alt)) then
                ()
            else
                (for $n at $p in tokenize($alt, ';')
                    order by $p
                return
                    (: skip entries ending with semicolon :)
                    if ($n eq '') then
                        ()
                    else
                        (
                        element catDesc {
                            attribute ana {'alt'},
                            attribute n {$p},
                            attribute xml:lang {$lang},
                            normalize-space($n)
                        })),
        
        if (substring-before(util:document-name($rows[1]), '_TYPE') eq 'OFFICE')
        then
            (
            (:~
            : There are 5907 ids appearing in two locations (4 tang ids appear more then twice (11037, 11039, 11042, 11045) )
            : The first appearance generally assigns an office to a dynsastic period, which is superflous. 
            : This code below returns the more meaningfull second occurrence.
            : To fix the 4 ids with more then two locations in the org tree there is a separate fix-up function. 
            :)
            let $codes := $config:OFFICE_CODES//no:row
            let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row
            let $option := <option><filter-rewrite>yes</filter-rewrite></option>

            let $matches := $codes/no:c_office_id[. = $type-rel/no:c_office_tree_id[ft:query(., <term>{$id}</term>, $option)]/../no:c_office_id]/..
            
            for $match in $matches

            return                                              
                (: in offices the second column contains the key id :)
                local:nest-categories($matches, $match/*[2], $id-prefix)
            )
        else
            (
            let $codes := $config:TEXT_BIBLCAT_CODES//no:row
            let $type-rel := $config:TEXT_BIBLCAT_CODE_TYPE_REL//no:row
            let $matches := $codes/no:c_text_cat_code[. = $type-rel/no:c_text_cat_type_id[. = $id]/../no:c_text_cat_code]/..
            
            for $match in $matches
            return
                (: the first child is usually the key id column :)
                local:nest-categories($matches, $match/*[1], $id-prefix)
            ),
        
        if (exists($parent[. eq $id]))
        then
            (for $child in $parent[. eq $id]/..
            return
                local:nest-categories($rows, $child/*[1], $id-prefix))
        else
            ()
    }
};

let $offices := $config:OFFICE_TYPE_TREE//no:row
let $codes := $config:OFFICE_CODES//no:row
let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row

let $option := <option><filter-rewrite>yes</filter-rewrite></option>

(:for $n in $offices/no:c_parent_id[. = 0]/..:)
(:for $n in $type-rel/no:c_office_tree_id[ft:query(., <term>06</term>, $option)]
return
$n/..:)
(:$n[ft:query(., <term>18</term>, <option><filter-rewrite>yes</filter-rewrite></option>)]/..:)

(:let $fix-dupes := 
    map:merge(
    for $n in $codes/no:c_office_id
    let $count := count($type-rel/no:c_office_id[. = $n])
    return
        if ($count > 1)
        then
            (map:entry($n/text(), $type-rel/no:c_office_id[. = $n][2]/../no:c_office_tree_id/text()))
        else
            (map:entry($n/text(), $type-rel/no:c_office_id[. = $n][1]/../no:c_office_tree_id/text()))
    ):)
(:return
<root>{
for $n in $codes/no:c_office_id[. = $type-rel/no:c_office_tree_id[. = 06020205]/../no:c_office_id]
let $count := count($type-rel/no:c_office_id[. = $n])
return
    if ($count > 1)
    then ($type-rel/no:c_office_id[. = $n][2]/..) (\:this is sucky way to choose:\)
    else ($type-rel/no:c_office_id[. = $n]/..)
}</root>     
:)

    
(:   $type-rel/no:c_office_id[. = $n/../no:c_office_id][2]:)

(:for $n in $type-rel/no:c_office_tree_id
return
if (count($type-rel/no:c_office_tree_id[. = '06100402']/../no:c_office_id) > 1)
then ($type-rel/no:c_office_tree_id[. = '06100402']/../no:c_office_id)
else ('no'):)
    

for $n in $offices[1]
return
    local:nest-categories($offices, $n/no:c_office_type_node_id, 'OFF')
    
