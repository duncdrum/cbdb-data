xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";

declare default element namespace "http://www.tei-c.org/ns/1.0";


(:officeB joins the nodes from the two intermediary files written by officeA.
it also cleans up after itself.
In case of disaster simply regenerate the previous files by running officeA.xql
:)

declare function local:merge-officeTree ($tree as node()*, $off as node()*) as node()* {
(: !!! WARNING local:merge-officeTree PERMANENTLY CHANGES DATA !!! :)

(:there are:
28623 offices in office.xml
 1384 are not matched via OFFICE_CODE_TYPE_REL but have dynasty 
  514 are missing even dynastic affiliations
:)

(:TODO
- fix missing links aka [@n = '']
- use: for $y allowing empty in $off... once exist supports it.
:)

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
    



        
