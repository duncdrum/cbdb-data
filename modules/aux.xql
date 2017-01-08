xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 

declare variable $YEAR_RANGE_CODES:= doc(concat($src, 'YEAR_RANGE_CODES.xml'));



declare function local:custodate ($dynasty as node()*, $reign as node()*,
    $year as xs:string?, $type as xs:string?) 
    as node()*{
(:this function takes chinese calendar dates ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. 

The normalized format takes DYNASTY//c_sort which is specific to CBDB,  
followed by the sequence of reigns determined by their position in cal_ZH.xml
followed by the Year number.D(\d*)-R(\d*)-(\d*)
:)

(:TODO
- getting to a somehwhat noramlized useful representation ofChinese Reign dates is tricky.
    inconsinsten pinyin for Nianhao creates ambigous and ugly dates.
- handle //c_dy[. = 0] stuff
:)

let $cal-ZH := doc(concat($target, 'cal_ZH.xml'))
let $cal-path := $cal-ZH/tei:taxonomy/tei:taxonomy/tei:category

let $dy := $DYNASTIES//c_dy[. = $dynasty/text()]
let $motto := count($cal-path/tei:category[@xml:id = concat('R', $reign/text())]/preceding-sibling::tei:category) +1

        
let $date-norm := string-join((concat('D', $dy/../c_sort), concat('R',$motto), concat('Y', $year)),'-')
        


let $date-orig := string-join(($dy/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reign/text()]/../c_nianhao_chn,
                    concat($year, '年')),'-')

return 
    element date { attribute datingMethod {'#chinTrad'}, 
        attribute calendar {'#chinTrad'},
        switch
            ($type)
                case 'notBefore'return attribute notBefore-custom {$date-norm}
                case 'notAfter' return attribute notAfter-custom {$date-norm}
                case 'from' return attribute from-custom {$date-norm}
                case 'to' return attribute to-custom {$date-norm}
                default return  attribute when-custom  {$date-norm},
                $date-orig                  
    }
};



 for $n in $NIAN_HAO//c_nianhao_id[. = 471]
 return
    local:custodate($n/../c_dy, $n, <year>3</year>, 'when')
    


