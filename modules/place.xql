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


declare function pla:address($addr as node()*) {

(: This function translates the ADDRESSES entities into TEI.:)

(: Based on this tests certain columns don't require aconditional check for empty() 
count(empty($ADDRESSES//c_admin_type)) 
 = count(empty($ADDRESSES//c_firstyear)) 
 = count(empty($ADDRESSES//c_lastyear))
= 1 = TRUE (unkown)

similarly belongs sources are all unkown
count($ADDR_BELONGS_DATA//c_source[. > 0])
:)


    for $place in $addr
    
    let $code := $global:ADDR_CODES//c_addr_id[. = $place]
    let $relation := $global:ADDR_BELONGS_DATA//c_addr_id[. = $place]    
    (:let $id-padding := string-length(string(max($ADDRESSES//c_addr_id))) +1  :)
    
    
    return  
        <place xml:id="{concat('PL', $place/../c_addr_id)}"
            type ="{ if (empty(pla:fix-admin-types($place/../c_admin_type)))
            then(pla:fix-admin-types($code/../c_admin_type))
            else (pla:fix-admin-types($place/../c_admin_type))
            }">
            <placeName xml:lang="zh-Hant">{$place/../c_name_chn/text()}</placeName>            
            <placeName xml:lang="zh-alac97">{$place/../c_name/text()}</placeName>            
                {
                if (empty($code/../c_alt_names)) 
                then ()
                else(<placeName type ="alias">{$code/../c_alt_names/text()}</placeName>)
                }
            {
            if (empty(cal:isodate($place/../c_firstyear)))
            then()
            else (<location from="{cal:isodate($place/../c_firstyear)}"
                        to="{cal:isodate($place/../c_lastyear)}">
                        {
                        if (empty($code/../x_coord) or $code/../x_coord = 0) 
                        then ()
                        else(<geo>{concat($code/../x_coord/text(), ' ',$code/../y_coord/text())}</geo>)
                        }
                   </location>)
            }            
            {
            if (empty($code/../CHGIS_PT_ID)) 
            then()
            else(<idno type="CHGIS">{$code/../CHGIS_PT_ID/text()}</idno>)
            }           
              {
              if (empty($code/../c_notes)) 
              then ()
              else(<note>{$code/../c_notes/text()}</note>)
              }
            {
            if (empty($relation/../c_notes)) 
            then ()
            else(<note>{$relation/../c_notes/text()}</note>)
            }
            {
            (:   !!! Check pointers to TEXT_DATA !!!  :)
            if (empty($relation/../c_source) or $relation/../c_source = 0) 
            then ()
            else(<bibl target="{concat('#', $relation/../c_source/text())}"/>)
            }
        </place>
};

let $address := xmldb:store($global:target, $global:place,
    <listPlace>
        {pla:address($global:ADDRESSES//c_addr_id[. > 0])}
    </listPlace>) 

for $nodes in doc($address)//place
let $id := substring-after(data($nodes/@xml:id), 'PL')
let $parent := $global:ADDR_BELONGS_DATA//c_addr_id[. = $id]/../c_belongs_to/text() 
let $parent-id := concat('PL', $parent)

where $parent > -1

return
if ($parent = 0) 
then ()
else (update insert $nodes into doc('/db/apps/cbdb-data/target/listPlace.xml')//place[@xml:id = $parent-id],
      update delete $nodes)



(:pla:fix-admin-types('Dudufu'):)
