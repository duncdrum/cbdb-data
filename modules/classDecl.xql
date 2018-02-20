xquery version "3.1";
(:~
 : This module generates the taxonomies for the teiHeader's classDecl element. 
 : All taxonomy entries should be referenced by their full URL from the indivial body lists. 
 : 
 :
 : @author Duncan Paterson
 : @version 0.8.0
 : 
 : @return data/classDecl/biblCat.xml
 : @return data/classDecl/
 : @return data/classDecl/
 :)

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";
import module namespace app = "http://exist-db.org/apps/cbdb-data/templates" at "app.xql";
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace taxo = "http://exist-db.org/apps/cbdb-data/taxo";


declare namespace output = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $target-classDecl := xmldb:create-collection($config:target-aemni, 'classDecl');
declare variable $target-calendar := xmldb:create-collection($config:target-aemni, 'calendar');

(:~
 : taxo:write-biblCat combines `TEXT_BIBLCAT_CODES` and `TEXT_BIBLCAT_TYPES` into nested taxonomy elements.
 : It ommits `TEXT_BIBL_CAT_TYPES_1` which does not seem to serve a purpose. :
 : The classification scheme seems to be based on the outdated Harvard–Yenching Classification. 
 :
 : TODO replace CBDB classification scheme with either CLC or LCC
 : TODO there are duplicates in the sources, between types and codes that could be streamlined.
 :
 : The exact difference between bibliographical category codes, and category types is unclear. 
 : This module joins them within one taxonomy and at the level specified in the source files. 
 :
 :
 : @see [harvard-Yenching CC](https://en.wikipedia.org/wiki/Harvard–Yenching_Classification#0100_to_0999_Chinese_Classics)
 : @see [CLC](http://clc.nlc.cn)
 : @see [LCC](https://www.loc.gov/catdir/cpso/lcc.html)
 : @see [new CLC](http://library.hkbu.edu.hk/about/class-chi.html)
 :
 : @return biblCat.xml:)

declare function taxo:nest-types($types as node()*, $type-id as node(), $zh as node(), $en as node()) as element(category)* {
    
    (:~ 
 : taxo:nest-types recursively transforms `TEXT_BIBLCAT_TYPES` into nested categories. 
 :
 : @param $types **row** in `TEXT_BIBLCAT_TYPES`
 : @param $type-id is a `c_text_cat_type_id`
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
            taxo:nest-types($types, $child/no:c_text_cat_type_id, $child/no:c_text_cat_type_desc_chn, $child/no:c_text_cat_type_desc)
    }

};

declare %private function taxo:write-biblCat($items as item()*, $types as item()*) as item()* {
    (:~
 : calls taxo:nest-types recursively  from top level elements.
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
                                    taxo:nest-types($types, $outer/no:c_text_cat_type_id, $outer/no:c_text_cat_type_desc_chn, $outer/no:c_text_cat_type_desc)
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

declare %test:assertTrue function taxo:validate-biblCat() {
    validation:jing(doc($config:target-classdecl || $config:genre), $config:tei_all)
};


(: TIMING: 1.4s:)

(
taxo:write-biblCat($config:TEXT_BIBLCAT_CODES//no:c_text_cat_code, $config:TEXT_BIBLCAT_TYPES//no:row)
)