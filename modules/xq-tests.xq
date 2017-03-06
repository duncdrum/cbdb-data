xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace inspect = "http://exist-db.org/xquery/inspection"; 
import module namespace test = "http://exist-db.org/xquery/xqsuite" at  "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog="http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";
import module namespace org="http://exist-db.org/apps/cbdb-data/institutions" at "institutions.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:~
 This module contains unit test and the test runner functions for all other xquery modules. 
 
  @author Duncan Paterson
  @version 0.7

:)

