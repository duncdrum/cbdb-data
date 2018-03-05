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
import module namespace app = "http://exist-db.org/apps/cbdb-data/templates" at "app.xql";

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

declare variable $target-calendar := xmldb:create-collection($config:target-aemni, 'calendar');
declare variable $wd-sparql := doc($config:app-root || "/src/sparql/multi-dy.xml");


declare %public function local:taxonomy-wrap($id as xs:string, $title as xs:string, $f as function(*), $args as array(*)) as element(TEI) {
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
        
            (:~
            : There are 5907 ids appearing in multiple locations 
            : @see local:fixup-office
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

declare %public function local:write-office($offices as item()*) as item()* {
(:
make sure that links from main files switch to full URI s (Hucker?)         [?]
and fix in main transforms                                                        [ ]
no note if contents equal 'alt'                                                  [ ]
find better way to avoid maxClauseCount error ?                                [x]
add ana=main to main entries? edit ODD no more type here                      [ ]
dedupe _type >> _code hack 11037                                                 [x]   
$type-rel has 2 instances of same ID see 11039 fix?                           [x]
much nicer find out what happened to 阿餐                                       [x]
fix old n="00" codes                                                              [ ]
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

for $n in $offices/no:c_parent_id[. = 0]/..
let $prefix := 'office-' || $n/no:c_office_type_node_id
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    local:taxonomy-wrap($prefix, 'Taxonomy of Imperial Bureaucracy', local:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF']))
};

declare %test:assertTrue function local:validate-office() {
(:there are duplicate xml:id not coaught by validation ??
these are related to left right offices create a fix-up function ?:)

for $docs in collection($config:target-office)
let $name := util:document-name($docs)
return
    validation:jing(doc($config:target-office || $name), $config:tei_all)
};

    
(:    validation:jing(doc(util:document-name($docs)), $config:tei_all):)
let $offices := $config:OFFICE_TYPE_TREE//no:row

for $n in $offices[1]
return
    local:write-office($config:OFFICE_TYPE_TREE//no:row)

(:let $codes := $config:OFFICE_CODES//no:row
let $type-rel := $config:OFFICE_CODE_TYPE_REL//no:row

for $n in $type-rel
return
   if (count(data($type-rel/no:c_office_tree_id)) > 1)
   then ($n)
   else ():)

(:let $offices := $config:OFFICE_TYPE_TREE//no:row

for $n in $offices[1]
return
    local:nest-categories($offices, $n/no:c_office_type_node_id, 'OFF'):)


(:WIP:)
(:return
    <root>{
            for $n in $type-rel/no:c_office_tree_id[string-length(.) = 2]
            let $count := count($type-rel/no:c_office_id[. = $n/../no:c_office_id])
            return
                if ($count > 1)
                then
                    (<id
                        c="{$count}">{$n/../no:c_office_id/text()} :
                        {
                            for $dupe in $type-rel/no:c_office_id[. = $n/../no:c_office_id][2]/../no:c_office_tree_id
                            return
                                $dupe/text()
                        }</id>)
                else
                    ()
        }</root>:)