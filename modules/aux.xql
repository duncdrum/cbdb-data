xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace no="nowhere";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare namespace output = "http://www.tei-c.org/ns/1.0";

(:declare default element namespace "http://www.tei-c.org/ns/1.0";:)

(:Aux.xql contains helper functions mostly for cleaning data and constructing functions.:)


declare function local:table-variables($f as node()*) as xs:string {

(:construct a variable declaration for each file in the collection:)
for $f in collection($global:src)
let $n := substring-after(base-uri($f), $global:src)
order by $n

return
     'declare variable' || ' $' || string($n) || ' := doc(concat($src, ' || "'" ||string($n) || "'));"
};

declare function local:write-chunk-includes($num as xs:integer?) as item()*{
(:This function inserts xinclude statemtns into the main TEI file for each chunk's list.xml file. 
As such $ipad, $num, and the return string depend on the main write operation in biographies.xql.
:)

for $i in 1 to $num
let $ipad := functx:pad-integer-to-length($i, 2)

return
    update insert
        <xi:include href="{concat('listPerson/chunk-', $ipad, '/list-', $i, '.xml')}" parse="xml"/>
    into doc(concat($global:target, $global:main))//tei:body
};
(:local:write-chunk-includes(37):)

declare function local:upgrade-contents($nodes as node()*) as node()* {

(: !!! WARNING !!! Handle with monumental care !!!!

This function performs an inplace update off all person records. 
It expects $global:BIOG_MAIN//no:c_personid s. 
It is handy for patching large number of records. 
Using the structural index in the return clause is crucial for performance.
:)

for $n in $nodes
return
 update value collection(concat($global:target, 'listPerson/'))//person[id(concat('BIO', $n))] 
 with biog:biog($n)/*

(:update value doc('/db/apps/cbdb-data/samples/test.xml')//listPlace with biog:biog($n)/*:)

};
(:local:upgrade-contents($global:BIOG_MAIN//no:c_personid[. > 0][. < 2]):)


declare function local:validate-fragment($frag as node()*, $loc as xs:string?) as node() {

(: This function validates $frag by inserting it into a minimal TEI template. 

This function cannot guarante that the final document is valid, 
but it can catch validation errors produced by other function early on.
This way we can minimize the number of validations necessary to catch errors.  

Especially usefull when combined with try-catch clauses:
Test expr:

biog:biog($global:BIOG_MAIN//no:c_personid[. = 12908])
bib:bibliography($global:TEXT_CODES//no:c_textid[. = 2031])

:)
let $mini := 
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
      <fileDesc>
         <titleStmt>
            <title>cbdbTEI-mini</title>
         </titleStmt>
         <publicationStmt>
            <p>testing ouput of individual functions using this mini tei document </p>
         </publicationStmt>
         <sourceDesc>
            <p>cannot replace proper validation of final output</p>
         </sourceDesc>
      </fileDesc>
      <encodingDesc>
         <classDecl>
            {if ($loc = 'category')
             then (<taxonomy>{$frag}</taxonomy>)
             else (<taxonomy><category><catDesc>some category</catDesc></category></taxonomy>)}
         </classDecl>
            {if ($loc = 'charDecl')
            then ($frag)
            else (<charDecl><glyph><mapping>⿸虍⿻夂丷⿱目</mapping></glyph></charDecl>)}        
      </encodingDesc>
  </teiHeader>
  <text>
      <body>       
         {
         switch ($loc)
         case 'person' return <listPerson ana="chunk"><listPerson ana="block">{$frag}</listPerson></listPerson>
         case 'org' return <listOrg>{$frag}</listOrg>
         case 'place' return <listPlace>{$frag}</listPlace>
         case 'bibl' return <listBibl>{$frag}</listBibl>
         default return (<p>some text here {data($frag)}</p>)
         }         
      </body>
  </text>
</TEI>

return 
    validation:jing-report($mini, doc('../templates/tei/tei_all.rng'))
};

local:validate-fragment(bib:bibliography($global:TEXT_CODES//no:c_textid[. = 2031]), 'bibl')
    

