xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";


import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog= "http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare function local:nest-places($data as node()*, $id as node()?, $zh as node()?, $py as node()?) as node()*{

(: This function takes the $global:ADDRESSES//row  and tranlsates them into tei:place.
This function is recursive to create a nested tree of place hierarchies via belongs1_ID.
It also needs to filter for duplicate c_addr_id's without loosing the distinct node values of
each duplicate instance. 

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

(: Based on these tests certain columns don't require aconditional checks for empty() 
count(empty($ADDRESSES//c_admin_type)) 
 = count(empty($ADDRESSES//c_firstyear)) 
 = count(empty($ADDRESSES//c_lastyear))
= 1 = TRUE (unkown)

similarly "_belongs" sources are all unkown
count($global:ADDR_BELONGS_DATA//c_source[. > 0]) = 0

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

- check how many $ids belongto 0, -1, or NULL
- types need if empty check use code if not in address
- from to not alwayse a pair need separate checks 
- names also need empty check

:)
    
    
    let $code := $global:ADDR_CODES//c_addr_id[. = $id]
    let $relation := $global:ADDR_BELONGS_DATA//c_addr_id[. = $id]   
(:    let $match := $data[c_addr_id = $id]/belongs1_ID:)
    
(:    let $place-dupe := if (count($global:ADDRESSES//c_addr_id[. = $place]) > 1)
                          then (<row>{functx:distinct-deep($global:ADDRESSES//c_addr_id[. = $place]/../*)}</row>)  
                          else ($place):)
    
    (:let $id-padding := string-length(string(max($ADDRESSES//c_addr_id))) +1  :)
    
    
    return  
        
        element place { attribute xml:id {concat('PL', $id/text())},
            attribute type {pla:fix-admin-types($id/../c_admin_type)},    
                        
            if (empty($relation/../c_source) or $relation/../c_source = 0) 
            then ()
            else (attribute source {concat('#BIB', $relation/../c_source/text())}), 
            
            element placeName { attribute xml:lang {'zh-Hant'},
                $zh/text()},
            element placeName { attribute xml:lang {'zh-alalc97'},
                $py/text()}, 
            
            if (empty($code/../c_alt_names)) 
            then ()
            else (element placeName { attribute type {'alias'}, 
                $code/../c_alt_names/text()}),
            
            if (empty($id/../c_firstyear) and empty($id/../c_lastyear))
            then ()
            else (element location {
                    attribute from {cal:isodate($id/../c_firstyear)},
                    attribute to {cal:isodate($id/../c_lastyear)},
                    
                if (empty($id/../x_coord) or $id/../x_coord[. = 0])
                then ()
                else (element geo {concat($id/../x_coord/text(), ' ', $id/../y_coord/text())})            
                                        }
            ),        
            
            if (empty($code/../CHGIS_PT_ID)) 
            then ()
            else (element idno { attribute type {'CHGIS'},
                        $code/../CHGIS_PT_ID/text()}),
                        
            if (empty($code/../c_notes)) 
            then ()
            else (element note {$code/../c_notes/text()}),
                       
            if (empty($relation/../c_notes)) 
            then ()
            else (element note {$relation/../c_notes/text()}),             
            
            if (exists($data[belongs1_ID = $id/text()]))
            then (for $child in $data[belongs1_ID = $id/text()]
                    return 
                       local:nest-places($data, $child/c_addr_id, $child/c_name_chn, $child/c_name))
            else ()     
        
        }          
       
};

let $data := $global:ADDRESSES//row

(:let $ns as QName := 'http://www.tei-c.org/ns/1.0':)
(:let $test := $data/c_addr_id[. > 0][. < 50]:)

return

<listPlace>
    {for $place in $data//c_addr_id[. > 0]
    where empty($place/../belongs1_ID)
    return
        local:nest-places($data, $place, $place/../c_name_chn, $place/../c_name)}
</listPlace>
