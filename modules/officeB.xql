xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

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



let $tree := doc('/db/apps/cbdb-data/target/office.xml')
let $off := doc('/db/apps/cbdb-data/target/officeA.xml')



return
    local:merge-officeTree($tree//category, $off//category) ,
    xmldb:remove($target, 'officeA.xml')
    



        
