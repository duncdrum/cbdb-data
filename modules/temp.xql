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



declare function local:custo-date-point (
    $dynasty as node()*, 
    $reign as node()*,
    $year as xs:string*, 
    $type as xs:string?) as node()*{

(:This function takes chinese calendar date points ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. 

The normalized format takes DYNASTY//c_sort which is specific to CBDB,  
followed by the sequence of reigns determined by their position in cal_ZH.xml
followed by the Year number.D(\d*)-R(\d*)-(\d*)
:)

(:TODO
- getting to a somehwhat noramlized useful representation ofChinese Reign dates is tricky.
    inconsinsten pinyin for Nianhao creates ambigous and ugly dates.
- handle //c_dy[. = 0] stuff
- add @period with #d42 #R123
- find a way to prevent empty attributes more and better logic FTW
- If only a dynasty is known lets hear it,
the others are dropped since only a year or nianhao is of little information value. 
:)

let $cal-ZH := doc(concat($target, 'cal_ZH.xml'))
let $cal-path := $cal-ZH/tei:taxonomy/tei:taxonomy/tei:category

let $dy := $DYNASTIES//c_dy[. = $dynasty/text()]
let $motto := count($cal-path/tei:category[@xml:id = concat('R', $reign/text())]/preceding-sibling::tei:category) +1

        
let $date-norm := string-join((concat('D', $dy/../c_sort), concat('R',$motto), concat('Y', $year)),'-')
        


let $date-orig := string-join(($dy/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reign/text()]/../c_nianhao_chn,
                    concat($year, '年')),'-')


(:$type has two basic values
defaults to when
S/E = start / end
c/u for certain/uncertain
:)
           

return 
    element date { attribute datingMethod {'#chinTrad'}, 
        attribute calendar {'#chinTrad'},
        switch
            ($type)
                case 'uStart'return attribute notBefore-custom {$date-norm}
                case 'uEnd' return attribute notAfter-custom {$date-norm}
                case 'Start' return attribute from-custom {$date-norm}
                case 'End' return attribute to-custom {$date-norm}
                default return  attribute when-custom  {$date-norm},
                $date-orig                  
    }
};

declare function local:custo-date-range (
    $dy-start as node()*, $dy-end as node()*,
    $reg-start as node()*, $reg-end as node()*, 
    $year-start as xs:string*, $year-end as xs:string*, 
    $type as xs:string?) as node()*{

(:this function takes chinese calendar date ranges ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. :)

let $cal-ZH := doc(concat($target, 'cal_ZH.xml'))
let $cal-path := $cal-ZH/tei:taxonomy/tei:taxonomy/tei:category

let $DS := $DYNASTIES//c_dy[. = $dy-start/text()]
let $DE := $DYNASTIES//c_dy[. = $dy-end/text()]

let $RS := count($cal-path/tei:category[@xml:id = concat('R',  $reg-start/text())]/preceding-sibling::tei:category) +1
let $RE := count($cal-path/tei:category[@xml:id = concat('R',  $reg-end/text())]/preceding-sibling::tei:category) +1

        
let $start-norm := string-join((concat('D', $DS/../c_sort), concat('R',$RS), concat('Y', $year-start)),'-')
let $end-norm := string-join((concat('D', $DE/../c_sort), concat('R',$RE), concat('Y', $year-end)),'-')       


                  
let $start-orig := string-join(($DS/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reg-start/text()]/../c_nianhao_chn,
                    concat($year-start, '年')),'-')  
                    
let $end-orig := string-join(($DE/../c_dynasty_chn, 
                    $NIAN_HAO//c_nianhao_id[. = $reg-end/text()]/../c_nianhao_chn,
                    concat($year-end, '年')),'-')                 
                    
(:$type 
defaults to certain dates = from/when
'uRange' returns uncertain date-ranges

:)                    

return     
        switch
            ($type)
                case 'uRange'return element date { attribute datingMethod {'#chinTrad'}, 
                                            attribute calendar {'#chinTrad'},
                                            attribute notBefore-custom {$start-norm},
                                       attribute notAfter-custom {$end-norm},
                                       concat($start-orig, ' ',$end-orig)                 
                                        }
                default return element date { attribute datingMethod {'#chinTrad'}, 
                                            attribute calendar {'#chinTrad'}, 
                                        attribute from-custom {$start-norm}, 
                                        attribute to-custom  {$end-norm},
                                    concat($start-orig, ' ',$end-orig)                 
                                    }
};

 for $n in $NIAN_HAO//c_nianhao_id[. = 471]
 return
    (:local:custo-date-point($n/../c_dy, $n, <year>4</year>, 'P'):)
    local:custo-date-range($n/../c_dy, $n/../c_dy, $n, $n, <year>3</year>, <year>7</year>, 'uRange')
    


