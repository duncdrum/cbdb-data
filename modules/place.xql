xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace pla="http://exist-db.org/apps/cbdb-data/place";
declare namespace output = "http://www.tei-c.org/ns/1.0";


(:place.xql reads the various basic entities for location type information 
    and creates a listPlace element for inclusion in the body element via xi:xinclude.
  to avoid confusion 'addresses' type data in CBDB is 'place' data in TEI, whereas CBDB's
  'place' is TEI's 'geo'.  
:)

(: TODO: 
    - in the future better translation from admin types into more precise TEI tags e.g. <country>
    - better CHGIS integragtion via <ref target="http://maps.cga.harvard.edu/tgaz/">TGAZ</ref>  
    - needs pointers once listBibl and sources are ready 
   
:)

declare function pla:fix-admin-types($adminType as xs:string?)  as xs:string* {
(:
let $types := 
    distinct-values(($ADDR_CODES//c_admin_type, $ADDRESSES//c_admin_type))
    
c_admin_type contains 225 (incl "unkown") distinct types which are not normalized.

This function normalizes these types by to lower case (-25) and more consistent use of whitespace (-4)
so we are left with only ~180. 

Greater consisitency in the use of white space could be achieved by extending
the switch statement below.

Neither TEI nor CBDB are particularly great at GIS. In the future this informartion should be pulled
from TGAZ and transformed into a consistent typology.


:)

let $lower := 
    for $n in $adminType
    return 
        lower-case($n) 
        
for $low in distinct-values($lower)
    return 
        switch($low)
            case 'banshidacheng' case 'banshi dachen' return 'banshidachen'
            case 'banshi zhangguan' return 'banshizhangguan'
            case 'bawan tong' return 'bawantong'
            case 'changguan' return 'zhangguan'
            case 'dao xingjun' return 'daoxingjun'
            case 'dependent kingdom' return 'dependent-kingdom'
            case 'dependent state' return 'dependent-state'
            case 'duhu fu' return 'duhufu'
            case 'hanguo (khanate)' return 'khanate'
            case 'independent state' return 'independent-state'
            case 'independent tribe' return'independent-tribe'
            case 'jiangjun xiaqu' return 'jiangjunxiaqu'
            case 'jun (zhou)' case 'jun commandery' return 'commandery'             
            case 'junmin anfushisi' return 'junminanfushisi'
            case 'junmin qianhusuo' return'junminqianhusuo'
            case 'junmin wanhufu' return'junminwanhufu'
            case 'junmin zongguanfu' return 'junminzongguanfu'
            case 'junmin`anfusi' return 'junminanfusi'
            case 'junminzhihuishishisi'  return 'junminzhihuishisi'
            case 'manyichangguansi' case 'manyi changguansi' case 'manyi zhangguansi' return 'manyizhangguansi'
            case 'qianhusuo (capital)' return 'qianhusuoJing'
            case 'shiqiaqu' case 'shixuiaqu' return 'shixiaqu'
            case 'shouyu qianhusuo' return 'shouyuqianhusuo'
            case 'suzheng lianfang si dao' return 'suzhenglianfangsidao'
            case 'tebie xingzhengqu' return 'tebiexingzhengqu'
            case "tribal federation" return "tribal-federation"
            case 'tributary state' return 'tributary-state'
            case 'wei (capital)' return 'weiJing'
            case 'xhangguansi' return 'zhangguansi'
            case 'xianm' return 'xian'
            case 'yushitai' case 'xing yushitai' return 'xingyushitai'
            case 'zhou(jun)' case 'zhou (jun)' return 'zhouJun'
            case '' case '[unknown]' return 'unkown'
        default return $low

};

declare function pla:merge-place-dupes ($places as node()*) as item()*{
(:this function takes the place nodes to be merged and writes them into an aux file:)
let $dupes := xmldb:store($global:target, 'place-lookup.xml',
    <listPlace>
        {for $place in $global:ADDRESSES//c_addr_id
         where count($global:ADDRESSES//c_addr_id[. = $place]) > 1
         return
            pla:address($place)}
    </listPlace>)
    
let $dedupes :=  <listPlace>
                        {for $dupe in $dupes/listPlace/place
                        let $id := data($dupe/@xml:id)                 
                        return
                            <place xml:id="{data($dupe/@xml:id)}">
                                {functx:distinct-deep($dupes//place[@xml:id = $id]/*)}
                            </place>}
                     </listPlace>

return
    xmldb:store($global:target, 'place-dupe.xml',
    <tei:listPLace>{functx:distinct-deep($dedupes//place)}</tei:listPLace>)
};

declare function pla:update-listPlace (){    

let $listPlace := doc(concat($global:target, $global:place))
let $dedupe := doc(concat($global:target, 'place-dedupe.xml'))

(:

dimitri's solution 
http://stackoverflow.com/questions/3875560/xquery-finding-duplciate-ids?rq=1

delete all dupes but the first

let $vSeq := $listPlace//tei:place[@xml:id = data($dedupe//tei:place/@xml:id)]
return
    update delete $vSeq[position() = index-of($vSeq, .)[. > 1]] 
    
    :)
    
let $vSeq := $listPlace//tei:place[@xml:id = data($dedupe//tei:place/@xml:id)]

for $n in $vSeq
let $m := $dedupe//tei:place[@xml:id = data($n/@xml:id)]



return
    (update delete $vSeq[position() = index-of($vSeq, .)[. > 1]] ), (update replace $n with $m)
    };

declare function pla:nest-places($data as node()*, $id as node(), $zh as node()?, $py as node()?) as node()*{

(: This function takes the $global:ADDR_CODES//rows plus the first $global:ADDR_BELONGS_DATA parent  
and tranlates them into tei:place.
This function is recursive to create a nested tree of place hierarchies via c_belongs_to.
This was neccessar to filter duplicates from $global:ADDRESSES, where multiple c_addr_id's 
are present. 

:)

 (: ADDRESSES                                               ADDR_CODES
 [c_addr_id] INTEGER,           x                          [c_addr_id] INTEGER PRIMARY KEY, 
 [c_addr_cbd] CHAR(255),        x                         
 [c_name] CHAR(255),                                       [c_name] CHAR(255), 
 [c_name_chn] CHAR(255),                                  [c_name_chn] CHAR(255), 
 [c_firstyear] INTEGER,                                   [c_firstyear] INTEGER,
 [c_lastyear] INTEGER,                                    [c_lastyear] INTEGER,
 [c_admin_type] CHAR(255),                                [c_admin_type] CHAR(255),
 [x_coord] FLOAT,                                          [x_coord] FLOAT,
 [y_coord] FLOAT,                                          [y_coord] FLOAT,
                                                             [CHGIS_PT_ID] INTEGER,
                                                             [c_notes] CHAR,
 [belongs1_ID] INTEGER,                                   [c_alt_names] CHAR(255))   
 [belongs1_Name] CHAR(255), 
 [belongs2_ID] INTEGER, 
 [belongs2_Name] CHAR(255), 
 [belongs3_ID] INTEGER, 
 [belongs3_Name] CHAR(255), 
 [belongs4_ID] INTEGER, 
 [belongs4_Name] CHAR(255), 
 [belongs5_ID] INTEGER, 
 [belongs5_Name] CHAR(255))
 :)
 
(: PLACE_CODES
[c_place_id] FLOAT, 
[c_place_1990] CHAR(50), 
[c_name] CHAR(50), 
[c_name_chn] CHAR(255), 
[x_coord] FLOAT, 
[y_coord] FLOAT, 
:)

(: Based on these tests certain columns don't require conditional checks for empty() 
count(empty($ADDRESSES//c_admin_type)) 
 = count(empty($ADDRESSES//c_firstyear)) 
 = count(empty($ADDRESSES//c_lastyear))
= 1 = TRUE (unkown)

similarly "_belongs" sources are all unkown
count($global:ADDR_BELONGS_DATA//c_source[. > 0]) = 0

Determining the joined time series for dupes is a hack:
inspecting the actual values shows, that the different time series
found in cbdb are encompassing each other e.g. addr_id 4342 has
<location from="1368" to="1643"/>
<location from="1522" to="1522"/>
<location from="1544" to="1544"> ...

which can be merged as:
<location from ="1368' to="1622"/>
                        
so min/max of the distinct values captures the data that is there 
(to be replaced by CHGIS soon). It will not capture breaks and impose
and artificial coninuity if there were an example such that: 
                        
<location from="1368" to="1443"/>
<location from="1522" to="1622"/>

it could NOT be merged as <location from ="1368' to="1622"/>
:)


(:TODO

- check how many $ids belongto 0, -1, or NULL A: ca. 600


:)

    let $belong := $global:ADDR_BELONGS_DATA//c_addr_id[. = $id]   
 
    
    return  
        element place { attribute xml:id {concat('PL', $id/text())},
            if (empty(pla:fix-admin-types($id/../c_admin_type)))
            then ()
            else ( attribute type {pla:fix-admin-types($id/../c_admin_type)}),    
                        
            if (empty($belong/../c_source) or $belong/../c_source = 0) 
            then ()
            else ( attribute source {concat('#BIB', $belong/../c_source/text())}), 
            
            if (empty($zh))
            then ()
            else ( element placeName { attribute xml:lang {'zh-Hant'},
                    $zh/text()}),
            if (empty($py))
            then ()
            else ( element placeName { attribute xml:lang {'zh-alalc97'},
                    $py/text()}), 
            
            if (empty($id/../c_alt_names)) 
            then ()
            else ( element placeName { attribute type {'alias'}, 
                $id/../c_alt_names/text()}),
            
            if (empty($id/../c_firstyear) and empty($id/../c_lastyear) and empty ($id/../x_coord))
            then ()
            else ( element location {
                if (empty($id/../c_firstyear))
                then ()
                else ( attribute from {cal:isodate($id/../c_firstyear)}),
                
                if (empty($id/../c_lastyear))
                then ()
                else ( attribute to {cal:isodate($id/../c_lastyear)}),
                    
                if (empty($id/../x_coord) or $id/../x_coord[. = 0])
                then ()
                else ( element geo {concat($id/../x_coord/text(), ' ', $id/../y_coord/text())})            
                }),        
            
            if (empty($id/../CHGIS_PT_ID)) 
            then ()
            else ( element idno { attribute type {'CHGIS'},
                        $id/../CHGIS_PT_ID/text()}),
                        
            if (empty($id/../c_notes)) 
            then ()
            else ( element note {$id/../c_notes/text()}),
                       
            if (empty($belong/../c_notes)) 
            then ()
            else ( element note {$belong/../c_notes/text()}),             
            
            if (exists($data//c_belongs_to[. = $id/text()]))
            then ( for $child in $data//c_belongs_to[. = $id/text()]
                    return 
                       pla:nest-places($data, $child/../c_addr_id, $child/../c_name_chn, $child/../c_name))
            else ()    
        
        }          
       
};


let $data := <root>{
    for $n in $global:ADDR_CODES//row
     
    return 
    
    if (count($global:ADDR_BELONGS_DATA//c_addr_id[. = $n/c_addr_id]) > 1)
    then (<row>
            {$n/*}
            <c_belongs_to>{min(data($global:ADDR_BELONGS_DATA//c_addr_id[. = $n/c_addr_id]/../c_belongs_to))}</c_belongs_to>
           </row>)
    else (<row>
            {($n/*, $global:ADDR_BELONGS_DATA//c_addr_id[. = $n/c_addr_id]/../c_belongs_to)}
           </row>)}
</root>  





return
xmldb:store($global:target, $global:place,

<listPlace>
    {for $place in $data//c_addr_id[. > 0]
    
    where $place/../c_belongs_to = 0
    return
        pla:nest-places($data, $place, $place/../c_name_chn, $place/../c_name)}
</listPlace>)



(:pla:fix-admin-types('Dudufu'):)
