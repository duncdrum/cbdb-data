xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";


import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";
declare namespace xi="http://www.w3.org/2001/XInclude";

(:for $place in $global:ADDRESSES//c_addr_id

where count($global:ADDRESSES//c_addr_id[. = $place]) > 1


return
   pla:address($place):)
   
(:   functx:distinct-deep(pla:address($global:ADDRESSES//c_addr_id[. =4342])):)


let $test :=
    <listPlace>
       <place xml:id="PL303533" type="yiweisi">
           <placeName xml:lang="zh-alac97">Xiangfu Yiwei si</placeName>
           <placeName xml:lang="zh-Hant">襄府儀衛司</placeName>
           <placeName type="alias">襄府儀衛;襄府護衛</placeName>
           <location from="1467" to="1643"/>
       </place>
       <place xml:id="PL303534" type="yiweisi">
           <placeName xml:lang="zh-alac97">Xingfu Yiwei si</placeName>
           <placeName xml:lang="zh-Hant">興府儀衛司</placeName>
           <placeName type="alias">興府儀衛;興府護衛</placeName>
           <location from="1467" to="1643"/>
       </place>
       <place xml:id="PL303534" type="yiweisi">
           <placeName xml:lang="zh-alac97">Xingfu Yiwei si</placeName>
           <placeName xml:lang="zh-Hant">興府儀衛司</placeName>
           <placeName type="alias">興府儀衛;興府護衛</placeName>
           <location from="1467" to="1643"/>
       </place>
       <place xml:id="PL303631" type="xian">
           <placeName xml:lang="zh-alac97">Longchang</placeName>
           <placeName xml:lang="zh-Hant">隆昌</placeName>
           <location from="1368" to="1643"/>
       </place>
       <place xml:id="PL303631" type="xian">
           <placeName xml:lang="zh-alac97">Longchang</placeName>
           <placeName xml:lang="zh-Hant">隆昌</placeName>
           <location from="1622" to="1643"/>
       </place>
    </listPlace>
    
(:for $place in $test//place
where count($place/@xml:id) :)
(:return
deep-equal($test//place[4], $test//place[5]):)

(:Because of the large number (>370k) of individuals
the write operatoin of biographies.xql is slighlty more complex. 
Instead of putting its data into a single file or collection, collections. 

bdbTEI.xml includes links to 37 listPerson files covering chunks of 10k persons each.  

"block" collections contain a single listPerson.xml file and further subcollectoins. 
This files contains xi:include statments to 10 further listPerson.xml files 
within its subcollections. 
Subcollections contain a single listPerson.xml file on the same level as the 
1k person records records.
:)
let $data := $global:BIOG_MAIN//c_personid[. > 0][. < 214]
let $count := count($data)
let $chunk-size := 100

for $i in 1 to $count idiv $chunk-size + 1
let $collection := xmldb:create-collection("/db/apps/cbdb-data/target/test", concat('block', functx:pad-integer-to-length($i, 3)))

for $individual in subsequence($data, ($i - 1) * $chunk-size, $chunk-size)
let $person := biog:biog($individual)
let $file-name := concat('cbdb-', functx:pad-integer-to-length(substring-after(data($person//@xml:id), 'BIO'), 7), '.xml')

(:let $listBlock := xmldb:store($collection, 'listPerson.xml', <tei:listPerson>
                        {for $files in collection($collection)
                        let $n := functx:substring-after-last(base-uri($files), '/')
                        where $n != 'listPerson.xml'
                        order by $n
                         return 
                            <xi:include href="{$n}" parse="xml"/>}
                        </tei:listPerson>):)

return (xmldb:store($collection, $file-name, $person), 
         xmldb:store($collection, 'listPerson.xml', 
            <tei:listPerson>
                {for $files in collection($collection)
                let $n := functx:substring-after-last(base-uri($files), '/')
                where $n != 'listPerson.xml'
                order by $n
                return 
                    <xi:include href="{$n}" parse="xml"/>}
            </tei:listPerson>))

 

