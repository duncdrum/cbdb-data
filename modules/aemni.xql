xquery version "3.1";

(:~
: aemni working module.
: Replace local with name of target module
:
: @author Duncan Paterson
: @version 0.8.0
:)
import module namespace functx = "http://www.functx.com";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
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

(:~
: Because of the large number (>370k) of individuals
: the write operation of biographies.xql is slightly more complex. 
: Instead of putting its data into a single file or collection, 
: it creates a single listPerson directory inside the target folder, 
: which is populated by further subdirectories and ultimately the person records. 
:
: Currently, cbdbTEI.xml includes links to 37 listPerson files 
: covering chunks of $chunk-size persons each (10k).  
:
: "chunk" collections contain a single list.xml file and $block-size (50) sub-collections. 
: This file contains xInclude statements to 1 listPerson.xml file per "block" sub-collection.
: Each block contains a single listPerson.xml file on the same level as the individual
: $ppl-per-block (200) person records .

: @param $test set to c_personid that requires further testing
: @param $src-id all c_personid sgreater then 0 (unkown)
: @param $count how many c_personids there are

: @param $chunk-size determines the sum of person records within the top level directories, 
:    each contains subdirectories and a single list-X.xml file.
: @param $block-size determines the number of subdirectories per chunk.
: @param $ppl-per-block the number of person records per block
:
: @return Files and Folders for person data:
:    *   Directories:
:        *   creates nested directories listPerson, chunk, and block using the respective parameters.
:    *   Files:
:        *   creates list-X.xml and listPerson.xml files that include xInclude statements linking individual person records back to the main tei file. 
:        *   populates the previously generated directories with individual person records by calling biog:biog.    
:        *   Error reports from failed write attempts, as well as validations errors will be stored in the reports directory.:)


(:5k item per chunk, 250 items per block, 20 blocks per chunk:)

declare function local:pad($num as xs:integer) as xs:integer {
string-length($num) +2
};

declare function local:find-last-dir ($i as xs:positiveInteger, $j as xs:positiveInteger){

if ($i mod $j = 0)
then ($i idiv $j )
else ($i idiv $j + 1)

};

declare function local:write-scaffold ($items as item()*, 
    $l1-name as xs:string,
    $l2-num as xs:positiveInteger, 
    $l3-item-num as xs:positiveInteger) as item()* {
    
let $count := count($items)
let $l2-count := local:find-last-dir($count, $l2-num)
let $block := local:find-last-dir($l2-count, $l3-item-num)

let $l1:= xmldb:create-collection($config:target-aemni,$l1-name)


for $i in 1 to local:find-last-dir($count, $l2-num)   
let $l2 := xmldb:create-collection($l1,
    'chunk-' || functx:pad-integer-to-length($i, local:pad($l2-num)))    

for $j in subsequence($items, ($i - 1 )* $block, $block)
return     
    xmldb:create-collection($l2, 
    'block-' || functx:pad-integer-to-length($j, local:pad($block)))

  
};


(:replace for loops for intermediate file swith call to xmldb:xcollection:)


declare function local:write-data ($item as item()*, $transform as function(*), $item-num as xs:integer) {

for $individual at $pos in subsequence($items, ($pos - 1) * $item-num, $item-num)
let $person := $transform($individual, 'n') 
let $id := data($person/@xml:id)
let $id-num := substring-after($id, 'BIO')

let $file-name := 
    'cbdb-' || functx:pad-integer-to-length($id-num, local:pad($id-num)) || '.xml'
return
    try {xmldb:store($collection, $file-name, $person)}
                    
    catch * {xmldb:store($collection, 'error.xml', 
             <error>Caught error {$err:code}: {$err:description}.  Data: {$err:value}.</error>)}
};

(:declare function local:write-and-split ($src-id as item()*, 
    $tei-name as xs:string, 
    $tei-list as xs:string, 
    $chunk-size as xs:integer, 
    $block-size as xs:integer, 
    $el-p-block as xs:integer, 
    $transform as function) as item()* {
    
let $count := count($src-id)
(\:switch to proper target :\)
let $dir := $config:target-aemni || $tei-list
let $inter-file := $tei-list || '.xml'

for $i in 1 to $count idiv $chunk-size + 1 
let $chunk := xmldb:create-collection($dir, 
    'chunk-' || functx:pad-integer-to-length($i, 2))
  

for $j in subsequence($src-id, ($i - 1) * $block-size, $block-size)
let $collection := xmldb:create-collection($chunk, 
    'block-' || functx:pad-integer-to-length($j, 4))    
    

for $individual in subsequence($src-id, ($j - 1) * $el-p-block, $el-p-block)
let $person := $transform($individual, 'n') 
let $file-name := 
    'cbdb-' || functx:pad-integer-to-length(substring-after(data($person/@xml:id), 'BIO'), 7) || '.xml'

return 
    try {(xmldb:store($collection, $file-name, $person), 

         xmldb:store($collection, $inter-file, 
            <listPerson>{
                    for $files in collection($collection)
                    let $n := functx:substring-after-last(base-uri($files), '/')
                    where $n != $inter-file
                    order by $n
                    return 
                        <xi:include href="{$n}" parse="xml"/>}
                    </listPerson>), 
            
        xmldb:store($chunk, concat('list-', $i, '.xml'), 
            <listPerson>{                
                    for $lists in collection($chunk)
                    let $m := functx:substring-after-last(base-uri($lists), '/') 
                    where $m  = $inter-file
                    order by base-uri($lists)
                    return
                        <xi:include href="{substring-after(base-uri($lists), 
                            concat('/chunk-', functx:pad-integer-to-length($i, 2), '/'))}" xpointer="{data($person/@xml:id)}" parse="xml"/>}
                    </listPerson>))}
                    
    catch * {xmldb:store($collection, 'error.xml', 
             <error>Caught error {$err:code}: {$err:description}.  Data: {$err:value}.</error>)}
};:)

let $test := element root {
    for $i in 1 to 500
    return
        element item {attribute xml:id {'i' || $i}, 
        $i}
}
let $full := count($config:BIOG_MAIN//no:c_personid[. > 0])

(:for $item in subsequence($test//item, $j * :)
return

(:    functx:pad-integer-to-length(33 idiv 5, 3):)
(:local:find-last-dir(15,5):)
 local:write-scaffold($test//item, 'test', 15, 5)
(:$full:)
(:local:pad(3):)
(:    local:write-and-split($test, 'person', 'listPerson', 10000,50,200):)