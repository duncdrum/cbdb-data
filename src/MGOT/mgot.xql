xquery version "3.1";

declare variable $data := doc('MGOT.xml');
declare variable $out := doc('mgot-tei.xml');

import module namespace functx = "http://www.functx.com";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare function local:transform($el as item()*) as item()* {
    <category
        xml:id="{concat('MGOT', $el/../@id)}" n="{data($el/../@id)}">        
        {
            for $e in $el
            return
                typeswitch ($e)
                    case element(Title)
                        return
                            element catDesc {
                                $e/@*,
                                $e/node()
                            }
                    case element(lvl)
                        return
                            ()
                    case element(note)
                        return
                            ()
                    default
                        return
                            element catDesc {
                                attribute ana {'note'},
                                $e/@*,
                                $e/node()
                            }
        }
    </category>
};

declare function local:add-source() {
    for $n in $data//row//*
    return
        if (matches($n, 'per Da Ming Hui Dian, juan \d*'))
        then
            (update replace $n with element {$n/name()} {
                $n/@*,
                attribute source {concat('DMHD_', normalize-space(substring-after($n, 'juan ')))},
                $n/node()
            })
        else
            if (matches($n, 'per Ming Shi, juan \d*'))
            then
                (update replace $n with element {$n/name()} {
                    $n/@*,
                    attribute source {concat('ming_shi_', normalize-space(substring-after($n, 'juan ')))},
                    $n/node()
                })
            else
                ()
};

declare function local:replacing-replacers (){
    for $replacement in $data//row/*[matches(., '^Replaced by \p{Lo}+（?\p{Lo}*）?')]
    let $replacement-id := data($replacement/../@id)
    let $replacement-off := $replacement/../Title[1]/text()
    let $replaced-str := functx:get-matches($replacement, '\p{Lo}+（?\p{Lo}*）?')[2]
    let $match := $data//row/*[matches(., '^Replaced ' || $replacement-off)]
    let $loose := $data//row/Title[. = $replaced-str]
    let $replaced-id := data($match/../@id)
    let $replaced-off := $match/../Title[1]/text()
    let $count := count($match)
    
    return
        switch($count)
            case 0 return 
                if (exists($loose))
                then (update replace $replacement with element {$replacement/name()} {
                                            $replacement/@*,                                          
                       
                                            attribute corresp {for $j in $data//row/Title[. = $replaced-str]
                                                return
                                                    concat('#', $j/../@id)
                                            },
                                            $replacement/node()
                                        }
                    )
                else (for $q in $data//lvl[@n = 3][@xml:lang = "zh-Hant"]
                        return 
                            if (contains($q, substring($replaced-str, 1, 3)) and contains($replacement, $q/../Title[1]))
                            then (update replace $replacement with element {$replacement/name()} {
                                    $replacement/@*,
                                    attribute corresp {concat('#', $q/../@id)},
                                    $replacement/node()
                                })
                            else ())            

            case 1 return 
               update replace $replacement with element {$replacement/name()} {
                    $replacement/@*,
                    attribute corresp {concat('#', $replaced-id)},
                    $replacement/node()
                }
        default return
           update replace $replacement with element {$replacement/name()} {
                    $replacement/@*,
                    attribute corresp { for $i in $replaced-id
                        return
                            concat('#', $i)
                        },
                    $replacement/node()
                }
};
 
declare function local:refactor-note() {
let $move := for $n in $data//note
let $row := $n/../..
return
  update insert element note { $n/../@*, $n/node()} into $row

let $cleanup := for $n in $data//lvl/note
    return update delete $n

return
    ($move, $cleanup)
};

declare function local:dedupe-output() {
    for $n in $out//*[@ana = 'note'][@n = 3]
    let $ancestor := $n/../../catDesc
    return
        if ($ancestor[@ana = 'note'] eq $n)
        then (update delete $n)
        else (update insert $n following $ancestor[last()])
};



xmldb:store('/db/apps/cbdb-data/src/MGOT/', 'mgot-3-tei.xml',
  <TEI>
        <teiHeader xml:lang="en">
            <fileDesc>
                <titleStmt>
                    <title>Ming Government Official Titles in TEI</title>
                    <editor>Duncan Paterson</editor>
                </titleStmt>
                <publicationStmt>               
                    <availability>
                        <licence
                            target="https://creativecommons.org/licenses/by-nc-sa/4.0/">cc-by-nc-sa
                            4.0</licence>
                    </availability>
                    <ptr target="https://escholarship.org/uc/item/2bz3v185"/>
                </publicationStmt>
                <sourceDesc>
                    <bibl>
                        <title
                            xml:lang="zh">明代職官中英辭典</title>
                        <title
                            xml:lang="en">Chinese-English Dictionary of Ming Government Official Titles</title>
                        <author>
                            <persName
                                xml:lang="zh">張穎</persName>
                            <persName
                                xml:lang="en">Ying Zhang</persName>
                        </author>
                        <author>
                            <persName
                                xml:lang="zh">薛燕</persName>
                            <persName
                                xml:lang="en">Susan Xue</persName>
                        </author>
                        <author>
                            <persName
                                xml:lang="zh">薛昭慧</persName>
                            <persName
                                xml:lang="en">Zhaohui Xue</persName>
                        </author>
                        <author>
                            <persName
                                xml:lang="zh">倪莉</persName>
                            <persName
                                xml:lang="en">Li Ni</persName>
                        </author>
                        <publisher><orgName>UC Irvine</orgName></publisher>
                        <date
                            when="2017-12-30">December 30, 2017</date>
                    </bibl>                    
                </sourceDesc>
            </fileDesc>
            <encodingDesc>
                <classDecl>
                    <taxonomy
                        xml:id="OFF19">
                        {                            
                            for $l1 at $p in distinct-values($data//lvl[@n = 1][@xml:lang = 'zh-Hant'])
                            let $en := distinct-values($data//lvl[@n = 1][@xml:lang = 'en'])[$p]
                            let $child := $data//lvl[. = $l1]/../lvl[@n = 2]
                            return
                                <category>
                                    <catDesc
                                        xml:lang="zh-Hant">{normalize-space($l1)}</catDesc>
                                    <catDesc
                                        xml:lang="en">{normalize-space($en)}</catDesc>
                                    {
                                        for $l2 at $p in distinct-values($child[@xml:lang = 'zh-Hant'])
                                        let $en := distinct-values($child[@xml:lang = 'en'])[$p]
                                        let $title := $data//lvl[last()][. = $en]
                                        let $grand-child := $data//lvl[. = $l2]/../lvl[@n = 3]
                                        return
                                            <category>
                                                <catDesc
                                                    xml:lang="zh-Hant">{normalize-space($l2)}</catDesc>
                                                <catDesc
                                                    xml:lang="en">{normalize-space($en)}</catDesc>                                                                                                       
                                                
                                                {
                                                    for $t in $title
                                                    return
                                                        local:transform($t/../*)                                                
                                                }
                                                
                                                {
                                                    for $l3 at $p in distinct-values($grand-child[@xml:lang = 'zh-Hant'])
                                                    let $en := distinct-values($grand-child[@xml:lang = 'en'])[$p]
                                                    let $title := $data//lvl[last()][. = $en]
                                                    let $note := functx:distinct-deep($data//lvl[. = $l3]/../note)
                                                    
                                                    return
                                                        <category>
                                                            <catDesc
                                                                xml:lang="zh-Hant">{normalize-space($l3)}</catDesc>
                                                            <catDesc
                                                                xml:lang="en">{normalize-space($en)}</catDesc>
                                                                {$note}                                                            
                                                            {
                                                                for $t in $title
                                                                return
                                                                    local:transform($t/../*)                                                            
                                                            }                                                        
                                                        </category>
                                                }                                            
                                            </category>
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
    </TEI>)



