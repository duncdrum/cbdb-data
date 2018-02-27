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
import module namespace dbutil = "http://exist-db.org/xquery/dbutil";
import module namespace sparql = "http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";

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
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

(:declare namespace output = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";:)

declare variable $target-calendar := xmldb:create-collection($config:target-aemni, 'calendar');
declare variable $wd-sparql := doc($config:app-root || "/src/sparql/multi-dy.xml");


declare %private function local:taxonomy-wrap($id as xs:string, $title as xs:string, $f as function(*), $args as array(*)) as element(TEI) {
    (:~
 : Fix Higher-order function syntax so that this works with any arity.
 : then fix classDecl to use wrap instead of two fragments.
:)
    <TEI>
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>{$title}</title>
                </titleStmt>
                <publicationStmt>
                    <p>Part of CBDB in TEI</p>
                </publicationStmt>
                <sourceDesc>
                    <p>born digital</p>
                </sourceDesc>
            </fileDesc>
            <encodingDesc>
                <classDecl>
                    <taxonomy
                        xml:id="{$id}">{apply($f, $args)}</taxonomy>
                </classDecl>
            </encodingDesc>
        </teiHeader>
        <text>
            <body>
                <p/>
            </body>
        </text>
    </TEI>
};


declare %public function local:nest-categories($rows as node()*, $id as node()*, $id-prefix as xs:string) as element(category)* {

(:~
 : recursive function for creating nested categories. 
 : Determines the langue of `catDesc` based on  element name in source file. 
 : Used for office and genre categories: `TEXT_BIBLCAT_TYPES`, 
 :`TEXT_BIBLCAT_CODES`, and …  
 :
 : @param $rows **row** from `*_TYPES` table
 : @param $id the id child element of the row.
 : @param $id-prefix the string prefix of the output id attributes values
 :
 : returns nested category elements:)
 
let $zh := $id/../*[ends-with(local-name(.), '_desc_chn')]
let $en := $id/../*[ends-with(local-name(.), '_desc')]
let $py := $id/../*[ends-with(local-name(.), '_pinyin')]
let $sort := $id/../*[ends-with(local-name(.), '_sortorder')]

let $parent := $rows/*[ends-with(local-name(.), '_parent_id')]



order by number($sort)

return
   element category {
            attribute xml:id {$id-prefix || $id},
            element catDesc {
                attribute xml:lang {'zh-Hant'},
                    normalize-space($zh)
            },
            
            if (empty($py)) then ()
            else (
            element catDesc {
                attribute xml:lang {'zh-Latn-alalc97'},
                    normalize-space($py)
            }),
            
            if (($en eq $zh) or ($en eq '[not yet translated]')) then ()
            else (
            element catDesc {
                attribute xml:lang {'en'},
                    normalize-space($en)
            }),
        (:  TODO: these hard coded references need to become dynamic :)
            let $categ := $config:TEXT_BIBLCAT_CODES//no:row
            let $cat-type-rel := $config:TEXT_BIBLCAT_CODE_TYPE_REL//no:row
            let $matches := $categ/no:c_text_cat_code[. = $cat-type-rel/no:c_text_cat_type_id[. = $id]/../no:c_text_cat_code]/..
            
            for $match in $matches
            return
                local:nest-categories($matches, $match/*[1],  'biblCat'),
                
            if (exists($parent[. eq $id]))
            then ( for $child in $parent[. eq $id]/..           
            return
                local:nest-categories($rows, $child/*[1], $id-prefix))
            else ()
        }
};




declare %test:assertTrue function local:validate-biblCat() {
    validation:jing(doc($config:target-classdecl || $config:genre), $config:tei_all)
};


