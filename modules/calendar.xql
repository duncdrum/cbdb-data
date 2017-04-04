xquery version "3.0";

(:~ 
: The calendar module reads the calendar data from ``GANZHI``, ``DYNASTIES``, and ``NIANHAO`` to 
: create a taxonomy element for inclusion in the teiHeader.
: The taxonomy consists of two elements one for the sexagenary cycle, 
: and one nested taxonomy for reign-titles and dynasties.
: We are dropping the c_sort value for dynasties since sequential sorting
: is implicit in the data structure.
:
: There are some inconsistencies with how *CBDB* processes Chinese dates, in the long
: run using an external authority could solve these problems. 
:    
: @author Duncan Paterson
: @version 0.7
: 
: @see http://authority.dila.edu.tw/time/
:
: @return  cal_ZH.xml:)

module namespace cal="http://exist-db.org/apps/cbdb-data/calendar";

(:import module namespace functx="http://www.functx.com";:)
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:~
:  the path to tei taxonomy file.:)
declare variable $cal:ZH := doc(concat($global:target, $global:calendar));
declare variable $cal:path := $cal:ZH/taxonomy/taxonomy/category;


declare
    %test:args('0') %test:assertEquals('-0001')
    %test:args('123') %test:assertEquals('0123')    
    %test:args('-12') %test:assertEquals('-0012')    
function cal:isodate ($string as xs:string?)  as xs:string* {

(:~ 
: cal:isodate turns inconsistent Gregorian year strings into proper xs:gYear type strings. 
: Consisting of 4 digits, with leading 0s. 
: This means that BCE dates have to be recalculated. Since '0 AD' -> "-0001"
: 
: @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.datable.w3c.html
: @param $string year number in western style counting
: @return gYear style string:)
        
    if (empty($string)) then ()
    else if (number($string) eq 0) then ('-0001')
    else if (starts-with($string, "-")) then (concat('-',(concat (string-join((for $i in (string-length(substring($string,2)) to 3) return '0'),'') , substring($string,2)))))
    else (concat (string-join((for $i in (string-length($string) to 3) return '0'),'') , $string))
};

declare 
    %test:args('11110101') %test:assertEquals('1111-01-01')
function cal:sqldate ($timestamp as xs:string?)  as xs:string* {
(:~ 
: cal:sqldate converts the timestamp like values from CBDBs RLDBMs and converts them into iso compatible date strings,
: i. e.: YYYY-MM-DD
: 
: @param $timestamp collection for strings for western style full date
: @return string in the format: YYYY-MM-DD:)

concat(substring($timestamp, 1, 4), '-', substring($timestamp, 5, 2), '-', substring($timestamp, 7, 2)) 
};

declare function cal:custo-date-point (
    $dynasty as node()*, 
    $reign as node()*,
    $year as xs:string*, 
    $type as xs:string?) as node()*{

(:~ 
: cal:custo-date-point takes Chinese calendar date strings (columns ending in ``*_dy``, ``*_gz``, ``*_nh``) .
: It returns a single ``tei:date`` element using ``att.datable.custom``. 
: cal:custo-date-range does the same but for date ranges. 
: 
: The normalized format takes ``DYNASTY//no:c_sort`` which is specific to CBDB,  
: followed by the sequence of reigns determined by their position in cal_ZH.xml
: followed by the Year number: ``D(\d*)-R(\d*)-(\d*)``
: 
: @param $dynasty the sort number of the dynasty.
: @param $reign the sequence of the reign period 1st = 1, 2nd = 2, etc. 
: @param $year the ordinal year of the reign period 1st = 1, 2nd = 2, etc.
: @param $type can process 5 kinds of date-point:  
:    *   'Start' , 'End' preceded by 'u' for uncertainty, defaults to 'when'.
:    
: @return ``<date datingMethod="#chinTrad" calendar="#chinTrad">input string</date>``:)

let $dy := $global:DYNASTIES//no:c_dy[. = $dynasty/text()]
let $motto := count($cal:path/category[@xml:id = concat('R', $reign/text())]/preceding-sibling::category) + 1
        
let $date-norm := string-join((concat('D', $dy/../no:c_sort), concat('R',$motto), concat('Y', $year)),'-')
let $date-orig := string-join(($dy/../no:c_dynasty_chn, 
                    $global:NIAN_HAO//no:c_nianhao_id[. = $reign/text()]/../no:c_nianhao_chn,
                    concat($year, '年')),'-')

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

(:~ 
: This function takes Chinese calendar date ranges. It's the companion to [cal:custo-date-point](#custo-date-point).
:
: It determines the matching end-points automatically when provided a starting point for a date range. 
: 
: @param $dy-start the sort number of the starting dynasty.
: @param $reg-start the sequence of the starting reign period 1st = 1, 2nd = 2, etc. 
: @param $year-start the ordinal year of the starting reign period 1st = 1, 2nd = 2, etc.
: @param $type has two options 'uRange' for uncertainty, default to certain ranges. 

: @return ``<date datingMethod="#chinTrad" calendar="#chinTrad">input string</date>``:)

let $DS := $global:DYNASTIES//no:c_dy[. = $dy-start/text()]
let $DE := $global:DYNASTIES//no:c_dy[. = $dy-end/text()]

let $RS := count($cal:path/category[@xml:id = concat('R',  $reg-start/text())]/preceding-sibling::category) + 1
let $RE := count($cal:path/category[@xml:id = concat('R',  $reg-end/text())]/preceding-sibling::category) + 1

        
let $start-norm := string-join((concat('D', $DS/../no:c_sort), concat('R',$RS), concat('Y', $year-start)),'-')
let $end-norm := string-join((concat('D', $DE/../no:c_sort), concat('R',$RE), concat('Y', $year-end)),'-')       


                  
let $start-orig := string-join(($DS/../no:c_dynasty_chn, 
                    $global:NIAN_HAO//no:c_nianhao_id[. = $reg-start/text()]/../no:c_nianhao_chn,
                    concat($year-start, '年')),'-')  
                    
let $end-orig := string-join(($DE/../no:c_dynasty_chn, 
                    $global:NIAN_HAO//no:c_nianhao_id[. = $reg-end/text()]/../no:c_nianhao_chn,
                    concat($year-end, '年')),'-')              

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

declare 
    %test:args('2036', 'zh') %test:assertEquals('丙辰')   
    %test:args('0004', 'py') %test:assertEquals('jiǎ zǐ')    
    %test:args('0000', 'py') %test:assertEquals("0 AD/CE  … it's complicated")    
    %test:args('-0001', 'zh') %test:assertEquals('庚申')    
    %test:args('-0247', 'zh') %test:assertEquals('乙卯')
function cal:ganzhi ($year as xs:integer, $lang as xs:string?)  as xs:string* {
(:~
: Just for fun: ``cal:ganzhi`` calculates the ganzhi cycle for a given year. 
: It assumes gYears for calculating BCE dates.
: 
: @param $year gYear compatible string. 
: @param $lang is either hanzi = 'zh', or pinyin ='py' for output. 
: 
: @return ganzhi cycle as string in either hanzi or pinyin.:)

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
        map:new (
        for $ganzhi at $pos in $ganzhi_zh
        return
            map:entry($pos, $ganzhi)
                )
    
    let $sexagenary_py :=
           map:new (
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

declare function cal:sexagenary ($ganzhi as node()*, $mode as xs:string?) as item()* {
(:~
: cal:sexagenary converts ``GANZHI`` data into categories. 
: 
: @param $ganzhi ``c_ganzhi_code``
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
: 
: @return ``<taxonomy xml:id="sexagenary">...</taxonomy>``:)

<taxonomy xml:id="sexagenary">{
    let $output := 
        for $gz in $ganzhi
        return         
            <category xml:id="{concat('S', $gz/no:c_ganzhi_code/text())}">
                <catDesc xml:lang="zh-Hant">{$gz/no:c_ganzhi_chn/text()}</catDesc>
                <catDesc xml:lang="zh-Latn-alalc97">{$gz/no:c_ganzhi_py/text()}</catDesc>
            </category>
    return 
        switch($mode)
            case 'v' return global:validate-fragment($output, 'category')
            case 'd' return global:validate-fragment($output, 'category')[1]
        default return $output
}
</taxonomy>
};

declare 
    %test:pending("validation as test")
function cal:dynasties ($dynasties as node()*, $mode as xs:string?) as item()* {
(:~
: cal:dynasties converts DYNASTIES, and NIANHAO data into categories. 
: 
: @param $dynasties ``c_dy``
: @param $mode can take three effective values:
:    *   'v' = validate; preforms a validation of the output before passing it on. 
:    *   ' ' = normal; runs the transformation without validation.
:    *   'd' = debug; this is the slowest of all modes.
: 
: @return ``<taxonomy xml:id="reign">...</taxonomy>``:)

<taxonomy xml:id="reign">{
    let $output :=     
        for $dy in $dynasties
        let $dy_id := $dy/no:c_dy
        where $dy/no:c_dy > '0'
        return                
            <category xml:id="{concat('D', $dy_id/text())}">
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
            </category>
    return 
        switch($mode)
            case 'v' return global:validate-fragment($output, 'category')
            case 'd' return global:validate-fragment($output, 'category')[1]
        default return $output     
        }
</taxonomy>
};

declare %private function cal:write($item as item()*) as item()*{
(:~
: write the taxonomy containing the results of both cal:sexagenary and cal:dynasties into db.:)

xmldb:store($global:target, $global:calendar, 
    <taxonomy xml:id="cal_ZH">{                
            cal:sexagenary($global:GANZHI_CODES//no:row, 'v'),
            cal:dynasties($global:DYNASTIES//no:row, 'v')}
    </taxonomy>)
};