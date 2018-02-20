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


declare namespace output = "http://www.tei-c.org/ns/1.0";
declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $target-calendar := xmldb:create-collection($config:target-aemni, 'calendar');

declare function local:sexagenary($ganzhi as node()*) as item()* {
    (:~
 : local:sexagenary converts `GANZHI` data into categories. 
 : 
 : @param $ganzhi `c_ganzhi_code`
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

declare
%test:pending("validation as test")
function local:dynasties($dynasties as node()*, $nianhao as node()*) as item()* {
    (:~
 : local:dynasties converts `DYNASTIES`, and `NIANHAO` data into categories. 
 : 
 : @param $dynasties `c_dy`
 :
 : @return `<taxonomy xml:id="reign">...</taxonomy>` :)
    
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
                            let $dy_id := $dy/../no:c_dy
                            return
                                <category
                                    xml:id="{concat('D', $dy_id)}">
                                    <catDesc>
                                        <date
                                            from="{cal:isodate($dy/../no:c_start)}"
                                            to="{cal:isodate($dy/../no:c_end)}"/>
                                    </catDesc>
                                    <catDesc
                                        xml:lang="zh-Hant">{normalize-space($dy/../no:c_dynasty_chn)}</catDesc>
                                    <catDesc
                                        xml:lang="en">{normalize-space($dy/../no:c_dynasty)}</catDesc>
                                    {
                                        for $nh in $nianhao/no:c_dy[. = $dy_id]
                                        (:                            where $nh/no:c_dy = $dy_id:)
                                        return
                                            if ($nh/../no:c_nianhao_pin != '')
                                            then
                                                (<category
                                                    xml:id="{concat('R', $nh/../no:c_nianhao_id)}">
                                                    <catDesc>
                                                        <date
                                                            from="{cal:isodate($nh/../no:c_firstyear)}"
                                                            to="{cal:isodate($nh/../no:c_lastyear)}"/>
                                                    </catDesc>
                                                    <catDesc
                                                        xml:lang="zh-Hant">{normalize-space($nh/../no:c_nianhao_chn)}</catDesc>
                                                    <catDesc
                                                        xml:lang="zh-Latn-alalc97">{normalize-space($nh/../no:c_nianhao_pin)}</catDesc>
                                                </category>)
                                            else
                                                (<category
                                                    xml:id="{concat('R', $nh/../no:c_nianhao_id)}">
                                                    <catDesc>
                                                        <date
                                                            from="{cal:isodate($nh/../no:c_firstyear)}"
                                                            to="{cal:isodate($nh/../no:c_lastyear)}"/>
                                                    </catDesc>
                                                    <catDesc
                                                        xml:lang="zh-Hant">{normalize-space($nh/../no:c_nianhao_chn)}</catDesc>
                                                </category>)
                                    }
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

declare %private function local:write-calendar($sexa as item()*, $dyna as item()*, $nian as item()*) as item()* {
(:~
 : write the taxonomy containing the results of both local:sexagenary and cal:dynasties into db. :)
    
    (xmldb:store($config:target-calendar, $config:sexagen, local:sexagenary($sexa)),
    xmldb:store($config:target-calendar, $config:calendar, local:dynasties($dyna, $nian)))

};

declare %test:assertTrue function local:validate-sexagenary() {
    validation:jing(doc($config:target-calendar || $config:genre), $config:tei_all)
};

declare %test:assertTrue function local:validate-dynasties() {
    validation:jing(doc($config:target-calendar || $config:calendar), $config:tei_all)
};

(: TIMING 0.8s :)

(:local:write-calendar($config:GANZHI_CODES//no:row, $config:DYNASTIES//no:row, $config:NIAN_HAO//no:row):)

validation:jing(doc($config:target-calendar || $config:calendar), $config:tei_all)