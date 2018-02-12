xquery version "3.1";

(:~
: Temporary working module.
: Replace local with name of target module
:
: @author Duncan Paterson
: @version 0.8.0
:)

import module namespace functx = "http://www.functx.com";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
(:import module namespace global = "http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
:)
import module namespace cal = "http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace no = "http://none";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace odd = "http://exist-db.org/apps/cbdb-data/odd";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";

(:declare default element namespace "http://www.tei-c.org/ns/1.0";:)

declare variable $path := collection($config:app-root || '/src/');
declare variable $model := $path/model/.;



declare function local:make-no-element-name($local-name as xs:string) {
(:~ A convenience function for creating element names in the no namespace :)
    QName("http://none", $local-name)
};


declare function local:find-table($table as xs:string?) as item()* {
(:~ 
: Identify the table that requires processing 
: TODO: maybe use maps for more efficient passing around?
: @returns table name as string
:)

let $n := $model//column[. = $table]
return
    local-name($n[1]/..)
};


declare function local:find-values($data as xs:string) as item()* {
(:~
: finds the unique values to populate odd:attVal list
:
: @param  $data column name 
: @return the column headers as string
:)

let $table := local:find-table($data)
let $col-path := $config:src-data || $table || '.xml'
(:let $name := local:make-no-element-name#1:)
for $n in doc($col-path)//*[local-name(.) eq $data]

return    
    distinct-values($n/text())
};


declare function local:transform (
    $odd-el as xs:string, 
    $odd-at as xs:string, 
    $src-el as xs:string*, 
    $src-gloss as xs:string*) as item()* {
(:~
: local:transform the distinct values of the source-tables into odd:attDef
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
                for $att in $odd-at
                return
                    element attDef { attribute ident {$odd-at},
                        attribute usage {'rec'},
                        attribute mode {'change'},
                            element gloss { $odd-el || ' should have ' || $odd-at || ' attribute'},
                            element datatype {
                                element rng:ref { attribute name {'datatype.Code'} }
                            },
                            element valList {        
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
        }
};



(:    local:find-values('c_name_type_desc_chn'):)

let $tmpl := doc('/db/apps/cbdb-data/templates/tei/cbdbTEI-template.xml')
let $el-spec := element root { 
    local:transform('addName', 'type', 'choronym', 'combination of place name and clan name'),
    local:transform('availability', 'status', 'restricted', ''),
    local:transform('bibl', 'subtype', 'bib:bib', ''),    
    local:transform('bibl', 'type', 'bib:bib', ''),
    local:transform('category', 'n', 'local:office', ''),    
    local:transform('date', 'type', ('original','published'), ''),
    local:transform('desc', 'type', ('kin-tie','biog:asso','biog:entry'), ''),
    local:transform('desc', 'n', 'biog:asso', ''),    
    local:transform('desc', 'ana', ('topic','genre','七色補官門','7specials'), ''),
    local:transform('desc', 'subtype', 'biog:entry', ''),    
    local:transform('event', 'role', '#BIO', ''),
    local:transform('event', 'type', ('general','biog:entry'), ''),
    local:transform('event', 'subtype', 'biog:entry', ''),
    local:transform('idno', 'type', ('TTS','CHGIS','VIAF', "UUID"), ''),    
    local:transform('listRelation', 'type', ('kinship','associations'), ''),
    local:transform('mapping', 'type', ('Unicode','standard'), ''),    
    local:transform('note', 'type', ('field','attempts','rank','parental-status','created','modified'), ''),    
    local:transform('org', 'role', 'org:org', ''),
    local:transform('org', 'ana', 'historical', ''),    
    local:transform('orgName', 'type', ('main','alias'), ''),
    local:transform('persName', 'role', 'mediator', ''),
    local:transform('persName', 'type', ('main','original','alias'), ''),    
    local:transform('person', 'ana', 'historical', ''),    
    local:transform('person', 'resp', 'selfbio', 'Tracks whatever c_self_bio tracks in CBDB'),
    local:transform('personGrp', 'role', ('kin','associates'), ''),
    local:transform('place', 'type', 'pla:fix-admin-types', ''),    
    local:transform('placeName', 'type', 'alias', ''),
    local:transform('relation', 'type', 'auto-generated', ''),
    local:transform('relation', 'name', ('biog:kin','biog:asso'), ''),    
    local:transform('residence', 'n', 'biog:pers-add', ''),
    local:transform('roleName', 'type', ('main','alt'), ''),
    local:transform('sex', 'value', 'biog:biog', ''),    
    local:transform('state', 'n', ('biog:status','biog:posses','biog:new-post'), ''),
    local:transform('state', 'ana', 'biog:asso', ''),
    local:transform('state', 'subtype', ('biog:asso','biog:status','biog:posses'), ''),
    local:transform('state', 'type', ('biog:asso','status','possession','posting','office-type','natal'), ''),    
    local:transform('title', 'type', ('main','alt','translation'), ''),
    local:transform('trait', 'type', ('household','ethnicity','tribe','mourning','parental-status'), ''),
    local:transform('trait', 'subtype', 'biog:kin', '')}
    
return
    $el-spec
        
    
        (:if (count(data($el-spec//elementSpec/@ident)) > 1)
        then ($n/attList)
        else ($n):)







