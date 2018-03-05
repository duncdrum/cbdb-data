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
 : Determines the langue of `catDesc` based on  element name in source file,
 : omitting missing information.
 : 
 : `TEXT_BIBLCAT_TYPES` and `OFFICE_TYPE_TREE` contain higher level groupings
 : `TEXT_BIBLCAT_CODES`, and `OFFICE_CODES` contain subdivisions. 
 : should this query result in a maxCauseCount error (1676) you ll need to 
 : increase this in a custom build of `lucene-core-4.10.4.jar`. Or use ft:query option
 :
 : @see [exist-db mailing list](https://sourceforge.net/p/exist/mailman/message/24540933/)
 : @see [exist-db documentation](http://exist-db.org/exist/apps/doc/lucene.xml?q=lucene&field=all&id=D1.4.6#D1.4.10.20)
 :
 : @param $rows **row** from `*_TYPES` table
 : @param $id the id child element of the row.
 : @param $id-prefix the string prefix of the output id attributes values
 : @param $codes the rows of the `*_CODES* table
 : @param $rel the rows of the types-2-codes relationship table
 :
 : returns nested category elements:)
    
    let $zh := $id/../*[ends-with(name(.), '_chn')]
    let $py := $id/../*[ends-with(name(.), '_pinyin')]
    let $en := $id/../*[ends-with(name(.), ('_desc', '_trans'))]
    
    let $zh-alt := $id/../*[ends-with(name(.), '_chn_alt')]
    let $py-alt := $id/../*[ends-with(name(.), '_pinyin_alt')]
    let $en-alt := $id/../*[ends-with(name(.), '_trans_alt')]
    
    let $sort := $id/../*[ends-with(name(.), '_sortorder')]
    let $parent := $rows/*[ends-with(name(.), '_parent_id')]
        
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
        
            (:~
            : There are 5907 ids appearing in multiple locations 
            : @see taxo:fixup-office
            :)
        if (substring-before(util:document-name($rows[1]), '_TYPE') eq 'OFFICE')
        then
            (
            let $codes := $config:OFFICE_CODES//no:row
            let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row
            let $option := <option><filter-rewrite>yes</filter-rewrite></option>
            let $query := <term>{$id}</term>

            let $matches := $codes/no:c_office_id[. = $type-rel/no:c_office_tree_id[. = $id]/../no:c_office_id]/..
               
            
            for $match in $matches
            return                
                (: the first child is always the key id column  except for offices there it is the second:)
                taxo:nest-categories($matches, $match/*[2], $id-prefix)
            )
        else
            (
            let $codes := $config:TEXT_BIBLCAT_CODES//no:row
            let $type-rel := $config:TEXT_BIBLCAT_CODE_TYPE_REL//no:row
            let $matches := $codes/no:c_text_cat_code[. = $type-rel/no:c_text_cat_type_id[. = $id]/../no:c_text_cat_code]/..
            
            for $match in $matches
            return
                (: the first child is always the key id column :)
                taxo:nest-categories($matches, $match/*[1], $id-prefix)
            ),
        
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
declare %public function taxo:write-office($offices as item()*) as item()* {
(:~
 : not much has happened in the last update to the structural problems.
 : To keep avoiding maXClauseCount errors on unmodified exist-db installations
 : this performs three seaparat write operations, instead of just processing all
 : offices in one go. 
 : Lastly, there is a fixup function that needs to run on the initial ouput. 
 :
 : @see taxo:fixup-offices
 :) 
 
(: no note if contents equal 'alt'                                               [ ]
add ana=main to main entries? edit ODD no more type here                      [ ]
fix old n="00" codes                                                               [ ]
add test that compares count($src//rows) with count($data//category)       [ ]
see old inline comments
create a fix-up function that is called by write and sorts this mess as best it can [x]
:)
let $count := count($offices/no:c_parent_id[. = 0])

let $report := <data top="{$count}">
        {for $n in $offices/no:c_parent_id[. = 0]/../no:c_office_type_node_id
        let $position := index-of($offices//no:c_office_type_node_id, $n)
        return
            <id pos="{$position}">{$n/text()}</id>
        }
        </data>
 (:
<data top="6">
    <id pos="1">06</id>
    <id pos="391">15</id>
    <id pos="550">16</id>
    <id pos="1016">18</id>
    <id pos="2011">19</id>
    <id pos="2012">20</id>
</data>
:)

(:
for $n in $offices/no:c_parent_id[. = 0]/..
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF']))
    :)

(for $n in $offices[1]
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF'])),

for $n in $offices[391]
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF'])),

for $n in $offices[550]
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF'])),

for $n in $offices[1016]
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF'])),

for $n in $offices[2011]
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF'])),

for $n in $offices[2012]
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    taxo:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', taxo:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF']))    
)
};

declare %private %updating function taxo:fixup-offices () {
(:~
 : There are 5907 ids appearing in two locations (4 tang ids appear more then twice (11037, 11039, 11042, 11045) )
 : The first appearance generally assigns an office to a dynsastic period, which is superflous. 
 : This code below returns the more meaningfull second occurrence.There are three files with problematic IDs :)
 
let $office-06 := doc($config:target-office || 'office-06.xml')
let $office-15 := doc($config:target-office || 'office-15.xml')
let $office-18 := doc($config:target-office || 'office-18.xml')

(: There  is a bug with the updating extension in 4.0.0 once fixed run this:)

for $n at $p in $office-06//*
let $data := data($n/@xml:id)

let $report := 
   if (count($office-06//*[@xml:id = $data]) = 1)
   then ()            

   else if (data($n/../../tei:category/@xml:id)[1] = 'OFF06')
            then (<delete n="{$p}" at="{data($n/../../tei:category/@xml:id)[1]}">{$n}</delete>)
            else (<keep n="{$p}" at="{data($n/../../tei:category/@xml:id)[2]}">{$office-06//*[@xml:id = $data][2]}</keep>) 
return
    (: check if there are multilpe IDs :)
   if (count($office-06//*[@xml:id = $data]) = 1)
   (: unique ids are britney, leave em alone :)
   then ()
   (: see if the dupe is a top level child :)
   else if (data($n/../../tei:category/@xml:id)[1] = 'OFF06')
        then (update delete $n)
        else (update replace $n with <category sameAs="{concat('#', data($n/../../tei:category/@xml:id)[1])}"/>)
};  
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

declare %test:assertTrue function taxo:validate-office() {
(: there are duplicate xml:id not coaught by validation ??
these are related to left right offices create a fix-up function ? :)

for $docs in collection($config:target-office)
let $name := util:document-name($docs)
return
    validation:jing(doc($config:target-office || $name), $config:tei_all)
};



(: TIMING 202.2s :)
(
taxo:write-calendar($config:GANZHI_CODES//no:row, $config:DYNASTIES//no:row),
taxo:write-biblCat($config:TEXT_BIBLCAT_TYPES//no:row), 
taxo:write-office($config:OFFICE_TYPE_TREE//no:row)
)
