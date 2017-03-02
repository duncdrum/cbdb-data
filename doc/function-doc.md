# xQuery Function Documentation

## bibliography
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each column used in this conversion.  

### bib:bibl-dates

### bib:bibliography

### bib:roles
``distinct-values($TEXT_CODES//no:c_pub_range_code), distinct-values($TEXT_CODES//no:c_range_code))``
shows range 300, and 301 not to be in use.

#### TODO
* ``$TEXT_ROLE_CODES//no:c_role_desc_chn`` is currently dropped from db might go into ODD later


## module: genre
Joins the different location for bibliographical genre/ category data in one nested tei taxonomy. 
``TEXT_BIBL_CAT_TYPES_1``, and ``TEXT_BIBL_CAT_TYPES_2`` become superflous, 
since we have a nested tree using ``TEXT_BIBL_CAT_TYPES``, ``TEXT_BIBL_CAT_CODES``, and ``TEXT_BIBL_CAT_CODE_TYPE_REL``.

## biographies
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each column used in this conversion.  
### biog:kin 

#### 9 basic categories of kinship Source: CBDB Manual p 13f

none of these is symmetrical hence there is no need for mutuality checks as in biog:asso.

* ``'e'`` Ego (the person whose kinship is being explored) 
* ``'F'`` Father
* ``'M'`` Mother
* ``'B'`` Brother
* ``'Z'`` Sister
* ``'S'`` Son
* ``'D'`` Daughter
* ``'H'`` Husband
* ``'W'`` Wife
* ``'C'`` Concubine

* ``'+'`` Older (e.g. older brother B+, 兄)
* ``'-'`` Younger (e.g. younger sister 妹)
* ``'*'`` Adopted heir (as in S*, adopted son)
* ``'°'`` Adopted
* ``'!'`` Bastard
* ``'^'`` Step- (as in S^ step-son)
* ``'½'``  half- (as in Z½ , half-sister)
* ``'~'`` Nominal (as in M~ , legitimate wife as nominal mother to children of concubine)
* ``'%'`` Promised husband or wife (marriage not completed at time of record)
* ``'y'`` Youngest (e.g., Sy is the youngest known son)
* ``'1'`` Numbers distinguish sequence (e.g., S1, S2 for first and second sons; W1, W2 for the first and the successor wives)
* ``'n'`` precise generation unknown
* ``'G-#'``, ``'G+#'`` lineal ancestor (–) or descendant (+) of # generation №
* ``'G-n'``, ``'G+n'``, ``'Gn'`` lineal kin of an unknown earlier generation (G-n), or unknown later generation (G+n), or unknown generation (Gn)
* ``'G-#B'``, ``'BG+#'`` a brother of a lineal ancestor of # generation; a brother’s lineal descendant of # generation
* ``'K'``, ``'K-#'``, ``'K+#'``, ``'Kn'`` Lineage kin, of the same, earlier (–), later (+) or unknown (n) generation. CBDB uses “lineage kin” for cases where kinship is attested but the exact relationship is not known. Lineage kin are presumably not lineal (direct descent) kin.
* ``'K–'``, ``'K+'`` Lineage kin of the same generation, younger (-) or elder (+).
* ``'P'``, ``'P-#'``, ``'P+#'``, ``'Pn'`` Kin related via father’s sisters or mother’s siblings, of the same, earlier (–), later (+) or unknown (n) generation. Signified by the term biao (表) in Chinese. (CBDB uses these codes only when the exact relationship is not known). 
* ``'P–'``, ``'P+'`` Kin related via father's sisters or mother's siblings, of the same generation, younger (-) or elder (+).
* ``'A'`` Affine/Affinal kin, kin by marriage

#### NOT Documented
* ``'(male)'`` -> ♂
* ``'(female)'`` -> ♀
* ``'©'`` -> of concubine
* ``'(claimed)'`` -> 
* ``'(eldest surviving son)'`` -> 
* ``'(only ...)'`` ->
* ``'(apical)'`` ->


### biog:asso
whats up with ``$assoc_codes//no:c_assoc_role_type`` ?

#### TODO 
* consider ``chal-ZH`` dates for state
* ``c_assoc_claimer_id`` could get a ``@role`` somewhere around state
* ``c_assoc_range`` currently dropped.

### biog:status

#### TODO
* ``c_notes``, and ``c_supplement`` from ``STATUS_DATA`` are currently dropped. 

### biog:event

there is a number of unused cells here mostly because they are empty in the source files.

### biog:entry
add institutional addressess via ``biog:inst-add``

#### TODO
* why does ``c_exam_field`` not point to anything?
* see c_personid: ``914`` for dual ``@type`` entries
* ``c_inst_code`` only points to ``0`` no links to org to be written
* switch to ``tei:education`` | ``tei:faith`` for entry type data
 
### biog:new-post
we need to ascertian a few things about dates and ``POST_DATA`` here:
are there any instances where one contains data that is not isodate or in ``POSTED_TO_OFFICE_DATA``? 

whats up with ``POSTED_TO_ADDR_DATA``?

#### TODO
* Turn postings into ``tei:event``?
* check placement of ``@ref`` for ``c_addr_id`` compare possessions

### biog:posses
Currently there are only five entries (c_personid: ``18332``, ``13550``, ``45279``, ``45518``, ``3874``)

#### TODO
* make use of ``@ref="#PL..."`` consistent for all ``state`` elements. 

### biog:pers-add

#### TODO
* addd ``BIOG_ADDR_CODES//no:c_addr_note`` values to ODD

### biog:inst-add
There are no dates in the src tables. 

### biog:biog

#### TODO
* ``c_self_bio`` from ``$source`` is dropped change to attribute when refactoring query syntax?

## calendar
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each column used in this conversion. 

#### TODO
*  friggin YEAR_RANGE_CODES.xml
* many nianhaos aren't transliterated hence $NH-py
*  ``DYNASTIES`` contains both translations and transliterations:
     e.g. 'NanBei Chao' but 'Later Shu (10 states) more normalization *yay*
*  make 10states a ``@type`` ? 

### cal:custo-date-point
tricky with the data at hand, consequently not called by other function whenever possible. 
long run switch to CCDB date authority since that also covers korean and japanese dates. 

#### TODO
* getting to a somehwhat noramlized useful representation of Chinese Reign dates is tricky. Inconsinsten pinyin for Nianhao creates ambigous and ugly dates.
* handle ``//no:c_dy[. = 0]`` stuff
* add ``@period`` with ``#d42`` ``#R123``
* find a way to prevent empty attributes more and better logic FTW
* If only a dynasty is known lets hear it, the others are dropped since only a year or nianhao is of little information value. 

### cal:custo-date-range
See cal:custo-date-point

### cal:dynasties

### cal:ganzhi
Just for fun not used in the transformation. Calculate the ganzhi cycle for a given year (postive and negative), in either pinyin or hanzi.  

#### TEST
```
cal:ganzhi(2036, 'zh') -> 丙辰
cal:ganzhi(1981, 'zh') -> 辛酉
cal:ganzhi(1967, 'zh') -> 丁未
cal:ganzhi(0004, 'zh') -> 甲子
cal:ganzhi(0001, 'zh') -> 壬戌
cal:ganzhi(0000, 'zh') -> no such gYear 
cal:ganzhi(-0001, 'zh') -> 庚申
cal:ganzhi(-0247, 'zh') -> 乙卯 = 246BC founding of Qing
```

### cal:isodate

### cal:sexagenary

### cal:sqldate

## global
This module holds all the variables and paths used in the app. 

The list of variable decleartions pointing to the imported tables, is generated via ``local:table-variables`` in the ``aux.xql`` module. 

[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each table of CBDB and their use in  cbdbTEI. 

### global:create-mod-by
Processes the created-by and midfied by data found on each table. Only called for main tables. 

### global:validate-fragment
Helper function called by every write operation, to ease the burden of validating the whole file when working on a specific section.

## institutions
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each column used in this conversion. 

### org:org
the ``@role`` for ``org`` elements takes three values ``'academy'``, ``'buddhist'``, ``'daoist'`` . These need to be added to the ODD in chinese translation.

#### TODO
* careful this has a combined primary key between ``inst_name`` and ``inst_code``
* fix datable -custom stuff otherwise ok
* friggin ``YEAR_RANGE_CODES`` are back
* most of this fields in these tables are empty 

## office
Office is split over 2 xql files ``officeA.xql`` and ``officeB.xql``. 
This is due to a potential bug with new Range indexes raising a ``maxClauseCount`` error when 
running the full transformation from inside a single module. 
Splitting the module into two prevents the error from ocurring.

[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a 
spreadsheet listing each column used in this conversion. 

### local:office (officeA)

#### TODO

* figure out what the heck ``$OFFICE_CODE_TYPE_REl//no:c_office_type_type_code`` wants to be?


### local:nest-children (officeA)

### local:merge-officeTree (officeB)
there are:
28623 offices in office.xml
 1384 are not matched via OFFICE_CODE_TYPE_REL but have dynasty 
  514 are missing even dynastic affiliations


#### TODO
* fix missing links aka [@n = '']
* use: ```for $y allowing empty in $off...``` once exist supports it.
 
## place
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a 
spreadsheet listing each column used in this conversion. 

Currently cbdbTEI.xml does not yet use the more fine-grained possibilities of TEI to express geographic units, 
such as ``<bloc>``, ``,country>``, ``<district>``, etc. However, better integration with CHGIS via [TGAZ](http://maps.cga.harvard.edu/tgaz/) could void current shortcomings.  

### pla:fix-admin-types
There are 225 distinct types of adminstrative units in CBDB, however these contain many duplicates due to inconsistent spelling. 
Furthermore, white-spaces prevent the existing types from becoming xml attribute values. 
Hence this function normalises and concats the spelling of admin types without modifing the source. 
```
let $types := 
    distinct-values(($global:ADDR_CODES//no:c_admin_type, $global:ADDRESSES//no:c_admin_type))    
```
The use of whitespace in particular stands in further need of normalization. In the future this information is likely to be pulled from TGAZ. 

### pla:nest-places
One consequence of CBDB's entity model is that multiple  and usually overlapping timeseries occur, e.g c_addr_id ``4342`` has:

```
<location from="1368" to="1643"/>
<location from="1522" to="1522"/>
<location from="1544" to="1544">
```

cbdbTEI uses min/max of the distinct values to captures the data that is actually there 
(to be replaced by CHGIS soon). This approach cannot capture the (theoretical) case where

```                        
<location from="1368" to="1443"/>
<location from="1522" to="1622"/>
```
which could NOT be merged as ```<location from ="1368' to="1622"/>```

The following cells are never empty
```($ADDRESSES//no:c_admin_type, no:c_firstyear, no:c_lastyear)```

#### TODO
* currently only patched places refer to their main entries via @corresp,
  add matching attributes to the main entities. 
  
### pla:patch-missing-addr
We need to patch missing places because only a few places only exist in one location in the DB. 

