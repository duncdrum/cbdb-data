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
 : @return data/classDecl/calendar/dyna_cal.xml
 : @return data/classDecl/calendar/sexa_cal.xml
 : @return data/classDecl/office/office-*.xml
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
declare variable $target-calendar := xmldb:create-collection($config:target-classdecl, 'calendar');
declare variable $target-office := xmldb:create-collection($config:target-classdecl, 'office');


(:~
 : This module generates taxonomies for the class declaration.
 : The private functions in the first section are shared among different transformations.
 : There are dedicated sections for calendrical, genre, and offices taxonomies
 : There are dedicated function that perform validation of the generated output, 
 : to be called by the xqsuite. 
 : Lastly there is a single write function that will OVERWRITE EXISTING DATA, 
:)

(: GENERAL :)

declare %public function taxo:taxonomy-wrap($id as xs:string, $title as xs:string, $f as function(*), $args as array(*)) as element(TEI) {
    (:~
 : Wrapper function to ensure each taxo is stored as a valid TEI document.
 : All write functions will call this wrapper. Modifications of the tei scaffold occur here. 
 :
 : a bug in Saxon prevent me from using <xi:include  href="../fileDesc.xml" fallback ="db/apps/cbdb-data/data/fileDesc.xml" xpointer="fileDesc" parse="xml"/>
 :
 : $param $id the xml:id of the taxonomy
 : $param $title title-line in header for taxonomy
 : $param $f the transform function from within this module.
 : $args the array of arguments used by the tranform function.
 : 
 : @return taxonomy wrapped in minimal tei scaffold. 
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

declare %public function taxo:nest-categories($rows as node()*, $id as node()*, $id-prefix as xs:string) as element(category)* {
    
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
            
            if (empty($py)) then
                ()
            else
                (
                element catDesc {
                    attribute xml:lang {'zh-Latn-alalc97'},
                    normalize-space($py)
                }),
            
            if (($en eq $zh) or ($en eq '[not yet translated]')) then
                ()
            else
                (
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
                taxo:nest-categories($matches, $match/*[1], 'biblCat'),
            
            if (exists($parent[. eq $id]))
            then
                (for $child in $parent[. eq $id]/..
                return
                    taxo:nest-categories($rows, $child/*[1], $id-prefix))
            else
                ()
        }
};

(: GENRE TAXONOMY :)

declare %private function taxo:write-biblCat($rows as item()*) as item()* {
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
 : @see [harvard-Yenching CC](https://en.wikipedia.org/wiki/Harvard–Yenching_Classification#0100_to_0999_Chinese_Classics)
 : @see [CLC](http://clc.nlc.cn)
 : @see [LCC](https://www.loc.gov/catdir/cpso/lcc.html)
 : @see [new CLC](http://library.hkbu.edu.hk/about/class-chi.html)
 :
 : @param $rows `TEXT_BIBLCAT_TYPES` 
 :
 : @return biblCat.xml :)
    
    let $bibl-tree := for $n in $rows[1]
    return
        taxo:taxonomy-wrap('biblCat', "CBDB's genre classification", taxo:nest-categories#3, [$rows, $n/no:c_text_cat_type_id, 'biblType'])
    return
        xmldb:store($config:target-classdecl, $config:genre, $bibl-tree)

};

(: CALENDAR TAXONOMIES :)

declare %public function taxo:sexagenary($ganzhi as node()*) as item()* {
    (:~
 : CALENDAR TAXONOMY
 : taxo:sexagenary converts `GANZHI` data into categories. 
 : 
 : @param $ganzhi rows from `GANZHI_CODES` filtering 'unkown'
 : 
 : @return `<taxonomy xml:id="sexagenary">...</taxonomy>`
 :)
    
    for $gz in $ganzhi/no:c_ganzhi_code[. ne '0']
    return
        <category
            xml:id="{concat('S', $gz/../no:c_ganzhi_code)}">
            <catDesc
                xml:lang="zh-Hant">{normalize-space($gz/../no:c_ganzhi_chn)}</catDesc>
            <catDesc
                xml:lang="zh-Latn-alalc97">{normalize-space($gz/../no:c_ganzhi_py)}</catDesc>
        </category>
};

declare %public function taxo:dynasties($dynasties as node()*) as item()* {
    (:~
 : taxo:dynasties converts `DYNASTIES`, and `NIANHAO` data into categories. 
 : The sparql part is awaiting a bug fix and therefore incomplete. 
 : TODO make sparql shine, with better query and dynamically pulled Qids
 :
 : @param $dynasties row from `DYNASTIES`
 : @param $nianhao row from `NIAN_HAO`
 :
 : #see http://tinyurl.com/y7mdp2lt
 : @see http://authority.dila.edu.tw/time/
 :
 : @return `<taxonomy xml:id="reign">...</taxonomy>`
 :)
    
    let $nianhao := $config:NIAN_HAO//no:row
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
    
    for $dy in $dynasties/no:c_dy[. > '0']
    let $dy-id := $dy/../no:c_dy
    (:    let $nianhao := $config:NIAN_HAO//no:row:)
    
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
};

declare %private function taxo:write-calendar($sexa as item()*, $dyna as item()*) as item()* {
    (:~
 : write the taxonomies containing the results of both taxo:sexagenary and cal:dynasties into db. 
 : TODO think about splitting each dynasty into its own file
 :)
    
    (xmldb:store($config:target-calendar, $config:sexagen,
    taxo:taxonomy-wrap('sexagenary', 'Sexagenary Calendar', taxo:sexagenary#1, [$sexa])),
    xmldb:store($config:target-calendar, $config:calendar,
    taxo:taxonomy-wrap('reign', 'Chinese Dynastyc Reign Calendar', taxo:dynasties#1, [$dyna])))

};

(: OFFICE TAXONOMIES :)

(: VALIDATION :)

declare %test:assertTrue function taxo:validate-biblCat() {
    validation:jing(doc($config:target-classdecl || $config:genre), $config:tei_all)
};

declare %test:assertTrue function taxo:validate-sexagenary() {
    validation:jing(doc($config:target-calendar || $config:sexagen), $config:tei_all)
};

declare %test:assertTrue function taxo:validate-dynasties() {
    validation:jing(doc($config:target-calendar || $config:calendar), $config:tei_all)
};



(: TIMING 2.2s :)
(
taxo:write-calendar($config:GANZHI_CODES//no:row, $config:DYNASTIES//no:row),
taxo:write-biblCat($config:TEXT_BIBLCAT_TYPES//no:row)
)
