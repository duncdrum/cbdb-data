xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $ADDRESSES:= doc(concat($src, 'ADDRESSES.xml')); 
declare variable $ADDR_BELONGS_DATA:= doc(concat($src, 'ADDR_BELONGS_DATA.xml')); 
declare variable $ADDR_CODES:= doc(concat($src, 'ADDR_CODES.xml')); 
declare variable $ADDR_PLACE_DATA:= doc(concat($src, 'ADDR_PLACE_DATA.xml')); 
declare variable $ADDR_XY:= doc(concat($src, 'ADDR_XY.xml')); 

declare variable $ASSOC_DATA:= doc(concat($src, 'ASSOC_DATA.xml')); 
declare variable $BIOG_ADDR_CODES:= doc(concat($src, 'BIOG_ADDR_CODES.xml')); 
declare variable $BIOG_ADDR_DATA:= doc(concat($src, 'BIOG_ADDR_DATA.xml'));
declare variable $BIOG_INST_DATA:= doc(concat($src, 'BIOG_INST_DATA.xml'));
declare variable $EVENTS_ADDR:= doc(concat($src, 'EVENTS_ADDR.xml')); 
declare variable $POSSESSION_ADDR:= doc(concat($src, 'POSSESSION_ADDR.xml')); 
declare variable $POSTED_TO_ADDR_DATA:= doc(concat($src, 'POSTED_TO_ADDR_DATA.xml')); 
declare variable $SOCIAL_INSTITUTION_ADDR:= doc(concat($src, 'SOCIAL_INSTITUTION_ADDR.xml')); 
declare variable $SOCIAL_INSTITUTION_ADDR_TYPES:= doc(concat($src, 'SOCIAL_INSTITUTION_ADDR_TYPES.xml'));

declare variable $PLACE_CODES:= doc(concat($src, 'PLACE_CODES.xml')); 
declare variable $COUNTRY_CODES:= doc(concat($src, 'COUNTRY_CODES.xml')); 

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

declare function local:isodate ($string as xs:string?)  as xs:string* {
(:see calendar.xql:)
     
    if (empty($string)) then ()
    else if (number($string) eq 0) then ('-0001')
    else if (starts-with($string, "-")) then (concat('-',(concat (string-join((for $i in (string-length(substring($string,2)) to 3) return '0'),'') , substring($string,2)))))
    else (concat (string-join((for $i in (string-length($string) to 3) return '0'),'') , $string))
};

declare function local:fix-admin-types($adminType as xs:string?)  as xs:string* {
(:
let $types := 
    distinct-values(($ADDR_CODES//c_admin_type, $ADDRESSES//c_admin_type, $ADDR_CODES//c_admin_type))
    
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

declare function local:address($addr as node()*) {

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
    
    let $code := $ADDR_CODES//c_addr_id[. = $place]
    let $relation := $ADDR_BELONGS_DATA//c_addr_id[. = $place]    
    (:let $id-padding := string-length(string(max($ADDRESSES//c_addr_id))) +1  :)
    
    
    return  
        <place xml:id="{concat('PL', $place/../c_addr_id)}"
            type ="{ if (empty(local:fix-admin-types($place/../c_admin_type)))
            then(local:fix-admin-types($code/../c_admin_type))
            else (local:fix-admin-types($place/../c_admin_type))
            }">            
            <placeName xml:lang="zh-alac97">{$place/../c_name/text()}</placeName>         
            <placeName xml:lang="zh-Hant">{$place/../c_name_chn/text()}</placeName>
                {
                if (empty($code/../c_alt_names)) 
                then ()
                else(<placeName type ="alias">{$code/../c_alt_names/text()}</placeName>)
                }
            {
            if (empty(local:isodate($place/../c_firstyear)))
            then()
            else (<location from="{local:isodate($place/../c_firstyear)}"
                        to="{local:isodate($place/../c_lastyear)}">
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

let $address := xmldb:store($target, 'listPlace.xml',
    <listPlace>
        {local:address($ADDRESSES//c_addr_id[. > 0])}
    </listPlace>) 

for $nodes in doc($address)//place
let $id := substring-after(data($nodes/@xml:id), 'PL')
let $parent := $ADDR_BELONGS_DATA//c_addr_id[. = $id]/../c_belongs_to/text() 
let $parent-id := concat('PL', $parent)

where $parent > -1

return
if ($parent = 0) 
then ()
else (update insert $nodes into doc('/db/apps/cbdb-data/target/listPlace.xml')//place[@xml:id = $parent-id],
      update delete $nodes)



(:local:fix-admin-types('Dudufu'):)
