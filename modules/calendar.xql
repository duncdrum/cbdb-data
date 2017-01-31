xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
(:import module namespace functx="http://www.functx.com";:)
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace cal="http://exist-db.org/apps/cbdb-data/calendar";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $cal:ZH := doc(concat($global:target, $global:calendar));
declare variable $cal:path := $cal:ZH/taxonomy/taxonomy/category;


(:calendar.xql reads the calendar aux tables (GANZHI, DYNASTIES, NIANHAO) 
    and creates a taxonomy element for inculsion in the teiHeader via xi:xinclude.
    The taxonomy consists of two elements one for the sexagenarycycle, 
    and one nested taxonomy for reign-titles and dynasties.
    We are dropping the c_sort value for dynasties since sequential sorting
    is implicit in the data structure
:)

(:TODO:
 - friggin YEAR_RANGE_CODES.xml
 - many nianhaos aren't transliterated hence $NH-py
 - DYNASTIES contains both translations and transliterations:
     e.g. 'NanBei Chao' but 'Later Shu (10 states)'  
   more normalization *yay*
 - make 10states a @type ?  
:)


declare function cal:isodate ($string as xs:string?)  as xs:string* {

(:This function returns proper xs:gYear type values, "0000", 4 digits, with leading "-" for BCE dates
   <a>-1234</a>    ----------> <gYear>-1234</gYear>
   <b/>    ------------------> <gYear/>
   <c>1911</c> --------------> <gYear>1911</gYear>
   <d>786</d>  --------------> <gYear>0786</gYear>
   
   according to <ref target="http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.datable.w3c.html"/>
   "0000" should be "-0001" in TEI.
   
:)
        
    if (empty($string)) then ()
    else if (number($string) eq 0) then ('-0001')
    else if (starts-with($string, "-")) then (concat('-',(concat (string-join((for $i in (string-length(substring($string,2)) to 3) return '0'),'') , substring($string,2)))))
    else (concat (string-join((for $i in (string-length($string) to 3) return '0'),'') , $string))
};

declare function cal:sqldate ($timestamp as xs:string?)  as xs:string* {
concat(substring($timestamp, 1, 4), '-', substring($timestamp, 5, 2), '-', substring($timestamp, 7, 2)) 
};

declare function cal:custo-date-point (
    $dynasty as node()*, 
    $reign as node()*,
    $year as xs:string*, 
    $type as xs:string?) as node()*{

(:This function takes chinese calendar date points ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. 

The normalized format takes DYNASTY//no:c_sort which is specific to CBDB,  
followed by the sequence of reigns determined by their position in cal_ZH.xml
followed by the Year number.D(\d*)-R(\d*)-(\d*)
:)

(:TODO
- getting to a somehwhat noramlized useful representation ofChinese Reign dates is tricky.
    inconsinsten pinyin for Nianhao creates ambigous and ugly dates.
- handle //no:c_dy[. = 0] stuff
- add @period with #d42 #R123
- find a way to prevent empty attributes more and better logic FTW
- If only a dynasty is known lets hear it,
the others are dropped since only a year or nianhao is of little information value. 
:)

let $dy := $global:DYNASTIES//no:c_dy[. = $dynasty/text()]
let $motto := count($cal:path/category[@xml:id = concat('R', $reign/text())]/preceding-sibling::category) +1

        
let $date-norm := string-join((concat('D', $dy/../no:c_sort), concat('R',$motto), concat('Y', $year)),'-')
        


let $date-orig := string-join(($dy/../no:c_dynasty_chn, 
                    $global:NIAN_HAO//no:c_nianhao_id[. = $reign/text()]/../no:c_nianhao_chn,
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

declare function cal:custo-date-range (
    $dy-start as node()*, $dy-end as node()*,
    $reg-start as node()*, $reg-end as node()*, 
    $year-start as xs:string*, $year-end as xs:string*, 
    $type as xs:string?) as node()*{

(:This function takes chinese calendar date ranges ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. :)

let $DS := $global:DYNASTIES//no:c_dy[. = $dy-start/text()]
let $DE := $global:DYNASTIES//no:c_dy[. = $dy-end/text()]

let $RS := count($cal:path/category[@xml:id = concat('R',  $reg-start/text())]/preceding-sibling::category) +1
let $RE := count($cal:path/category[@xml:id = concat('R',  $reg-end/text())]/preceding-sibling::category) +1

        
let $start-norm := string-join((concat('D', $DS/../no:c_sort), concat('R',$RS), concat('Y', $year-start)),'-')
let $end-norm := string-join((concat('D', $DE/../no:c_sort), concat('R',$RE), concat('Y', $year-end)),'-')       


                  
let $start-orig := string-join(($DS/../no:c_dynasty_chn, 
                    $global:NIAN_HAO//no:c_nianhao_id[. = $reg-start/text()]/../no:c_nianhao_chn,
                    concat($year-start, '年')),'-')  
                    
let $end-orig := string-join(($DE/../no:c_dynasty_chn, 
                    $global:NIAN_HAO//no:c_nianhao_id[. = $reg-end/text()]/../no:c_nianhao_chn,
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

declare function cal:ganzhi ($year as xs:integer, $lang as xs:string?)  as xs:string* {

(:Just for fun: calculate the ganzhi cycle for gYears where $year is an integer,
and $lang is either hanzi = 'zh', or pinyin ='py' for output. 

The function assumes that $year is an isoyear using astronomical calendar conventions so:
AD 1 = year 1, = 0001 xs:gYear
1 BC = year 0, = -0001 xs:gYear
2 BC = year −1, = -0002 xs:gYear
etc. :)

(: TEST:

cal:ganzhi(2036, 'zh') -> 丙辰
cal:ganzhi(1981, 'zh') -> 辛酉
cal:ganzhi(1967, 'zh') -> 丁未
cal:ganzhi(0004, 'zh') -> 甲子
cal:ganzhi(0001, 'zh') -> 壬戌
cal:ganzhi(0000, 'zh') -> no such gYear 
cal:ganzhi(-0001, 'zh') -> 庚申
cal:ganzhi(-0247, 'zh') -> 乙卯 = 246BC founding of Qing

:)

    let $ganzhi_zh := 
        for $step in (1 to 60)
        
        let $stem_zh := ('甲', '乙','丙','丁','戊','己','庚','辛','壬','癸') 
        let $branch_zh := ('子','丑','寅,','卯','辰','巳','午','未','申','酉','戌','亥')            
        
        return
            if ($step = 60) then (concat($stem_zh[10], $branch_zh[12]))
            else if ($step mod 10 = 0) then (concat($stem_zh[10], $branch_zh[$step mod 12]))
            else if ($step mod 12 = 0) then (concat($stem_zh[$step mod 10], $branch_zh[12]))
            else concat($stem_zh[$step mod 10], $branch_zh[$step mod 12])  
            
   let $ganzhi_py :=
        for $step in (1 to 60)        
        
        let $stem_py := ('jiǎ', 'yǐ', 'bǐng', 'dīng', 'wù', 'jǐ', 'gēng', 'xīn', 'rén', 'guǐ')
        let $branch_py := ('zǐ', 'chǒu', 'yín, ', 'mǎo', 'chén', 'sì', 'wǔ', 'wèi', 'shēn', 'yǒu', 'xū', 'hài')
        
         return
            if ($step = 60) then (concat($stem_py[10], ' ', $branch_py[12]))
            else if ($step mod 10 = 0) then (concat($stem_py[10], ' ', $branch_py[$step mod 12]))
            else if ($step mod 12 = 0) then (concat($stem_py[$step mod 10], ' ', $branch_py[12]))
            else concat($stem_py[$step mod 10], ' ', $branch_py[$step mod 12])          
            
    
   let $sexagenary_zh :=
        map:new(
        for $ganzhi at $pos in $ganzhi_zh
        return
            map:entry($pos, $ganzhi)
                )
    
    let $sexagenary_py :=
           map:new(
           for $ganzhi at $pos in $ganzhi_py
           return
               map:entry($pos, $ganzhi)
                   )
                   
    return
        switch ($lang)
        case 'zh'
            return     
                if  ($year > 3)  then ($sexagenary_zh((($year -3) mod 60)))
                    else if ($year = 3)  then ($sexagenary_zh(60))
                    else if ($year = 2)  then ($sexagenary_zh(59))
                    else if ($year = 1)  then ($sexagenary_zh(58))
                    else if ($year = -1)  then ($sexagenary_zh(57))
                    else if ($year < -1)  then ($sexagenary_zh((60 - (($year * -1) +1) mod 60)))        
                else "0年 …太複雜"
        case 'py'
            return     
                if  ($year > 3)  then ($sexagenary_py((($year -3) mod 60)))
                    else if ($year = 3)  then ($sexagenary_py(60))
                    else if ($year = 2)  then ($sexagenary_py(59))
                    else if ($year = 1)  then ($sexagenary_py(58))
                    else if ($year = -1)  then ($sexagenary_py(57))
                    else if ($year < -1)  then ($sexagenary_py((60 - (($year * -1) +1) mod 60)))        
                else "0 AD/CE  … it's complicated"
        default return "please specify either 'py' or 'zh'"    
            
};

declare function cal:sexagenary ($ganzhi as node()*) as item()* {
<taxonomy xml:id="sexagenary"> 
{ 
for $gz in $ganzhi
return         
    global:validate-fragment(<category xml:id="{concat('S', $gz/no:c_ganzhi_code/text())}">
        <catDesc xml:lang="zh-Hant">{$gz/no:c_ganzhi_chn/text()}</catDesc>
        <catDesc xml:lang="zh-Latn-alalc97">{$gz/no:c_ganzhi_py/text()}</catDesc>
    </category>, 'category')
            }
</taxonomy>
};

declare function cal:dynasties ($dynasties as node()*) as item()* {
<taxonomy xml:id="reign">
    {
    for $dy in $dynasties
    let $dy_id := $dy/no:c_dy
    where $dy/no:c_dy > '0'
    return                
        global:validate-fragment(<category xml:id="{concat('D', $dy_id/text())}">
            <catDesc>
                <date from="{cal:isodate($dy/no:c_start)}" to="{cal:isodate($dy/no:c_end)}"/>
        </catDesc>
        <catDesc xml:lang="zh-Hant">{$dy/no:c_dynasty_chn/text()}</catDesc>
        <catDesc xml:lang="en">{$dy/no:c_dynasty/text()}</catDesc>
        {
        for $nh in $global:NIAN_HAO//no:row 
        where $nh/no:c_dy = $dy_id
        return
            if ($nh/no:c_nianhao_pin != '')
            then (<category xml:id="{concat('R' , $nh/no:c_nianhao_id/text())}">
                        <catDesc>
                            <date from="{cal:isodate($nh/no:c_firstyear)}" to="{cal:isodate($nh/no:c_lastyear)}"/>
                        </catDesc>
                        <catDesc xml:lang="zh-Hant">{$nh/no:c_nianhao_chn/text()}</catDesc>
                        <catDesc xml:lang="zh-Latn-alalc97">{$nh/no:c_nianhao_pin/text()}</catDesc>
                   </category>) 
            else (<category xml:id="{concat('R' , $nh/no:c_nianhao_id/text())}">
                        <catDesc>
                            <date from="{cal:isodate($nh/no:c_firstyear)}" to="{cal:isodate($nh/no:c_lastyear)}"/>                    
                        </catDesc>
                        <catDesc xml:lang="zh-Hant">{$nh/no:c_nianhao_chn/text()}</catDesc>
                    </category>)                           
        }
        </category>, 'category')
    }
</taxonomy>
};

xmldb:store($global:target, $global:calendar, 
    <taxonomy xml:id="cal_ZH">{                
            cal:sexagenary($global:GANZHI_CODES//no:row),
            cal:dynasties($global:DYNASTIES//no:row)}
    </taxonomy>)

            

        