xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
(:import module namespace functx="http://www.functx.com";:)

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare namespace pla="http://exist-db.org/apps/cbdb-data/place";

declare default element namespace "http://www.tei-c.org/ns/1.0";


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
    distinct-values(($ADDR_CODES//no:c_admin_type, $ADDRESSES//no:c_admin_type))
    
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


declare function pla:nest-places($data as node()*, $id as node(), $zh as node()?, $py as node()?) as item()*{

(: This function takes the $global:ADDR_CODES//no:rows plus the first $global:ADDR_BELONGS_DATA parent  
and tranlates them into tei:place.
This function is recursive to create a nested tree of place hierarchies via c_belongs_to.
This was neccessar because of duplicates in $global:ADDRESSES.
Where multiple identical c_addr_id's are present, we use the one covering the largest admin level.
For c_addr_ids only present in $global:ADDRESSES but not $global:ADDR_CODES we determine the identity of their 
corresponding entities in $global:ADDR_CODES and insert an empty tei:place element with @corresponds into the main
listPlace file. 

:)

 (: ADDRESSES                                               ADDR_CODES
 [c_addr_id] INTEGER,               x                   [c_addr_id] INTEGER PRIMARY KEY,         x
 [c_addr_cbd] CHAR(255),           d                         
 [c_name] CHAR(255),                p                    [c_name] CHAR(255),                        x  
 [c_name_chn] CHAR(255),           p                    [c_name_chn] CHAR(255),                   x
 [c_firstyear] INTEGER,            p                     [c_firstyear] INTEGER,                    x
 [c_lastyear] INTEGER,               p                   [c_lastyear] INTEGER,                     x
 [c_admin_type] CHAR(255),          p                   [c_admin_type] CHAR(255),                x
 [x_coord] FLOAT,                     p                   [x_coord] FLOAT,                           x
 [y_coord] FLOAT,                     p                   [y_coord] FLOAT,                           x
                                                             [CHGIS_PT_ID] INTEGER,                     x
                                                             [c_notes] CHAR,                            x
 [belongs1_ID] INTEGER,             x                      [c_alt_names] CHAR(255))                  x
 [belongs1_Name] CHAR(255),         d
 [belongs2_ID] INTEGER,              d   
 [belongs2_Name] CHAR(255),         d
 [belongs3_ID] INTEGER,             d    
 [belongs3_Name] CHAR(255),         d
 [belongs4_ID] INTEGER,             d
 [belongs4_Name] CHAR(255),         d
 [belongs5_ID] INTEGER,             d
 [belongs5_Name] CHAR(255))         d
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
count(empty($ADDRESSES//no:c_admin_type)) 
 = count(empty($ADDRESSES//no:c_firstyear)) 
 = count(empty($ADDRESSES//no:c_lastyear))
= 1 = TRUE (unkown)

similarly "_belongs" sources are all unkown
count($global:ADDR_BELONGS_DATA//no:c_source[. > 0]) = 0

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

- currently only patched places refer to their main entries via @corresp,
  add matching attributes to the main entities. 


:)

    let $belong := $global:ADDR_BELONGS_DATA//no:c_addr_id[. = $id]   
 
    
    return  
        global:validate-fragment(element place { attribute xml:id {concat('PL', $id/text())},
            if (empty(pla:fix-admin-types($id/../no:c_admin_type)))
            then ()
            else ( attribute type {pla:fix-admin-types($id/../no:c_admin_type)}),    
                        
            if (empty($belong/../no:c_source) or $belong/../no:c_source = 0) 
            then ()
            else ( attribute source {concat('#BIB', $belong/../no:c_source/text())}), 
            
            if (empty($zh))
            then ()
            else ( element placeName { attribute xml:lang {'zh-Hant'},
                    $zh/text()}),
            if (empty($py))
            then ()
            else ( element placeName { attribute xml:lang {'zh-Latn-alalc97'},
                    $py/text()}), 
            
            if (empty($id/../no:c_alt_names)) 
            then ()
            else ( element placeName { attribute type {'alias'}, 
                $id/../no:c_alt_names/text()}),
            
            if (empty($id/../no:c_firstyear) and empty($id/../no:c_lastyear) and empty($id/../x_coord))
            then ()
            else ( element location {
                if (empty($id/../no:c_firstyear))
                then ()
                else ( attribute from {cal:isodate($id/../no:c_firstyear)}),
                
                if (empty($id/../no:c_lastyear))
                then ()
                else ( attribute to {cal:isodate($id/../no:c_lastyear)}),
                    
                if (empty($id/../no:x_coord) or $id/../no:x_coord[. = 0])
                then ()
                else ( element geo {concat($id/../no:x_coord/text(), ' ', $id/../no:y_coord/text())})            
                }),        
            
            if (empty($id/../CHGIS_PT_ID)) 
            then ()
            else ( element idno { attribute type {'CHGIS'},
                        $id/../CHGIS_PT_ID/text()}),
                        
            if (empty($id/../no:c_notes)) 
            then ()
            else ( element note {$id/../no:c_notes/text()}),
                       
            if (empty($belong/../no:c_notes)) 
            then ()
            else ( element note {$belong/../no:c_notes/text()}),             
            
            if (exists($data//no:c_belongs_to[. = $id/text()]))
            then ( for $child in $data//no:c_belongs_to[. = $id/text()]
                    return 
                       pla:nest-places($data, $child/../no:c_addr_id, $child/../no:c_name_chn, $child/../no:c_name))
            else ()    
        
        }, 'place')          
       
};

declare function pla:patch-missing-addr($data as node()*) as node()*{
    
(: This function adds tei:places that are present in $global:ADDRESSES but not $global:ADDR_CODES.  
It expects $global:ADDRESSES//no:row s and insert either empty place elements with a matching @corresp attribute, 
or complete tei:place elements from pla:nest-places for elements not captured in the intial write operation.

We need to do this to make sure that every c_addr_id element present in CBDB can be found in listPlace.xml. 
:)
    for $n in $data
    let $corresp := min(data($global:ADDR_CODES//no:c_name_chn[. = $n/no:c_name_chn]/../no:c_addr_id))
    let $branch := if ($global:ADDR_CODES//no:c_addr_id[. = $n/no:belongs1_ID])
                     then (concat('PL', $n/no:belongs1_ID))
                     else if ($global:ADDR_CODES//no:c_addr_id[. = $n/no:belongs2_ID])
                           then (concat('PL', $n/no:belongs2_ID)) 
                           else if ($global:ADDR_CODES//no:c_addr_id[. = $n/no:belongs3_ID])
                                then (concat('PL', $n/no:belongs3_ID))
                                else if ($global:ADDR_CODES//no:c_addr_id[. = $n/no:belongs4_ID])
                                      then (concat('PL', $n/no:belongs4_ID))
                                      else if ($global:ADDR_CODES//no:c_addr_id[. = $n/no:belongs5_ID])
                                            then (concat('PL', $n/no:belongs5_ID))
                                            else (concat('PL', $corresp))
                                            
    let $listPlace := doc(concat($global:target, $global:place))
    
    where empty($global:ADDR_CODES//no:c_addr_id[. = $n/no:c_addr_id])
    order by $n/no:c_addr_id/number()
    
    return 
        if (empty($corresp))
        then (update insert pla:nest-places($n, $n/no:c_addr_id, $n/no:c_name_chn, $n/no:c_name) 
                       into $listPlace//*[@xml:id = $branch])
        else (update insert element place { attribute xml:id {concat('PL', $n/no:c_addr_id/text())}, 
                                attribute corresp{concat('#PL',$corresp)}}
                       into $listPlace//*[@xml:id = $branch])
                
}; 

let $data := <no:root>{
    for $n in $global:ADDR_CODES//no:row
     
    return 
    
    if (count($global:ADDR_BELONGS_DATA//no:c_addr_id[. = $n/no:c_addr_id]) > 1)
    then (<no:row>
            {$n/*}
            <no:c_belongs_to>{min(data($global:ADDR_BELONGS_DATA//no:c_addr_id[. = $n/no:c_addr_id]/../no:c_belongs_to))}</no:c_belongs_to>
           </no:row>)
    else (<no:row>
            {($n/*, $global:ADDR_BELONGS_DATA//no:c_addr_id[. = $n/no:c_addr_id]/../no:c_belongs_to)}
           </no:row>)}
</no:root>  





return
xmldb:store($global:target, $global:place,

<listPlace xmlns="http://www.tei-c.org/ns/1.0">{                        
    for $place in $data//no:c_addr_id[. > 0]
    
    where $place/../no:c_belongs_to = 0
    return
        pla:nest-places($data, $place, $place/../no:c_name_chn, $place/../no:c_name)}
</listPlace>)



(:pla:fix-admin-types('Dudufu'):)
(:local:patch-missing-addr($global:ADDRESSES//no:row):)