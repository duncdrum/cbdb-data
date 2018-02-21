xquery version "3.1";

(:~
 : aemni sparql queries
 : as long as i don't get the expected results 
 :
 : @see https://query.wikidata.org
 : @see https://github.com/ljo/exist-sparql/issues/6
 :
 : @author Duncan Paterson
 : @version 0.8.0
 :)
 
import module namespace sparql = "http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace config = "http://exist-db.org/apps/cbdb-data/config" at "config.xqm";

declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

declare variable $temp := $config:app-root || "/src/sparql/";

let $dy-sparql := ("PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
                PREFIX wd: <http://www.wikidata.org/entity/> 
                PREFIX wikibase: <http://wikiba.se/ontology#> 
                PREFIX bd: <http://www.bigdata.com/rdf#> 
                SELECT ?item ?itemLabel 
                WHERE { ?item wdt:P31 wd:Q836688.
                SERVICE wikibase:label { bd:serviceParam wikibase:language 'zh,en'. }
}")

let $dy-muli-sp := ("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                PREFIX wikibase: <http://wikiba.se/ontology#>
                PREFIX wd: <http://www.wikidata.org/entity/>
                PREFIX wdt: <http://www.wikidata.org/prop/direct/>

                SELECT DISTINCT ?item ?label (lang(?label) as ?label_lang)
                {
                ?item wdt:P31 wd:Q836688;
                
                rdfs:label ?label
                    filter(lang(?label) = 'zh' || lang(?label) = 'en')
}")

for $query in ($dy-sparql, $dy-sparql)
return
    sparql:query($query)