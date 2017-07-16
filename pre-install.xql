xquery version "3.0";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace file = "http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

(: the path to the exist-db installation :)
declare variable $exist_home as xs:string := system:get-exist-home();
(:check available memory:)
declare variable $mem-max := system:get-memory-max();
(: minimum memory requirements :)
declare variable $mem-req := 2000000000;
(: minimum cache Size:)
declare variable $cache-req := 500;

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return
            (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
            )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(: Helper function to check the instance's chacheSize. :)
declare function local:check-cache-size($path as xs:string) as xs:boolean {
    if (file:is-readable($path || "/conf.xml"))
    then
        (
        let $doc := fn:parse-xml(file:read($path || "/conf.xml"))
        return
            if (number(substring-before($doc//exist/db-connection/@cacheSize/string(), "M")) > $cache-req)
            then
                (fn:true())
            else
                (fn:error(fn:QName('https://github.com/duncdrum/cbdb-data', 'err:cache-low'), 'Your configured cacheSize is too low')))
    else
        (fn:true())
};

(: Helper function to check the instance's memory. :)
declare function local:check-mem-size($memory as xs:integer) as xs:boolean {
    if ($memory > $mem-req)
    then
        (fn:true())
    else
        (fn:error(fn:QName('https://github.com/duncdrum/cbdb-data', 'err:memory-low'), 'Your configured -xmx memory is too low'))
};

if (local:check-mem-size($mem-max) and local:check-cache-size($exist_home))
then
    (
    (: store the collection configuration :)
    local:mkcol("/db/system/config", $target),
    xdb:store-files-from-pattern(concat("/db/system/config", $target), $dir, "*.xconf"))
else
    (fn:error(fn:QName('https://github.com/duncdrum/cbdb-data', 'err:pre-crash'), 'An unknown error occured during pre-install'))