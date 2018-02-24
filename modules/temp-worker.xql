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


declare %private function local:taxonomy-wrap($id as xs:string, $title as xs:string, $f as function(*), $arg as item()*) as element(TEI) {
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
                        xml:id="{$id}">{$f($arg)}</taxonomy>
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

declare function local:nest-types($types as node()*, $type-id as node(), $zh as node(), $en as node()) as element(category)* {
    
    (:~ 
 : local:nest-types recursively transforms `TEXT_BIBLCAT_TYPES` into nested categories. 
 : TODO make nest functio suffienceitly abstract to make do with just one.
 :
 : @param $types **row** in `*_TYPES`
 : @param $type-id is a `*_type_id`
 : @param $zh category name in Chinese
 : @param $en category name in English
 :
 : @return nested `<category xml:id="biblType">...</category>`:)
    
    
    element category {
        attribute xml:id {concat('biblType', $type-id)},
        element catDesc {
            attribute xml:lang {'zh-Hant'},
            normalize-space($zh)
        },
        element catDesc {
            attribute xml:lang {'en'},
            normalize-space($en)
        },
        
        for $child in $types[no:c_text_cat_type_parent_id = $type-id]
            order by $child[no:c_text_cat_type_sortorder]
        return
            local:nest-types($types, $child/no:c_text_cat_type_id, $child/no:c_text_cat_type_desc_chn, $child/no:c_text_cat_type_desc)
    }

};

declare %private function local:write-biblCat($items as item()*, $types as item()*) as item()* {
    (:~
 : calls local:nest-types recursively  from top level elements.
 : Executing the write will return an empty sequence. 
 : This is misleading, the correct data should have been written regardless.
 :
 : @param $items `TEXT_BIBLCAT_CODES` to be inserted into nested types
 : @param $types `TEXT_BIBLCAT_TYPES`
 :
 : a bug in Saxon prevent me from using <xi:include  href="../fileDesc.xml" fallback ="db/apps/cbdb-data/data/fileDesc.xml" xpointer="fileDesc" parse="xml"/>
 :
 : @returns $typeTree the nested tree of types stored in the db with inserted codes :)
    let $match := $types/no:c_text_cat_type_id[. = '01']
    let $typeTree := xmldb:store($config:target-classdecl, $config:genre,
    <TEI>
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>CBDB's genre classification</title>
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
                        xml:id="biblCat">
                        <category
                            xml:id="biblType01">
                            <catDesc
                                xml:lang="zh-Hant">{normalize-space($match/../no:c_text_cat_type_desc_chn)}</catDesc>
                            <catDesc
                                xml:lang="en">{normalize-space($match/../no:c_text_cat_type_desc)}</catDesc>
                            {
                                for $outer in $types[no:c_text_cat_type_parent_id = '01']
                                    order by $outer[no:c_text_cat_type_sortorder]
                                return
                                    local:nest-types($types, $outer/no:c_text_cat_type_id, $outer/no:c_text_cat_type_desc_chn, $outer/no:c_text_cat_type_desc)
                            }
                        </category>
                    </taxonomy>
                </classDecl>
            </encodingDesc>
        </teiHeader>
        <text>
            <body>
                <p/>
            </body>
        </text>
    </TEI>)
    
    (: inserts the genre categories codes, into the previously generated tree of category types :)
    
    for $cat in $items
    
    let $type-id := $config:TEXT_BIBLCAT_CODE_TYPE_REL//no:c_text_cat_code[. = $cat]/../no:c_text_cat_type_id
    let $type := doc($typeTree)//category/@xml:id[. = concat('biblType', $type-id)]
    let $category := element category {
        attribute xml:id {concat('biblCat', $cat)},
        element catDesc {
            attribute xml:lang {'zh-Hant'},
            normalize-space($cat/../no:c_text_cat_desc_chn)
        },
        element catDesc {
            attribute xml:lang {'zh-Latn-alalc97'},
            normalize-space($cat/../no:c_text_cat_pinyin)
        },
        if ($cat/../no:c_text_cat_desc/text() eq $cat/../no:c_text_cat_desc_chn/text())
        then
            ()
        else
            (element catDesc {
                attribute xml:lang {'en'},
                normalize-space($cat/../no:c_text_cat_desc)
            })
    }
        order by number($cat/../no:c_text_cat_sortorder)
    return
        update insert $category into $type/..
};



declare %test:assertTrue function local:validate-dynasties() {
    validation:jing(doc($config:target-calendar || $config:calendar), $config:tei_all)
};

(: TIMING 0.8s :)
(:
let $dynasties := $config:DYNASTIES//no:row:)

local:taxonomy-wrap('reign', 'Chinese Dynastyc Reign Calendar', local:dynasties#1, $config:DYNASTIES//no:row)
(:local:taxonomy-wrap('sexagenary', 'Sexagenary Calendar', local:sexagenary#1, $config:GANZHI_CODES//no:row):)

(:validation:jing-report(doc($config:target-calendar || $config:calendar), $config:tei_all):)