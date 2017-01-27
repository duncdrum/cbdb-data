xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="nowhere";
(:declare namespace output = "http://www.tei-c.org/ns/1.0";:)

declare function local:tei-name ($names as node()*) as node()* {

for $name in $names
return
    <person xmlns="http://www.tei-c.org/ns/1.0">
        <persName>{concat($name/no:fname, ' ', $name/no:lname)}</persName>
    </person>
};

declare function local:validate-fragment($frag as node()*, $loc as xs:string?) as node() {
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
      </teiHeader>
  <text>
      <body>       
         {
         switch ($loc)
         case 'person' return <listPerson ana="chunk"><listPerson ana="block">{$frag}</listPerson></listPerson>         
         default return (<p>some text here {data($frag)}</p>)
         }         
      </body>
  </text>
</TEI>

return
    validation:jing-report($mini, doc('../templates/tei/tei_all.rng'))

};
let $data :=
<no:data xmlns="nowhere">
    <fname>Mr.</fname>
    <lname>Big</lname>
</no:data>


return
   local:validate-fragment(local:tei-name($data), 'person')
(:    local:tei-name($data):)