xquery version "3.0";

(:~
: place.xql reads the various basic entities for location type information 
: and creates a listPlace element for inclusion in the body element via xInclude.
: to avoid confusion 'addresses' type data in *CBDB* is 'place' data in TEI, whereas CBDB's
: 'place' is TEI's 'geo'.
: 
: This data should soon be replaced with data from *China Historical GIS*
: 
: @author Duncan Paterson
: @version 0.7
:
: @see http://maps.cga.harvard.edu/tgaz/
: 
: @return listPlace.xml:)

module namespace pla="http://exist-db.org/apps/cbdb-data/place";

(:import module namespace functx="http://www.functx.com";:)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare default element namespace "http://www.tei-c.org/ns/1.0";


declare 
    %test:args("Aaa")
    %test:assertEquals("aaa")
function pla:fix-admin-types ($adminType as xs:string?)  as xs:string* {
(:~
: There are 225 distinct types of administrative units in CBDB, 
: however these contain many duplicates due to inconsistent spelling. 
: Furthermore, white-spaces prevent the existing types from becoming xml attribute values. 
: Hence this function normalizes and concats the spelling of admin types without modifying the source.
:
: @param $adminType is a ``c_admin_type``
: @return normalized and deduped string:)

(:make everything lower case:)
let $lower := 
    for $n in $adminType
    return 
        lower-case($n) 

(:take the lower case forms, and merge duplicates :)
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


declare 
    %test:pending('$global:ADDR_CODES//no:c_addr_id[. = 4342]')
    function pla:nest-places ($data as node()*, $id as node(), $zh as node()?, $py as node()?, $mode as xs:string?) as item()*{

(:~  
: pla:nest-places recursively reads rows from ADDR_CODES and the first ADDR_BELONGS_DATA parent, to generate place elements.                                            
:
: This leaves duplicate ids between here and ADDRESSES.
: Where multiple identical c_addr_id's are present, we use the one covering the largest admin level.
:
: All cases of overlapping dates for location data can actually be resolved to min/max.
:
: @param $data is ADDR_CODES row elements
: @param $id is a ``c_addr_id``
: @param $zh placeName in Chinese
: @param $en placeName in English
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
:
: @return nested ``<place xml:id="PL...">...</place>``:)

(:
<location from="1368" to="1643"/>
<location from="1522" to="1522"/>
<location from="1544" to="1544"> --> <location from ="1368' to="1622"/>
:)

    let $belong := $global:ADDR_BELONGS_DATA//no:c_addr_id[. = $id]   
    let $output :=   
        element place { attribute xml:id {concat('PL', $id/text())},
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
            
            if (empty($id/../no:CHGIS_PT_ID)) 
            then ()
            else ( element idno { attribute type {'CHGIS'},
                        $id/../no:CHGIS_PT_ID/text()}),
                        
            if (empty($id/../no:c_notes)) 
            then ()
            else ( element note {$id/../no:c_notes/text()}),
                       
            if (empty($belong/../no:c_notes)) 
            then ()
            else ( element note {$belong/../no:c_notes/text()}),             
            
            if (exists($data//no:c_belongs_to[. = $id/text()]))
            then ( for $child in $data//no:c_belongs_to[. = $id/text()]
                    return 
                       pla:nest-places($data, $child/../no:c_addr_id, $child/../no:c_name_chn, $child/../no:c_name, ''))
            else ()            
        }
return 
    switch($mode)
        case 'v' return global:validate-fragment($output, 'place')
        case 'd' return global:validate-fragment($output, 'place')[1]
    default return $output       
       
};

declare function pla:patch-missing-addr ($data as node()*) as node()*{
    
(:~ 
: pla:patch-missing-addr makes sure that every c_addr_id from CBDB is present in listPlace.xml .
:
: It does so by inserting empty places present in ADDRESSES but not ADDR_CODES, using a @corresp attribute, 
: or complete place elements where no correspondence can be established.
:
: places are inserted at the highest discernable level of hierarchy. 
: 
: @param $data row elements from ADDRESSES table.
: @return ``<place>...</place>``:)

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
        then (update insert pla:nest-places($n, $n/no:c_addr_id, $n/no:c_name_chn, $n/no:c_name, '') 
                       into $listPlace//*[@xml:id = $branch])
        else (update insert element place { attribute xml:id {concat('PL', $n/no:c_addr_id/text())}, 
                                attribute corresp{concat('#PL',$corresp)}}
                       into $listPlace//*[@xml:id = $branch])
                
}; 

declare %private function pla:write ($item as item()*) as item()* {
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

(:~ first run store ... :)
return
xmldb:store($global:target, $global:place,

<listPlace xmlns="http://www.tei-c.org/ns/1.0">{                        
    for $place in $data//no:c_addr_id[. > 0]
    
    where $place/../no:c_belongs_to = 0
    return
        pla:nest-places($data, $place, $place/../no:c_name_chn, $place/../no:c_name, '')}
</listPlace>)
};

(:~ then uncomment and run the following :)
(:pla:patch-missing-addr($global:ADDRESSES//no:row):)