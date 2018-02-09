xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module. incorporating former global module. 
 :
 : @author Duncan Paterson
 : @version 0.8.0
 :)
 
module namespace config="http://exist-db.org/apps/cbdb-data/config";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

(: General :)
declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;
declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:src-data := $config:app-root || "/src/xml/";
declare variable $config:target-data := $config:app-root || "/target/";
declare variable $config:target-aemni := $config:app-root || "/data/";

declare variable $config:report := $config:app-root || "/reports/";
declare variable $config:patch := $config:app-root || "/reports/patch/";
declare variable $config:samples := $config:app-root || "/samples/";
declare variable $config:modules := $config:app-root || "/modules/";
declare variable $config:doc := $config:app-root || "/doc/";

(:THE TEI FILES IN TARGET:)
declare variable $config:genre := 'biblCat.xml';
declare variable $config:calendar := 'cal_ZH.xml';
declare variable $config:gaiji := 'charDecl.xml';
declare variable $config:bibliography := 'listBibl.xml';
declare variable $config:institution := 'listOrg.xml';
declare variable $config:place := 'listPlace.xml';
declare variable $config:office := 'office.xml';
declare variable $config:office-temp := 'officeA.xml';
declare variable $config:main := 'cbdbTEI.xml';
declare variable $config:person := 'listPerson';

(:CBDB source tables :)
declare variable $config:ADDRESSES := doc($config:src-data || 'ADDRESSES.xml');
declare variable $config:ADDR_BELONGS_DATA := doc($config:src-data || 'ADDR_BELONGS_DATA.xml');
declare variable $config:ADDR_CODES := doc($config:src-data || 'ADDR_CODES.xml');
declare variable $config:ADDR_PLACE_DATA := doc($config:src-data || 'ADDR_PLACE_DATA.xml');
declare variable $config:ADDR_XY := doc($config:src-data || 'ADDR_XY.xml');
declare variable $config:ALTNAME_CODES := doc($config:src-data || 'ALTNAME_CODES.xml');
declare variable $config:ALTNAME_DATA := doc($config:src-data || 'ALTNAME_DATA.xml');
declare variable $config:APPOINTMENT_TYPE_CODES := doc($config:src-data || 'APPOINTMENT_TYPE_CODES.xml');
declare variable $config:ASSOC_CODES := doc($config:src-data || 'ASSOC_CODES.xml');
declare variable $config:ASSOC_CODE_TYPE_REL := doc($config:src-data || 'ASSOC_CODE_TYPE_REL.xml');
declare variable $config:ASSOC_DATA := doc($config:src-data || 'ASSOC_DATA.xml');
declare variable $config:ASSOC_TYPES := doc($config:src-data || 'ASSOC_TYPES.xml');
declare variable $config:ASSUME_OFFICE_CODES := doc($config:src-data || 'ASSUME_OFFICE_CODES.xml');
declare variable $config:BIOG_ADDR_CODES := doc($config:src-data || 'BIOG_ADDR_CODES.xml');
declare variable $config:BIOG_ADDR_DATA := doc($config:src-data || 'BIOG_ADDR_DATA.xml');
declare variable $config:BIOG_INST_CODES := doc($config:src-data || 'BIOG_INST_CODES.xml');
declare variable $config:BIOG_INST_DATA := doc($config:src-data || 'BIOG_INST_DATA.xml');
declare variable $config:BIOG_MAIN := doc($config:src-data || 'BIOG_MAIN.xml');
declare variable $config:BIOG_SOURCE_DATA := doc($config:src-data || 'BIOG_SOURCE_DATA.xml');
declare variable $config:CHORONYM_CODES := doc($config:src-data || 'CHORONYM_CODES.xml');
declare variable $config:COUNTRY_CODES := doc($config:src-data || 'COUNTRY_CODES.xml');
declare variable $config:CopyMissingTables := doc($config:src-data || 'CopyMissingTables.xml');
declare variable $config:CopyTables := doc($config:src-data || 'CopyTables.xml');
declare variable $config:CopyTablesDefault := doc($config:src-data || 'CopyTablesDefault.xml');
declare variable $config:DATABASE_LINK_CODES := doc($config:src-data || 'DATABASE_LINK_CODES.xml');
declare variable $config:DATABASE_LINK_DATA := doc($config:src-data || 'DATABASE_LINK_DATA.xml');
declare variable $config:DYNASTIES := doc($config:src-data || 'DYNASTIES.xml');
declare variable $config:ENTRY_CODES := doc($config:src-data || 'ENTRY_CODES.xml');
declare variable $config:ENTRY_CODE_TYPE_REL := doc($config:src-data || 'ENTRY_CODE_TYPE_REL.xml');
declare variable $config:ENTRY_DATA := doc($config:src-data || 'ENTRY_DATA.xml');
declare variable $config:ENTRY_TYPES := doc($config:src-data || 'ENTRY_TYPES.xml');
declare variable $config:ETHNICITY_TRIBE_CODES := doc($config:src-data || 'ETHNICITY_TRIBE_CODES.xml');
declare variable $config:EVENTS_ADDR := doc($config:src-data || 'EVENTS_ADDR.xml');
declare variable $config:EVENTS_DATA := doc($config:src-data || 'EVENTS_DATA.xml');
declare variable $config:EVENT_CODES := doc($config:src-data || 'EVENT_CODES.xml');
declare variable $config:EXTANT_CODES := doc($config:src-data || 'EXTANT_CODES.xml');
declare variable $config:FIX_AUTHORS := doc($config:src-data || 'FIX_AUTHORS.xml');
declare variable $config:ForeignKeys := doc($config:src-data || 'ForeignKeys.xml');
declare variable $config:FormLabels := doc($config:src-data || 'FormLabels.xml');
declare variable $config:GANZHI_CODES := doc($config:src-data || 'GANZHI_CODES.xml');
declare variable $config:HOUSEHOLD_STATUS_CODES := doc($config:src-data || 'HOUSEHOLD_STATUS_CODES.xml');
declare variable $config:KINSHIP_CODES := doc($config:src-data || 'KINSHIP_CODES.xml');
declare variable $config:KIN_DATA := doc($config:src-data || 'KIN_DATA.xml');
declare variable $config:KIN_MOURNING_STEPS := doc($config:src-data || 'KIN_MOURNING_STEPS.xml');
declare variable $config:KIN_Mourning := doc($config:src-data || 'KIN_Mourning.xml');
declare variable $config:LITERARYGENRE_CODES := doc($config:src-data || 'LITERARYGENRE_CODES.xml');
declare variable $config:MEASURE_CODES := doc($config:src-data || 'MEASURE_CODES.xml');
declare variable $config:NIAN_HAO := doc($config:src-data || 'NIAN_HAO.xml');
declare variable $config:OCCASION_CODES := doc($config:src-data || 'OCCASION_CODES.xml');
declare variable $config:OFFICE_CATEGORIES := doc($config:src-data || 'OFFICE_CATEGORIES.xml');
declare variable $config:OFFICE_CODES := doc($config:src-data || 'OFFICE_CODES.xml');
declare variable $config:OFFICE_CODES_CONVERSION := doc($config:src-data || 'OFFICE_CODES_CONVERSION.xml');
declare variable $config:OFFICE_CODE_TYPE_REL := doc($config:src-data || 'OFFICE_CODE_TYPE_REL.xml');
declare variable $config:OFFICE_TYPE_TREE := doc($config:src-data || 'OFFICE_TYPE_TREE.xml');
declare variable $config:OFFICE_TYPE_TREE_backup := doc($config:src-data || 'OFFICE_TYPE_TREE_backup.xml');
declare variable $config:PARENTAL_STATUS_CODES := doc($config:src-data || 'PARENTAL_STATUS_CODES.xml');
declare variable $config:PLACE_CODES := doc($config:src-data || 'PLACE_CODES.xml');
declare variable $config:POSSESSION_ACT_CODES := doc($config:src-data || 'POSSESSION_ACT_CODES.xml');
declare variable $config:POSSESSION_ADDR := doc($config:src-data || 'POSSESSION_ADDR.xml');
declare variable $config:POSSESSION_DATA := doc($config:src-data || 'POSSESSION_DATA.xml');
declare variable $config:POSTED_TO_ADDR_DATA := doc($config:src-data || 'POSTED_TO_ADDR_DATA.xml');
declare variable $config:POSTED_TO_OFFICE_DATA := doc($config:src-data || 'POSTED_TO_OFFICE_DATA.xml');
declare variable $config:POSTING_DATA := doc($config:src-data || 'POSTING_DATA.xml');
declare variable $config:SCHOLARLYTOPIC_CODES := doc($config:src-data || 'SCHOLARLYTOPIC_CODES.xml');
declare variable $config:SOCIAL_INSTITUTION_ADDR := doc($config:src-data || 'SOCIAL_INSTITUTION_ADDR.xml');
declare variable $config:SOCIAL_INSTITUTION_ADDR_TYPES := doc($config:src-data || 'SOCIAL_INSTITUTION_ADDR_TYPES.xml');
declare variable $config:SOCIAL_INSTITUTION_ALTNAME_CODES := doc($config:src-data || 'SOCIAL_INSTITUTION_ALTNAME_CODES.xml');
declare variable $config:SOCIAL_INSTITUTION_ALTNAME_DATA := doc($config:src-data || 'SOCIAL_INSTITUTION_ALTNAME_DATA.xml');
declare variable $config:SOCIAL_INSTITUTION_CODES := doc($config:src-data || 'SOCIAL_INSTITUTION_CODES.xml');
declare variable $config:SOCIAL_INSTITUTION_CODES_CONVERSION := doc($config:src-data || 'SOCIAL_INSTITUTION_CODES_CONVERSION.xml');
declare variable $config:SOCIAL_INSTITUTION_NAME_CODES := doc($config:src-data || 'SOCIAL_INSTITUTION_NAME_CODES.xml');
declare variable $config:SOCIAL_INSTITUTION_TYPES := doc($config:src-data || 'SOCIAL_INSTITUTION_TYPES.xml');
declare variable $config:STATUS_CODES := doc($config:src-data || 'STATUS_CODES.xml');
declare variable $config:STATUS_CODE_TYPE_REL := doc($config:src-data || 'STATUS_CODE_TYPE_REL.xml');
declare variable $config:STATUS_DATA := doc($config:src-data || 'STATUS_DATA.xml');
declare variable $config:STATUS_TYPES := doc($config:src-data || 'STATUS_TYPES.xml');
declare variable $config:TEXT_BIBLCAT_CODES := doc($config:src-data || 'TEXT_BIBLCAT_CODES.xml');
declare variable $config:TEXT_BIBLCAT_CODE_TYPE_REL := doc($config:src-data || 'TEXT_BIBLCAT_CODE_TYPE_REL.xml');
declare variable $config:TEXT_BIBLCAT_TYPES := doc($config:src-data || 'TEXT_BIBLCAT_TYPES.xml');
declare variable $config:TEXT_BIBLCAT_TYPES_1 := doc($config:src-data || 'TEXT_BIBLCAT_TYPES_1.xml');
declare variable $config:TEXT_CODES := doc($config:src-data || 'TEXT_CODES.xml');
declare variable $config:TEXT_DATA := doc($config:src-data || 'TEXT_DATA.xml');
declare variable $config:TEXT_ROLE_CODES := doc($config:src-data || 'TEXT_ROLE_CODES.xml');
declare variable $config:TEXT_TYPE := doc($config:src-data || 'TEXT_TYPE.xml');
declare variable $config:TablesFields := doc($config:src-data || 'TablesFields.xml');
declare variable $config:TablesFieldsChanges := doc($config:src-data || 'TablesFieldsChanges.xml');
declare variable $config:TangBureaucraticTree := doc($config:src-data || 'TangBureaucraticTree.xml');
declare variable $config:YEAR_RANGE_CODES := doc($config:src-data || 'YEAR_RANGE_CODES.xml');
declare variable $config:tmpBM_NIY := doc($config:src-data || 'tmpBM_NIY.xml');
declare variable $config:tmpBM_NIY_finished := doc($config:src-data || 'tmpBM_NIY_finished.xml');
declare variable $config:tmpIndexYear := doc($config:src-data || 'tmpIndexYear.xml');


(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};