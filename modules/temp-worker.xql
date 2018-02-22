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

declare function local:dynasties($dynasties as node()*, $nianhao as node()*) as item()* {
    (:~
 : taxo:dynasties converts `DYNASTIES`, and `NIANHAO` data into categories. 
 : The sparql part is awaiting a bug fix and therefore incomplete. 
 : TODO make sparql shine, with better query and dynamically pulled Qids
 :
 : @param $dynasties row from `DYNASTIES`
 : @param $nianhao row from `NIAN_HAO`
 :
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

};

declare %private function local:taxonomy-wrap($id as xs:string, $title as xs:string, $f as function(*)) as element(TEI) {
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
                        xml:id="{$id}">{util:eval($f)}</taxonomy>
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


declare %test:assertTrue function local:validate-dynasties() {
    validation:jing(doc($config:target-calendar || $config:calendar), $config:tei_all)
};

(: TIMING 0.8s :)
(:
let $dynasties := $config:DYNASTIES//no:row:)

(:local:taxonomy-wrap('reign', 'Chinese Dynastyc Reign Calendar', local:dynasties#2($config:DYNASTIES//no:row, $config:NIAN_HAO//no:row)):)


(:local:dynasties($config:DYNASTIES//no:row, $config:NIAN_HAO//no:row):)

(:taxo:write-calendar($config:GANZHI_CODES//no:row, $config:DYNASTIES//no:row, $config:NIAN_HAO//no:row):)
(:validation:jing-report(doc($config:target-calendar || $config:calendar), $config:tei_all):)