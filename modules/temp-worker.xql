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

declare %public function local:write-office($offices as item()*) as item()* {
(:
use app:write-and-split                                                           [x]
office does the same as genres, but 0.0.7 reversed the order of code and type, 
reconsider, starting with type seems better  (it is)                          [x] 
there is more then just one top level type for offices: 6                     [x]
reconsider the use of roleName and date inside the taxonomy                  [x] 
check what the new tang bureau table does and where it fits in (nothing)    [x]
make sure that links from main files switch to full URI s (Hucker?)          [?]
simplify office and genre id prefix (GEN, OFF)                                 [x]
and fix in main transforms                                                        [ ]
no note if contents equal 'alt'                                                  [ ]
tokenize alt-name onn ';' and iterate                                           [x]
avoid maxClauseCount error                                                       [x]
add ana=main to main entries? edit ODD no more type here                     [ ]
dedupe _type >> _code hack 11037                                                [x]   
$type-rel has 2 innstance of same ID see 11039 fix?                          [ ]
much nicer find out what happened to 阿餐                                       [ ]
fix old n="00" codes                                                               [ ]
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
(:for $n in $offices[1]:)
let $prefix := 'office-' || $n/no:c_office_type_node_id/text() 
return 
    xmldb:store($config:target-office, $prefix || '.xml',
    local:taxonomy-wrap($prefix, 'Taxonomy of Bureaucratic Offices', local:nest-categories#3, [$offices, $n/no:c_office_type_node_id, 'OFF']))

};

(:TODO since we are going to call write-and-split this will need to be fixed:)
declare %test:assertTrue function local:validate-office() {
(:there are a handful of duplicates related to left right offices create a fix-up function ?:)
    validation:jing(doc($config:target-classdecl || $config:office), $config:tei_all)
};


    local:write-office($config:OFFICE_TYPE_TREE//no:row)

(:    local:nest-categories($offices, $n/no:c_office_type_node_id, 'OFF'):)


(:WIP:)
