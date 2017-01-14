xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";


for $person in $global:BIOG_MAIN//c_personid[. = 7]

let $dy_by := $global:DYNASTIES//c_dy[. = $global:NIAN_HAO//c_nianhao_id[. = $person/../c_by_nh_code]/../c_dy]/../c_sort
let $dy_dy := $global:DYNASTIES//c_dy[. = $global:NIAN_HAO//c_nianhao_id[. = $person/../c_dy_nh_code]/../c_dy]/../c_sort

let $re_by := count($cal:path/tei:category[@xml:id = concat('R', $person/../c_by_nh_code/text())]/preceding-sibling::tei:category) +1
let $re_dy := count($cal:path/tei:category[@xml:id = concat('R', $person/../c_dy_nh_code/text())]/preceding-sibling::tei:category) +1

return
<birth>{
    if  ($person/../c_by_nh_code[.  > 0])
                 then (attribute datingMethod {'#chinTrad'},
                        attribute when-custom {
                        if ($person/../c_by_nh_year[.  > 0])
                        then (string-join(
                                (concat('D', $dy_by), concat('R',$re_by), concat('Y', $person/../c_by_nh_year)),'-')
                              )
                        else (string-join(
                                (concat('D', $dy_by), concat('R',$re_by)),'-')
                              )
                        })
                 else (),
                 if ($person/../c_by_nh_code > 0 or $person/../c_by_nh_year or $person/../c_by_day_gz > 0)
                 then (element date { attribute calendar {'#chinTrad'},
                    attribute period{concat('#R',$person/../c_by_nh_code/text())},
                 $dy_by/../c_dynasty_chn/text(), $global:NIAN_HAO//c_nianhao_id[. = $person/../c_by_nh_code]/../c_nianhao_chn/text(), 
                 string-join(($person/../c_by_nh_year/text(), $person/../c_by_day_gz/text()), ':')
                 })
                 else ()}
</birth>