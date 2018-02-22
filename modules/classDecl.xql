xquery version "3.1";
(:~
 : This module generates the taxonomies for the teiHeader's classDecl element. 
 : This is an updating module, which will overwrite existing data. 
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
declare variable $target-office := xmldb:create-collection($config:target-aemni, 'office');

(:~
 : GENRE TAXONOMY
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

declare function taxo:sexagenary($ganzhi as node()*) as item()* {
(:~
 : CALENDAR TAXONOMY
 : taxo:sexagenary converts `GANZHI` data into categories. 
 : 
 : @param $ganzhi rows from `GANZHI_CODES` filtering 'unkown'
 : 
 : @return `<taxonomy xml:id="sexagenary">...</taxonomy>`:)
 
    <TEI>
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>Sexagenary Calendar</title>
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
                        xml:id="sexagenary">{
                            for $gz in $ganzhi/no:c_ganzhi_code[. ne '0']
                            return
                                <category
                                    xml:id="{concat('S', $gz/../no:c_ganzhi_code)}">
                                    <catDesc
                                        xml:lang="zh-Hant">{normalize-space($gz/../no:c_ganzhi_chn)}</catDesc>
                                    <catDesc
                                        xml:lang="zh-Latn-alalc97">{normalize-space($gz/../no:c_ganzhi_py)}</catDesc>
                                </category>
                        }
                    </taxonomy>
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

declare function taxo:dynasties($dynasties as node()*, $nianhao as node()*) as item()* {
    (:~
 : taxo:dynasties converts `DYNASTIES`, and `NIANHAO` data into categories. 
 : The sparql part is awaiting a bug fix and therefore incomplete. 
 : TODO make sparql shine, with better query and dynamically pulled Qids
 :
 : @param $dynasties row from `DYNASTIES`
 : @param $nianhao row from `NIAN_HAO`
 :
 : #see http://tinyurl.com/y7mdp2lt
 : @return `<taxonomy xml:id="reign">...</taxonomy>` :)
    
    let $map := map
    {
        5: 'wd:Q7405',
        6: 'wd:Q9683',
        15: 'wd:Q7462',
        16: 'wd:Q4958',
        17: 'wd:Q5066',
        18: 'wd:Q7313',
        19: 'wd:Q9903',
        20: 'wd:Q8733',
        25: 'wd:Q1147037',
        27: 'wd:Q306928',
        43: 'wd:Q7183',
        71: 'wd:Q169705',
        77: 'wd:Q35216'
    }
    
    return
        
        <TEI>
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title>Chinese Dynastyc Reign Calendar</title>
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
                            xml:id="reign">{
                                for $dy in $dynasties/no:c_dy[. > '0']
                                let $dy-id := $dy/../no:c_dy
                                return
                                    element category {
                                        attribute xml:id {'D' || $dy-id},
                                        if (map:contains($map, $dy-id))
                                        then
                                            (attribute source {$map($dy-id)})
                                        else
                                            (),
                                        element catDesc {
                                            element date {
                                                attribute from {cal:isodate($dy/../no:c_start)},
                                                attribute to {cal:isodate($dy/../no:c_end)}
                                            }
                                        },
                                        element catDesc {
                                            attribute xml:lang {'zh-Hant'},
                                            normalize-space($dy/../no:c_dynasty_chn)
                                        },
                                        element catDesc {
                                            attribute xml:lang {'en'},
                                            normalize-space($dy/../no:c_dynasty)
                                            },
                                            for $nh in $nianhao/no:c_dy[. = $dy-id]
                                            return
                                                element category {
                                                    attribute xml:id {'R' || $nh/../no:c_nianhao_id},
                                                    element catDesc {
                                                        element date {
                                                            attribute from {cal:isodate($nh/../no:c_firstyear)},
                                                            attribute to {cal:isodate($nh/../no:c_lastyear)}
                                                        }
                                                    },
                                                    element catDesc {
                                                        attribute xml:lang {'zh-Hant'},
                                                        normalize-space($nh/../no:c_nianhao_chn)
                                                    },
                                                    if ($nh/../no:c_nianhao_pin != '')
                                                    then
                                                        (element catDesc {
                                                            attribute xml:lang {'zh-Latn-alalc97'},
                                                            normalize-space($nh/../no:c_nianhao_pin)
                                                        })
                                                    else
                                                        ()
                                                }
                                    }                            
                        }</taxonomy>
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

declare %private function taxo:write-calendar($sexa as item()*, $dyna as item()*, $nian as item()*) as item()* {
(:~
 : write the taxonomies containing the results of both taxo:sexagenary and cal:dynasties into db. 
 : TODO think about splitting each dynasty into its own file
 :)
    
    (xmldb:store($config:target-calendar, $config:sexagen, taxo:sexagenary($sexa)),
    xmldb:store($config:target-calendar, $config:calendar, taxo:dynasties($dyna, $nian)))

};

declare %test:assertTrue function taxo:validate-sexagenary() {
    validation:jing(doc($config:target-calendar || $config:genre), $config:tei_all)
};

declare %test:assertTrue function taxo:validate-dynasties() {
    validation:jing(doc($config:target-calendar || $config:calendar), $config:tei_all)
};



(: TIMING 0.8s :)(: TIMING: 1.4s:)
(
taxo:write-calendar($config:GANZHI_CODES//no:row, $config:DYNASTIES//no:row, $config:NIAN_HAO//no:row),
taxo:write-biblCat($config:TEXT_BIBLCAT_CODES//no:c_text_cat_code, $config:TEXT_BIBLCAT_TYPES//no:row)
)
