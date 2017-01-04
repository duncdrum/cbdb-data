xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 

(:calendar.xql reads the calendar aux tables (GANZHI, DYNASTIES, NIANHAO) 
    and creates a taxonomy element for inculsion in the teiHeader via xi:xinclude.
    The taxonomy consists of two elements one for the sexagenarycycle, 
    and one nested taxonomy for reign-titles and dynsties.
    we are dropping the c_sort value for dynasties since sequential sorting
    is implicit in the data structure
:)

(:TODO:
 -  
:)


declare function local:isodate ($string as xs:string?)  as xs:string* {

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

declare function local:sqldate ($timestamp as xs:string?)  as xs:string* {
concat(substring($timestamp, 1, 4), '-', substring($timestamp, 5, 2), '-', substring($timestamp, 7, 2)) 
};

declare function local:ganzhi ($year as xs:integer, $lang as xs:string?)  as xs:string* {

(:Just for fun: calculate the ganzhi cycle for gYears where $year is an integer,
and $lang is either hanzi = 'zh', or pinyin ='py' for output. 

The function assumes that $year is an isoyear using astronomical calendar conventions so:
AD 1 = year 1, = 0001 xs:gYear
1 BC = year 0, = -0001 xs:gYear
2 BC = year −1, = -0002 xs:gYear
etc. :)

(: TEST:

local:ganzhi(2036, 'zh') -> 丙辰
local:ganzhi(1981, 'zh') -> 辛酉
local:ganzhi(1967, 'zh') -> 丁未
local:ganzhi(0004, 'zh') -> 甲子
local:ganzhi(0001, 'zh') -> 壬戌
local:ganzhi(0000, 'zh') -> no such gYear 
local:ganzhi(-0001, 'zh') -> 庚申
local:ganzhi(-0247, 'zh') -> 乙卯 = 246BC founding of Qing

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

declare function local:sexagenary ($ganzhi as node()*) as node() {
<taxonomy xml:id="sexagenary"> 
{ 
for $gz in $ganzhi
return         
    <category xml:id="{concat('S', $gz/c_ganzhi_code/text())}">
        <catDesc xml:lang="zh-Hant">{$gz/c_ganzhi_chn/text()}</catDesc>
        <catDesc xml:lang="zh-alalc97">{$gz/c_ganzhi_py/text()}</catDesc>
    </category>
            }
</taxonomy>
};

declare function local:dynasties ($dynasties as node()*) as node() {
<taxonomy xml:id="reign">
    {
    for $dy in $dynasties
    let $dy_id := $dy/c_dy
    where $dy/c_dy > '0'
    return                
        <category xml:id="{concat('D', $dy/c_dy/text())}">
            <catDesc>
                <date from="{local:isodate($dy/c_start)}" to="{local:isodate($dy/c_end)}"/>
        </catDesc>
        <catDesc xml:lang="zh-Hant">{$dy/c_dynasty_chn/text()}</catDesc>
        <catDesc xml:lang="en">{$dy/c_dynasty/text()}</catDesc>
        {
        for $nh in $NIAN_HAO//row 
        where $nh/c_dy = $dy_id
        return
            if ($nh/c_nianhao_pin != '')
            then (<category xml:id="{concat('R' , $nh/c_nianhao_id/text())}">
                        <catDesc>
                            <date from="{local:isodate($nh/c_firstyear)}" to="{local:isodate($nh/c_lastyear)}"/>
                        </catDesc>
                        <catDesc xml:lang="zh-Hant">{$nh/c_nianhao_chn/text()}</catDesc>
                        <catDesc xml:lang="zh-alalc97">{$nh/c_nianhao_pin/text()}</catDesc>
                   </category>) 
            else (<category xml:id="{concat('R' , $nh/c_nianhao_id/text())}">
                        <catDesc>
                            <date from="{local:isodate($nh/c_firstyear)}" to="{local:isodate($nh/c_lastyear)}"/>                    
                        </catDesc>
                        <catDesc xml:lang="zh-Hant">{$nh/c_nianhao_chn/text()}</catDesc>
                    </category>)                           
        }
        </category>
    }
</taxonomy>
};

xmldb:store($target, 'cal_ZH.xml', 
    <taxonomy xml:id="cal_ZH">                
        {local:sexagenary($GANZHI_CODES//row)}
        {local:dynasties($DYNASTIES//row)}
    </taxonomy>
)

            

        