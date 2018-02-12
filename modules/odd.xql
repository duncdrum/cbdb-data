xquery version "3.1";

(:~
: The odd module creates a a custom odd based on the exported CBDB source files
: 
: @author Duncan Paterson
: @version 0.8.0
:)

(:module namespace odd="http://exist-db.org/apps/cbdb-data/odd";:)


import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";


declare variable $path := collection($config:app-root || '/src/');
declare variable $model := $path/model/.;
declare variable $tmpl := doc('/db/apps/cbdb-data/templates/tei/cbdbTEI-template.xml');

declare option output:method "adaptive";

declare function odd:make ($att as item()) as map()* {
(:~ anything but array here leads to error, yet arrays remore ws :)
let $att-name:=  for $n in $tmpl//*/@*[local-name(.) = $att]
    return
        local-name($n/..)
        
for $x in distinct-values($att-name)
let $key := $x || '/@' || $att 
let $val := 'distinct-values(data($tmpl//tei:' || $x || '/@' || $att || '))'
let $seq := [util:eval($val)]

return
   map {$key := $seq}
};

declare function odd:transform (
    $odd-el as xs:string, 
    $odd-at as xs:string, 
    $src-el as xs:string*, 
    $src-gloss as xs:string*) as item()* {
(:~
: odd:transform the distinct values of the source-tables into odd:attDef
: 
:
: @param $odd-el the tei element name
: @param $odd-at the tei attribute to modified typically 'type' or 'sub-type'
: @param $src-el the cdbd element that contains the unique values
: @param $src-gloss the cbdb element that contains gloss for $src-el, if any. 
:)


element elementSpec { attribute ident {$odd-el},
        attribute mode {'change'},
            element attList {
                element attDef { attribute ident {$odd-at},
                    attribute usage {'rec'},
                    attribute mode {'change'},
                        element gloss { $odd-el || ' should have ' || $odd-at || ' attribute'},
                        element datatype {
                            element rng:ref { attribute name {'datatype.Code'} }
                        },
                        
                        for $value in distinct-values($src-el)                            
                        return
                            element valItem { attribute ident {$value},
                                if ($src-gloss = '') 
                                then (element gloss {'machine generated'})
                                else (element gloss {$src-gloss})
                            }
                }
            }        
        }
};


let $attribute := function () {
    let $a := for $n in $tmpl//*/@*
        return local-name($n)
    
    return
        distinct-values(data($a))
    }

let $filter := 
    map:merge(
        for $n in $attribute()
        
        return
            switch($n)
                case 'type' return odd:make('type')
                case 'status' return odd:make('status')
                case 'n' return odd:make('n')
                case 'ana' return odd:make('ana')
                case 'resp' return odd:make('resp')
                case 'value' return odd:make('value')
                case 'role' return odd:make('role')
                case 'name' return odd:make('name')
                case 'subtype' return odd:make('subtype')
             default return map {'' : ''} )  

let $process := 
(:  find away to split $src-el programmatically  :)
    map:for-each($filter, function($key, $value){
    let $a := substring-before($key, '/')
    let $b := substring-after($key, '@')
    let $c :=  map:get($filter, $key)
    
    return        
        "odd:transform('" || $a || "', '" || $b || "', ('" || $c || "'), ''),"
    })

let $el-spec := element root { 
    odd:transform('addName', 'type', 'choronym', 'combination of place name and clan name'),
    odd:transform('availability', 'status', 'restricted', ''),
    odd:transform('bibl', 'subtype', 'bib:bib', ''),    
    odd:transform('bibl', 'type', 'bib:bib', ''),
    odd:transform('category', 'n', 'odd:office', ''),    
    odd:transform('date', 'type', ('original','published'), ''),
    odd:transform('desc', 'type', ('kin-tie','biog:asso','biog:entry'), ''),
    odd:transform('desc', 'n', 'biog:asso', ''),    
    odd:transform('desc', 'ana', ('topic','genre','七色補官門','7specials'), ''),
    odd:transform('desc', 'subtype', 'biog:entry', ''),    
    odd:transform('event', 'role', '#BIO', ''),
    odd:transform('event', 'type', ('general','biog:entry'), ''),
    odd:transform('event', 'subtype', 'biog:entry', ''),
    odd:transform('idno', 'type', ('TTS','CHGIS','VIAF', "UUID"), ''),    
    odd:transform('listRelation', 'type', ('kinship','associations'), ''),
    odd:transform('mapping', 'type', ('Unicode','standard'), ''),    
    odd:transform('note', 'type', ('field','attempts','rank','parental-status','created','modified'), ''),    
    odd:transform('org', 'role', 'org:org', ''),
    odd:transform('org', 'ana', 'historical', ''),    
    odd:transform('orgName', 'type', ('main','alias'), ''),
    odd:transform('persName', 'role', 'mediator', ''),
    odd:transform('persName', 'type', ('main','original','alias'), ''),    
    odd:transform('person', 'ana', 'historical', ''),    
    odd:transform('person', 'resp', 'selfbio', 'Tracks whatever c_self_bio tracks in CBDB'),
    odd:transform('personGrp', 'role', ('kin','associates'), ''),
    odd:transform('place', 'type', 'pla:fix-admin-types', ''),    
    odd:transform('placeName', 'type', 'alias', ''),
    odd:transform('relation', 'type', 'auto-generated', ''),
    odd:transform('relation', 'name', ('biog:kin','biog:asso'), ''),    
    odd:transform('residence', 'n', 'biog:pers-add', ''),
    odd:transform('roleName', 'type', ('main','alt'), ''),
    odd:transform('sex', 'value', 'biog:biog', ''),    
    odd:transform('state', 'n', ('biog:status','biog:posses','biog:new-post'), ''),
    odd:transform('state', 'ana', 'biog:asso', ''),
    odd:transform('state', 'subtype', ('biog:asso','biog:status','biog:posses'), ''),
    odd:transform('state', 'type', ('biog:asso','status','possession','posting','office-type','natal'), ''),    
    odd:transform('title', 'type', ('main','alt','translation'), ''),
    odd:transform('trait', 'type', ('household','ethnicity','tribe','mourning','parental-status'), ''),
    odd:transform('trait', 'subtype', 'biog:kin', '')}
    
return
    $el-spec