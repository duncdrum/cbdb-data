xquery version "3.1";

(:~
: Writes the unique columns for each table into a model.xml file
:
: @author Duncan Paterson
: @version 0.8.0
:)

import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace no = "http://none";



declare variable $path := collection($config:app-root || '/src/');
   
declare %private function local:get-col ($nodes as document-node()?) as item()* {

let $names := for $node in $nodes//no:row/*
    return
        local-name($node)
return
    distinct-values ($names)
};    

declare %private function local:write-model ($docs as item()*) {
xmldb:store ($path, 'model.xml',
    element model {    
        for $n in $docs
        let $doc := doc($config:src-data || $n)
        let $name := substring-before($n,'.')
    
        return
            element {$name} {
                for $c in local:get-col ($doc)
                return
                    element column {$c}
            }
    })
};

let $src-files := function () {
    for $files in collection($config:src-data)
    let $name := util:document-name($files)
    order by $name
    return
        $name
}


return
    if ($path/model/* = "")
    then (local:write-model($src-files()))
    else (util:log('info', 'A model already exists, if you wish to replace it, please run the write-model code manually'))





