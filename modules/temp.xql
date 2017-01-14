xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace temp="http://exist-db.org/apps/cbdb-data/";

max($global:BIOG_MAIN//row/c_personid)

(:There are 362918 individuals in CBDB, the highest ID is :)