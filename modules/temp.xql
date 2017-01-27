xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";


import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="nowhere";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare function local:nest-places($data as node()*, $id as node(), $zh as node()?, $py as node()?) as node()*{

(: This function takes the $global:ADDR_CODES//rows plus the first $global:ADDR_BELONGS_DATA parent  
and tranlates them into tei:place.
This function is recursive to create a nested tree of place hierarchies via c_belongs_to.
This was neccessar to filter duplicates from $global:ADDRESSES, where multiple c_addr_id's 
are present. 

:)

 (: ADDRESSES                                               ADDR_CODES
 [c_addr_id] INTEGER,           x                          [c_addr_id] INTEGER PRIMARY KEY, 
 [c_addr_cbd] CHAR(255),        x                         
 [c_name] CHAR(255),                                       [c_name] CHAR(255), 
 [c_name_chn] CHAR(255),                                  [c_name_chn] CHAR(255), 
 [c_firstyear] INTEGER,                                   [c_firstyear] INTEGER,
 [c_lastyear] INTEGER,                                    [c_lastyear] INTEGER,
 [c_admin_type] CHAR(255),                                [c_admin_type] CHAR(255),
 [x_coord] FLOAT,                                          [x_coord] FLOAT,
 [y_coord] FLOAT,                                          [y_coord] FLOAT,
                                                             [CHGIS_PT_ID] INTEGER,
                                                             [c_notes] CHAR,
 [belongs1_ID] INTEGER,                                   [c_alt_names] CHAR(255))   
 [belongs1_Name] CHAR(255), 
 [belongs2_ID] INTEGER, 
 [belongs2_Name] CHAR(255), 
 [belongs3_ID] INTEGER, 
 [belongs3_Name] CHAR(255), 
 [belongs4_ID] INTEGER, 
 [belongs4_Name] CHAR(255), 
 [belongs5_ID] INTEGER, 
 [belongs5_Name] CHAR(255))
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

- check how many $ids belongto 0, -1, or NULL A: ca. 600


:)

    let $belong := $global:ADDR_BELONGS_DATA//no:c_addr_id[. = $id]   
 
    
    return  
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
            
            if (empty($id/../no:c_firstyear) and empty($id/../no:c_lastyear) and empty ($id/../x_coord))
            then ()
            else ( element location {
                if (empty($id/../no:c_firstyear))
                then ()
                else ( attribute from {cal:isodate($id/../no:c_firstyear)}),
                
                if (empty($id/../no:c_lastyear))
                then ()
                else ( attribute to {cal:isodate($id/../no:c_lastyear)}),
                    
                if (empty($id/../x_coord) or $id/../x_coord[. = 0])
                then ()
                else ( element geo {concat($id/../x_coord/text(), ' ', $id/../y_coord/text())})            
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
                       local:nest-places($data, $child/../no:c_addr_id, $child/../no:c_name_chn, $child/../no:c_name))
            else ()    
        
        }          
       
};


declare function local:patch-missing-addr($data as node()*) as node()*{
    
(: This function adds tei:places that are present in $global:ADDRESSES but not $global:ADDR_CODES.  
It expects $global:ADDRESSES//row s and insert either empty place elements with a matching @corresp attribute, 
or complete tei:place elements from pla:nest-places for elements not captured in the intial write operation.

We need to do this to make sure that every c_addr_id element present in CBDB can be found in listPlace.xml. 
:)
    for $n in $data
    let $corresp := min(data($global:ADDR_CODES//no:c_name_chn[. = $n/no:c_name_chn]/../no:c_addr_id))
    let $branch := if ($global:ADDR_CODES//no:c_addr_id[. = $n/belongs1_ID])
                     then (concat('PL', $n/belongs1_ID))
                     else if ($global:ADDR_CODES//no:c_addr_id[. = $n/belongs2_ID])
                           then (concat('PL', $n/belongs2_ID)) 
                           else if ($global:ADDR_CODES//no:c_addr_id[. = $n/belongs3_ID])
                                then (concat('PL', $n/belongs3_ID))
                                else if ($global:ADDR_CODES//no:c_addr_id[. = $n/belongs4_ID])
                                      then (concat('PL', $n/belongs4_ID))
                                      else if ($global:ADDR_CODES//no:c_addr_id[. = $n/belongs5_ID])
                                            then (concat('PL', $n/belongs5_ID))
                                            else (concat('PL', $corresp))
                                            
    let $listPlace := doc(concat($global:target, $global:place))
    
    where empty($global:ADDR_CODES//no:c_addr_id[. = $n/no:c_addr_id])
    order by $n/no:c_addr_id/number()
    
    return 
        if (empty($corresp))
        then (local:nest-places($n, $n/no:c_addr_id, $n/no:c_name_chn, $n/no:c_name) 
                       , <branch>{$branch}</branch>)
        else (element place { attribute xml:id {concat('PL', $n/no:c_addr_id/text())}, 
                                attribute corresp{concat('#PL',$corresp)}, 
                                attribute branch{$branch}}
                       )
                
};  



    local:patch-missing-addr($global:ADDRESSES//row)


