xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare default element namespace "http://www.tei-c.org/ns/1.0";


(:officeB joins the nodes from the two intermediary files written by officeA.
it also cleans up after itself.
In case of disaster simply regenerate the previous files by running officeA.xql

 @author Duncan Paterson
 @version 0.6
 
 @return merges officeA.xml into office.xml, then deletes temp file officeA.xml.
:)

declare function local:merge-officeTree ($tree as node()*, $off as node()*) as node()* {
(: !!! WARNING local:merge-officeTree PERMANENTLY CHANGES DATA !!! :)

for $x in $tree, 
    $y in $off[@n = data($x/@n)]
return 
       update insert $y into $x
};



let $tree := doc(concat($global:target, $global:office))
let $off := doc(concat($global:target, $global:office-temp))



return
    local:merge-officeTree($tree//category, $off//category) ,
    xmldb:remove($global:target, $global:office-temp)
    



        
