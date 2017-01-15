xquery version "3.0";
import module namespace functx="http://www.functx.com";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";

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
return
deep-equal($test//place[4], $test//place[5])

