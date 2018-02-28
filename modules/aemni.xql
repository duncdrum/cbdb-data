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
            
            if (lower-case($en) = ($zh, '[not yet translated]', '')) then
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
        
        (:  TODO: these hard coded references need to become dynamic :)
        if (substring-before(util:document-name($rows[1]), '_TYPE') eq 'OFFICE')
        then
            (
            let $codes := $config:OFFICE_CODES//no:row
            let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row
            (: this is a hack :)
            let $matches := 
                if (count($type-rel/no:c_office_tree_id[. = $id]) > 1) 
                then
                    ( $codes/no:c_office_id[. = $type-rel/no:c_office_tree_id[. = $id][2]/../no:c_office_id]/..)
                else 
                    ($codes/no:c_office_id[. = $type-rel/no:c_office_tree_id[. = $id]/../no:c_office_id]/..)
               
            
            for $match in $matches
            return                
                (: the first child is always the key id column  except for offices there it is the second:)
                local:nest-categories($matches, $match/*[2], $id-prefix)
            )
        else
            (
            let $codes := $config:TEXT_BIBLCAT_CODES//no:row
            let $type-rel := $config:TEXT_BIBLCAT_CODE_TYPE_REL//no:row
            let $matches := $codes/no:c_text_cat_code[. = $type-rel/no:c_text_cat_type_id[. = $id]/../no:c_text_cat_code]/..
            
            for $match in $matches
            return
                (: the first child is always the key id column :)
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
(:let $codes := $config:OFFICE_CODES//no:row
let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row


for $match in $offices
let $id := $match/*[1][. = '06']
let $off-id := $type-rel/no:c_office_tree_id[. =  $id]/../no:c_office_id
let $off := $codes/no:c_office_id[. =$off-id]/..
let $matches := $codes/no:c_office_id[. = $type-rel/no:c_office_tree_id[. = $id]/../no:c_office_id]/..
return
   <result>{ 
$matches   }</result>:)

(:for $n in $offices/no:c_parent_id[. = 0]/..:)
for $n in $offices[1]
return
    local:nest-categories($offices, $n/no:c_office_type_node_id, 'OFF')
   

(:let $seq := (1, 2, 3, 1, 1 )
for $n in $seq    
return
 if (count($n) > 1)
 then ($n)
 else ():)