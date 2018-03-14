xquery version "3.1";

(:nest levels ??:)
declare function local:transform($el as item()*) as item()* {
    <category
        n="{$el/../@id}">
        {
            for $e in $el
            return
                typeswitch ($e)
                    case element(Title)
                        return
                            element catDesc {
                                $e/@*,
                                normalize-space($e)
                            }
                    case element(lvl)
                        return
                            ()
                    default
                        return
                            element desc {normalize-space($e)}
        }
    </category>

};

(:                            <catDesc
                                xml:lang="{$e/@xml:lang}">
                                {$e/text()}
                            </catDesc>:)

(:add titles ??:)
declare function local:make-tree($nodes as node()*) as node()* {
    for $n in $nodes/*
    return
        $n/Title
};

let $data := doc('MGOT.xml')
let $test :=
<root>
    <row
        id="1">
        <lvl
            xml:lang="zh-Hant"
            n="1">皇族宮廷類</lvl>
        <lvl
            xml:lang="en"
            n="1">Imperial Family and Royal Court</lvl>
        <lvl
            xml:lang="zh-Hant"
            n="2">帝后門</lvl>
        <lvl
            xml:lang="en"
            n="2">Emperors and Empresses</lvl>
        <lvl
            xml:lang="zh-Hant"
            n="3">帝</lvl>
        <lvl
            xml:lang="en"
            n="3">Emperor and Supreme Ruler</lvl>
        <Title
            xml:lang="zh-Hant">皇帝</Title>
        <Title
            xml:lang="zh-Latn-alalc97">huang di</Title>
        <Title
            xml:lang="en">Emperor</Title>
    </row>
    <row
        id="2">
        <lvl
            xml:lang="zh-Hant"
            n="1">皇族宮廷類</lvl>
        <lvl
            xml:lang="en"
            n="1">Imperial Family and Royal Court</lvl>
        <lvl
            xml:lang="zh-Hant"
            n="2">帝后門</lvl>
        <lvl
            xml:lang="en"
            n="2">Emperors and Empresses</lvl>
        <lvl
            xml:lang="zh-Hant"
            n="3">帝</lvl>
        <lvl
            xml:lang="en"
            n="3">Emperor and Supreme Ruler</lvl>
        <Title
            xml:lang="zh-Hant">太上皇帝</Title>
        <Title
            xml:lang="zh-Latn-alalc97">tai shang huang di</Title>
        <Title
            xml:lang="en">Emperor Emeritus</Title>
        <Title
            type="alt"
            xml:lang="zh-Hant">太上皇</Title>
        <Title
            type="alt"
            xml:lang="zh-Latn-alalc97">tai shang huang</Title>
    </row>
    <row
        id="21">
        <lvl
            xml:lang="zh-Hant"
            n="1">皇族宮廷類</lvl>
        <lvl
            xml:lang="en"
            n="1">Imperial Family and Royal Court</lvl>
        <lvl
            xml:lang="zh-Hant"
            n="2">皇太子與東宮門</lvl>
        <lvl
            xml:lang="en"
            n="2">Heir Apparent and Eastern Palace</lvl>
        <Title
            xml:lang="zh-Hant">皇太子</Title>
        <Title
            xml:lang="zh-Latn-alalc97">huang tai zi</Title>
        <Title
            xml:lang="en">Heir Apparent</Title>
    </row>
    <row
        id="851">
        <lvl
            xml:lang="zh-Hant"
            n="1">中央中樞官署類</lvl>
        <lvl
            xml:lang="en"
            n="1">The Central Government</lvl>
        <lvl
            xml:lang="zh-Hant"
            n="2">公師門</lvl>
        <lvl
            xml:lang="en"
            n="2">The Three Dukes and Three Solitaries</lvl>
        <Title
            xml:lang="zh-Hant">太師</Title>
        <Title
            xml:lang="zh-Latn-alalc97">tai shi</Title>
        <Title
            xml:lang="en">Grand Preceptor</Title>
    </row>
</root>

(:for $n in $test//row
let $depth := max(data($n/*/preceding-sibling::lvl/@n))
let $parent:= $n/*/preceding-sibling::lvl[@n = $depth]
let $child := $n/Title

group by $d := $n/lvl[@n='2']/text():)

return
    <TEI>
        <teiHeader
            xml:lang="en">
            <fileDesc>
                <titleStmt>
                    <title>Ming Government Official Titles in TEI</title>
                    <encoder>Duncan Paterson</encoder>
                </titleStmt>
                <publicationStmt>                    
                    <availability>
                        <licence
                            target="https://creativecommons.org/licenses/by-nc-sa/4.0/">cc-by-nc-sa
                            4.0</licence>
                    </availability>                    
                </publicationStmt>
                <sourceDesc>
                    <bibl>
                    <title xml:lang="zh">明代職官中英辭典</title>
                    <title xml:lang="en">Chinese-English Dictionary of Ming Government Official Titles</title>
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
                        <date when="2017-12-30">December 30, 2017</date>
                    </bibl>
                    <p>The contents of the born digital <ref
                            target="https://escholarship.org/uc/item/2bz3v185">source</ref> encoded in TEI for easy reference</p>
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
                                                    return
                                                        <category>
                                                            <catDesc
                                                                xml:lang="zh-Hant">{normalize-space($l3)}</catDesc>
                                                            <catDesc
                                                                xml:lang="en">{normalize-space($en)}</catDesc>
                                                            
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
    </TEI>
    
    
    
    (:    for $l3 at $p in distinct-values($test//lvl[@n = 3][@xml:lang = 'zh-Hant'])
    let $en := distinct-values($test//lvl[@n = 3][@xml:lang = 'en'])[$p]
    let $title := $test//lvl[last()][. = $en]
    
    return
        for $t in $title
        let $row := <item>{$test//Title[. = $t/../Title]}</item>
        return
            $row:)
    (: $test//lvl[last()]/@n:)
    
    (:element {$parent/name()} { attribute  xml:lang {$parent/@xml:lang},
        $parent/text(),
        $child
    }:)