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

declare function local:address-new($addr as node()*) {

(: This function takes the $global:ADDRESSES//c_addr_id entities and tranlsates them into tei:place.
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

(: Based on this tests certain columns don't require aconditional check for empty() 
count(empty($ADDRESSES//c_admin_type)) 
 = count(empty($ADDRESSES//c_firstyear)) 
 = count(empty($ADDRESSES//c_lastyear))
= 1 = TRUE (unkown)

similarly "_belongs" sources are all unkown
count($global:ADDR_BELONGS_DATA//c_source[. > 0]) = 0
:)


    
    
    let $code := $global:ADDR_CODES//c_addr_id[. = $addr]
    let $relation := $global:ADDR_BELONGS_DATA//c_addr_id[. = $addr]    
    (:let $id-padding := string-length(string(max($ADDRESSES//c_addr_id))) +1  :)
    
    
    return  
        if (count($global:ADDRESSES//c_addr_id[. = $addr]) > 1)
        then (
                functx:distinct-deep($global:ADDRESSES//c_addr_id[. = $addr]/../*)
                
(:                element place { attribute xml:id {concat('PL', $place-dupe[1])}
                }:)
                )
        else ( for $place in $addr
        return
        <place xml:id="{concat('PL', $place/../c_addr_id)}"
            type ="{ if (empty(pla:fix-admin-types($place/../c_admin_type)))
            then (pla:fix-admin-types($code/../c_admin_type))
            else (pla:fix-admin-types($place/../c_admin_type))
            }">
            <placeName xml:lang="zh-Hant">{$place/../c_name_chn/text()}</placeName>            
            <placeName xml:lang="zh-alac97">{$place/../c_name/text()}</placeName>            
                {
                if (empty($code/../c_alt_names)) 
                then ()
                else (<placeName type ="alias">{$code/../c_alt_names/text()}</placeName>)
                }
            {
            if (empty(cal:isodate($place/../c_firstyear)))
            then ()
            else (<location from="{cal:isodate($place/../c_firstyear)}"
                        to="{cal:isodate($place/../c_lastyear)}">
                        {
                        if (empty($code/../x_coord) or $code/../x_coord = 0) 
                        then ()
                        else(<geo>{concat($code/../x_coord/text(), ' ',$code/../y_coord/text())}</geo>)
                        }
                   </location>)
            }            
            {
            if (empty($code/../CHGIS_PT_ID)) 
            then ()
            else (<idno type="CHGIS">{$code/../CHGIS_PT_ID/text()}</idno>)
            }           
              {
              if (empty($code/../c_notes)) 
              then ()
              else (<note>{$code/../c_notes/text()}</note>)
              }
            {
            if (empty($relation/../c_notes)) 
            then ()
            else (<note>{$relation/../c_notes/text()}</note>)
            }
            {
            (:   !!! Check pointers to TEXT_DATA !!!  :)
            if (empty($relation/../c_source) or $relation/../c_source = 0) 
            then ()
            else (<bibl target="{concat('#', $relation/../c_source/text())}"/>)
            }
        </place>)
};


let $test := $global:ADDRESSES//c_addr_id[. = 4342]
return
(:    $test/..:)

<fix>
    <old count="{count($test)}">{pla:address($test)}</old>
    <new count="{count($test)}">{local:address-new($test)}</new>
</fix>