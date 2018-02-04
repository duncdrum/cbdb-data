# TEI encoding guidelines
## Contents
*   [Introduction](#introduction)
    *   [About this document](#about-this-document)
*   [Basic encoding decisions](#basic-encoding-decisions)
*   [General encoding decisions](#general-encoding-decisions)
    *   [Languages](#languages)
    *   [Dates](#dates)
*   [Header](#header)
    *   [fileDesc](#filedesc)
    *   [encodingDesc](#encodingdesc)
        *   [listPrefixDef](#listprefixdef)
        *   [charDecl](#chardecl)
        *   [classDesc](#classdesc)
            *   [biblCat](#biblcat)
            *   [cal_ZH](#cal_zh)
            *   [office](#office)
    *   [profileDesc and revisionDesc](#profiledesc-and-revisiondesc)
        *   [revisionDesc](#revisiondesc)
        *   [langUsage](#langusage)
        *   [calendarDesc](#calendardesc)    
*   [body](#body)
    *   [person](#person)
        *   [persName](#persname)
        *   [other](#other)
    *   [org](#org)
    *   [place](#place)
    *   [bibl](#bibl)
    *   [Appendix](#appendix)     



## Introduction
To facilitate my own needs for semi-automated annotation of historical Chinese documents I encountered either competing authority institutions, or an absence of the kind of reference points that enable linked open data applications. In particular with respect to prosopographical data, the most comprehensive data collection [*China Biographical Database*](http://projects.iq.harvard.edu/cbdb/home) provided only limited means for retrieving machine readable data. *CBDB in TEI* is a xml application that follows the [TEI-P5](http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ST.html) encoding guidelines. It can be installed and used along other tools that all facilitate xml oriented workflows of academic editing.

Transforming the contents of a relational database  into TEI is very different from transcribing source documents. The primary challenge consists of finding fitting tei-xml elements for every column in *CBDB*’s tables. The other challenge was to write performative transformation scripts that can handle missing data points or errors in the input data, such as an event dated to: ``1234-02-30``.

### About this document
This document describes the encoding decisions behind *CBDB in TEI*. It is not a replacement of the original TEI documentation, and covers only those elements and attributes that are actually used by the project. The documentation and explanation of the various xQuery programs used in the transformation from SQLite to xml are located in the [function documentation](/function-doc.md).

## Basic encoding decisions
Conceptually, *CBDB in TEI* encodes all aspects of *CBDB* in a single tei-xml document ``cbdbTEI.xml``, without using special elements. In the future, *CBDB in TEI* is likely to also make use of ``<xenodata>`` for replacing *CBDB*’s GIS components with a better suited data format based on [*China Historical GIS*](http://www.fas.harvard.edu/~chgis/), and [*TGAZ*](https://github.com/vajlex/tgaz).
This is the skeleton of ``cbdbTEI.xml`` (some elements are omitted —see [``cbdbTEI-template.xml``](../templates/tei/cbdb-TEI-template.xml) for the complete example):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"?>
<?xml-model href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schematypens="http://purl.oclc.org/dsdl/schematron"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>…</titleStmt>
            <publicationStmt>
                <availability>
                    <licence target="https://creativecommons.org/licenses/by-sa/4.0/">cc-by-sa 4.0</licence>
                </availability>
            </publicationStmt>
            <sourceDesc>…</sourceDesc>
        </fileDesc>
        <encodingDesc>
            <classDecl>
                <taxonomy xml:id="biblCat">…</taxonomy>
                <taxonomy xml:id="cal_ZH">…</taxonomy>
                <taxonomy xml:id="office">…</taxonomy>
            </classDecl>
            <charDecl>…</charDecl>
            <listPrefixDef>…</listPrefixDef>
        </encodingDesc>
        <profileDesc>
            <langUsage>…</langUsage>
            <calendarDesc>…</calendarDesc>
        </profileDesc>
        <revisionDesc>
            <change when="…" who="…">…</change>
        </revisionDesc>
    </teiHeader>
    <text>
        <body>
            <listPerson>…</listPerson>
            <listOrg>…</listOrg>
            <listPlace>…</listPlace>
            <listBibl>…</listBibl>
        </body>
    </text>
</TEI>
```

Logically, ``cbcbTEI.xml`` is root of over 350000 xml fragments which are connected using [xInclude](https://www.w3.org/TR/xinclude/) statements and additional intermediary xml files for storing lists of such statements. The details of the logical file hierarchy’s production see the [function documentation](function-doc.md). The files to be expanded into ``cbcbTEI.xml`` are: ``biblCat.xml``, ``cal_ZH.xml``, ``charDecl.xml``, ``listBibl.xml``, ``listOrg.xml``, ``listPlace.xml``, and ``office.xml``, as well as the contents of the directory ``/listPerson’’ where the bulk of the fragments resides.

## General encoding decisions
Encoding patterns that apply to multiple or all parts of *CBDB in TEI*.

### Languages
The encoding pattern of *CBDB in TEI* emulates the multilingual structure of *CBDB*, instead of separating Chinese and English descriptions via TEI’s internationalization options. This means that element and attribute names are in English. TEI already provides a [localized](http://www.tei-c.org/Tools/I18N/) version of the guidelines in Chinese, but this has not been tested. Automatic translation of the custom schema should however be easy. While the large majority of attribute values sticks to ASCII characters, use of UTF-8 is also permitted when considered necessary. Whenever the original language is machine-readable in the source, multilingual element values appear in a fixed sequence: original, transliteration, translation. For a full list of machine-readable languages see [langUsage](#langUsage) below.

With the improved support for unicode in xml over the relational database format of the source *CBDB in TEI* uses UTF-8 encoding, double-byte encoded characters have to be converted into UTF-8 representations, see [charDecl](#charDecl) for details.

### Dates
Since TEI guidelines allow for various ways of encoding dates, *CBDB in TEI* opted for strict ISO-8601 conformance for Western dates. In other words we use ``@when`` for Western dates, and ``@when-custom`` for Chinese dates, see [calendarDesc](#calendarDesc) for details, ``@when-iso`` is never used.

Even converting Western dates required some adjustments, because the date fields in *CBDB* do not seem to adhere to any standard for encoding dates. While converting ``1234/2/21`` into ``1234-02-21`` is straightforward, many instances of impossible dates appear in the source, and had to be corrected.

It is not clear if *CBDB* is consistent in its adherence to the historical or astronomical interpretation of the Gregorian calendar. Chinese dates are all converted to astronomical counting so that the year ``0001`` is preceded by ``-0001``, and not ``0000`` as in BC/BCE counting. However, ``c_year`` fields that contain negative dates are converted to ``YYYY`` without adding or subtracting ``1``.

Should the [EDTF](http://www.loc.gov/standards/datetime/pre-submission.html) proposal be included in the ISO standard, this notation could be adopted here, until then in cases where only year and day is known, but months are unknown e.g.: ``1234-uu-02`` the day is missing from the tei-xml and only the year ``1234`` value appears.

## Header
The following section introduces the elements contained by the ``<teiHeader>`` paying special attention where their contents go beyond the minimal requirements of the TEI guidelines.               

### fileDesc
Contains the mandatory information regarding the file itself, and its creator. In addition, it includes the [CC-BY-SA](https://creativecommons.org/licenses/by-sa/4.0/) 4.0 license statement. The ``<respStmt>`` element contains all identifiable contributors and modifiers of *CBDB* that are explicitly mentioned in the ``<body>``.

### encodingDesc
This element has three parts: ``<classDecl>``, ``<charDecl>``, and ``<listPrefixDef>``.   Class and character declaration contain xInclude statements pointing to external files, while the list of prefix Definitions is directly created from the data source.

```xml
<encodingDesc>
    <classDecl>
        <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="biblCat.xml" parse="xml"/>
        <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="cal_ZH.xml" parse="xml"/>
        <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="office.xml" parse="xml"/>
    </classDecl>
    <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="charDecl.xml" parse="xml"/>
    <listPrefixDef>
        <prefixDef ident="idtf" matchPattern="([.]*)" replacementPattern="http://tkb.zinbun.kyoto-u.ac.jp/pers-db/$1"/>
        …  
    </listPrefixDef>
</encodingDesc>
```


#### listPrefixDef
Contains three ``<prefixDef>`` elements capturing data necessary to construct full URI’s stored in *CBDB*’s ``DATABASE_LINK_CODES``, and ``DATABASE_LINK_DATA``. The ttsweb links to Academia Sinica however are broken.

#### charDecl
Since historical Chinese data often irregular Character variants, which are hard to capture in *CBDB*’s native format, *CBDB in TEI* includes a place for capturing this data. Irregular characters appearing anywhere in the document should be encoded using the ``<g>`` element. The character declaration provides a central place to store such variants and to provide a standardized form for searching and processing.

Each unique glyph requires an ``@xml:id`` starting with the letters” ```GAI``` (for gaiji). The descriptions of the irregular character in question must follow the guidelines for the use of ideographic description characters of section 18.2 of the [unicode standard](http://www.unicode.org/versions/Unicode9.0.0/ch18.pdf). In addition, descriptions should prioritize visual equivalence over semantic equivalence, e.g.: ``𬇕`` =
``氵⿰万`` not ``水⿰萬`` (see *ibid* Figure 18-8 example 6 p. 691).

```xml
<charDecl>
    <glyph xml:id="GAI1">
        <mapping type="Unicode">⿸虍⿻夂丷⿱目</mapping>
        <mapping type="standard">𧇖</mapping>
    </glyph>
    …
</charDecl>
```

#### classDesc
The class description contains three main taxonomies with the following ``@xml:id``s: ``biblCat``, ``cal_ZH``, ``office``. These capture in order: bibliographical genre classification, Chinese Calendar Dates, and bureaucratic offices. Each generated by a separate xQuery function module.

##### biblCat
A taxonomy of nested bibliographical classification categories. Each ``<category>`` has an ``@xml:id`` starting with either: ``biblCat`` or ``biblType`` depending on its originating table in the source. The root category is ``Chinese Primary Texts`` in the future a better alignment with externally provided and authoritative controlled vocabularies is desirable.
These categories are mainly referenced by the bibliographic elements in ``<listBibl>``.

```xml
<taxonomy xml:id="biblCat">
    <category xml:id="biblType">
        <catDesc xml:lang="zh-Hant">gen:nest-types</catDesc>
        <catDesc xml:lang="zh-Latn-alalc97">gen:nest-types</catDesc>
        …
    </category>
</taxonomy>
```

##### cal_ZH
This taxonomy encompasses two further ``<taxonomy>`` elements, one to capture the permutations of the sexagenary cycle (``@xml:id="sexagenary"``), and one to cover traditional dynastic reign dates (``@xml:id="reign"``). The latter, contains an additional empty ``<date>`` element with ``@from`` / ``@to`` attributes to record beginning and end year of the period encoded by each category.

This taxonomy is used to resolve Chinese dates throughout the database. As with the bibliographical classification scheme, future developments are likely to focus on integration with external authority files for East Asian Dates, such as [*DDBC*](http://authority.ddbc.edu.tw/).

```xml
<taxonomy xml:id="cal_ZH">
    <taxonomy xml:id="sexagenary">
        <category xml:id="S">
            <catDesc xml:lang="zh-Hant">cal:sexagenary</catDesc>
            <catDesc xml:lang="zh-Latn-alalc97">cal:sexagenary</catDesc>
            …
        </category>
    </taxonomy>
    <taxonomy xml:id="reign">
        <category xml:id="D">
            <catDesc>
                <date from="0001" to="0001"/>
            </catDesc>
            <catDesc xml:lang="zh-Hant">cal:dynasties</catDesc>
            <catDesc xml:lang="zh-Latn-alalc97">cal:dynasties</catDesc>
            …
        </category>
    </taxonomy>
</taxonomy>
```

##### office
The taxonomy for administrative offices consists of nested category whose position corresponds to the location within the bureaucratic hierarchy. The category description of each category contains the name of the office as ``<roleName>``.  There are two possible values for the ``@type`` attribute: ``main``, and ``alt``. The main roleName may contain an additional ``<note>`` element. The category description also includes a date element, to denote  the dynasty in which a certain office was established.

```xml
<taxonomy xml:id="office">
    <category xml:id="OFF" n="local:office" source="#BIB">
        <catDesc>
            <roleName type="main">
                <roleName xml:lang="zh-Hant">local:office</roleName>
                <roleName xml:lang="zh-Latn-alalc97">local:office</roleName>
                <roleName xml:lang="en">local:office</roleName>
                <note>local:office</note>
            </roleName>
            <roleName type="alt">
                <roleName xml:lang="zh-Hant">local:office</roleName>
                <roleName xml:lang="zh-Latn-alalc97">local:office</roleName>
                <roleName xml:lang="en">local:office</roleName>
            </roleName>
            <date calendar="#chinTrad" period="#D">local:office</date>
        </catDesc>
    </category>
</taxonomy>
```

### profileDesc and revisionDesc
The ``<profileDesc>`` contains two mandatory child elements followed by the ``<revisionDesc>``:

```xml
<profileDesc>
    <langUsage>
        <language ident="…">…</language>
        …
    </langUsage>
    <calendarDesc>
        <calendar xml:id="chinTrad">
            <p>…</p>
        </calendar>
    </calendarDesc>
</profileDesc>
<revisionDesc>
    <change when="…" who="…">…</change>
</revisionDesc>
```

### revisionDesc
The revision description tracks substantial changes to the TEI files, usually coinciding with a major/minor version update to the GitHub repository. The source’s own tracking of modifications is do not belong into this field. Bulk changes should be grouped together into a single ``<change>`` statement.
Each change requires a date and a person responsible for the change (``@when``, ``@who``).

#### langUsage
*CBDB* contains languages other then English and Chinese, however, these are not tagged in a machine readable fashion. Every language occurring in the source must be indicated here, following the ISO 639-1 format, which is referenced via ``@xml:lang``. Once of the advantages of converting *CBDB* into TEI, come from the fact that adding new languages or language variants doesn’t require a major redesign of any relational table structures. Properly indicating Manchu, Mongolian, Tibetan, etc. contents would be of great help for future extensions.

A special note on *CBDB*’s use of pinyin. The use of ``@xml:lang="zh-Latn-alalc97"`` suggests greater regularity then is present in the source. With competing standards for things like word separation, use of diacritics, etc.*CBDB* is not consistently following one set of rules. The above seemed to be the closest rule-set for what is in the data, but I have made no further attempts at normalization.

#### calendarDesc
Since, *CBDB in TEI* makes extensive use of custom calendar dates, this prose description of calendar in use is mandatory.

## body
Conceptually, the body contains of four list elements, which contain data for the main entities of *CBDB*:

*   ``<listPerson>``
*   ``<listOrg>``
*   ``<listPlace>``
*   ``<listBibl>``

Of these four lists, listPerson is special. Because of its size this list is split into 37 chunks, which are further split into smaller units (blocks). For the exact composition see the [function documentation](function-doc.md#biographies).

### person
Not only are ``<person>`` elements the most numerous, they can also contain the most child elements in the whole database.

*CBDB* only contains data on historical persona, hence each element receives a mandatory ``@ana="historical"`` attribute. Each person must have a unique ``@xml:id`` starting with ``BIO``. Further optional attributes are: ``@source`` for references to the text used by *CBDB* to generate the person entry, and ``@resp`` for case where ``selfbio`` was indicated.

```xml
<person ana="historical" xml:id="BIO" source="#BIB" resp="selfbio">
…     
```

#### persName


```xml
…
<persName type="main">
    <persName xml:lang="zh-Hant">
        <surname>biog:name</surname>
        <forename>biog:name</forename>
        <addName type="choronym">biog:name</addName>
    </persName>
    <persName xml:lang="zh-Latn-alalc97">
        <surname>biog:name</surname>
        <forename>biog:name</forename>
        <addName type="choronym">biog:name</addName>
    </persName>
    <persName type="original">
        <surname>biog:name</surname>
        <forename>biog:name</forename>
    </persName>
    <persName type="original">biog:name</persName>
</persName>
<persName type="alias" key="AKA" source="#BIB">
    <addName xml:lang="zh-Hant">biog:alias</addName>
    <term>biog:alias</term>
    <addName xml:lang="zh-Latn-alalc97">biog:alias</addName>
    <term>biog:alias</term>
    <note>biog:alias</note>
</persName>
…
```

#### age

```xml
…
<birth when="0001-01-01" datingMethod="#chinTrad" when-custom="D-R-Y">
    <date calendar="#chinTrad" period="#R">biog:biog</date>
</birth>
<death when="0001-01-01" datingMethod="#chinTrad" when-custom="D-R-Y">
    <date calendar="#chinTrad" period="#R">biog:biog</date>
</death>
<floruit notBefore="0001" notAfter="0001">
    <date when="0001" datingMethod="#chinTrad" period="#D">biog:biog</date>
    <note>biog:biog</note>
</floruit>
<age cert="medium">biog:biog</age>
…
```

#### trait

```xml
…
<trait type="household" key="biog:biog">
    <label xml:lang="zh-Hant">biog:biog</label>
    <label xml:lang="en">biog:biog</label>
</trait>
<trait type="ethnicity" key="biog:biog">
    <label>biog:biog</label>
    <desc xml:lang="zh-Hant">biog:biog</desc>
    <desc xml:lang="zh-Latn-alalc97">biog:biog</desc>
    <desc xml:lang="en">biog:biog</desc>
    <note>biog:biog</note>
</trait>
<trait type="tribe">
    <label>biog:biog</label>
</trait>
…
```


#### affiliation


```xml
…
<affiliation>
    <note> <!--I do not like this note wrapper one bit-->
        <listPerson>
            <personGrp role="kin"/>
            <listRelation type="kinship">
                <relation active="#BIO" passive="#BIO" key="biog:kin" sortKey="biog:kin" name="biog:kin" source="biog:kin" type="auto-generated">
                    <desc type="kin-tie">
                        <label>biog:kin</label>
                        <desc xml:lang="zh-Hant">biog:kin</desc>
                        <desc xml:lang="en">biog:kin</desc>
                        <trait type="mourning" subtype="biog:kin">
                            <label xml:lang="zh-Hant">biog:kin</label>
                            <desc xml:lang="zh-Hant">biog:kin</desc>
                            <desc xml:lang="en">biog:kin</desc>
                        </trait>
                    </desc>
                </relation>
            </listRelation>
        </listPerson>
    </note>
    <note> <!--I do not like this note wrapper one bit-->
        <listPerson>
            <personGrp role="associates"/>
            <listRelation type="associations">
                <relation mutual="biog:asso" name="biog:asso" key="biog:asso" sortKey="biog:asso" source="#BIB">
                    <desc type="biog:asso" n="biog:asso">
                        <label>biog:asso</label>
                        <desc xml:lang="zh-Hant">biog:asso<label>biog:asso</label>
                        </desc>
                        <desc xml:lang="en">biog:asso<label>biog:asso</label>
                        </desc>
                        <state ref="#PL #ORG" when="0001" ana="biog:asso" type="biog:asso" subtype="biog:asso">
                            <label xml:lang="zh-Hant">biog:asso</label>
                            <label xml:lang="zh-Latn-alalc97">biog:asso</label>
                            <desc ana="topic">biog:asso</desc>
                            <desc xml:lang="zh-Hant">biog:asso<label>biog:asso</label>
                            </desc>
                            <desc xml:lang="en">biog:asso<label>biog:asso</label>
                            </desc>
                        </state>
                        <desc ana="genre">
                            <label xml:lang="zh-Hant">biog:asso</label>
                            <label xml:lang="en">biog:asso</label>
                        </desc>
                        <desc>
                            <persName role="mediator" ref="#BIO"/>
                        </desc>
                    </desc>
                </relation>
            </listRelation>
        </listPerson>
    </note>
</affiliation>
…
```

#### socecStatus

```xml
…
<socecStatus>
    <state type="status" subtype="biog:status" from="0001" to="0001" n="biog:status" source="#BIB">
        <desc xml:lang="zh-Hant">biog:status</desc>
        <desc xml:lang="en">biog:status</desc>
    </state>
</socecStatus>
<socecStatus scheme="#office" code="#OFF">
    <state type="posting" ref="#PL" n="biog:new-post" key="biog:new-post" notBefore="0001" notAfter="0001" source="#BIB">
        <desc>
            <label>appointment</label>
            <desc xml:lang="zh-Hant">biog:new-post</desc>
            <desc xml:lang="en">biog:new-post</desc>
        </desc>
        <desc>
            <label>assumes</label>
            <desc xml:lang="zh-Hant">biog:new-post</desc>
            <desc xml:lang="en">biog:new-post</desc>
        </desc>
        <note>biog:new-post</note>
    </state>
    <state type="office-type" n="biog:new-post">
        <desc xml:lang="zh-Hant">biog:new-post</desc>
        <desc xml:lang="en">biog:new-post</desc>
        <note>biog:new-post</note>
    </state>
</socecStatus>
…
<state type="possession" xml:id="POS" unit="biog:posses" quantity="1" n="biog:posses" when="0001" source="#BIB" subtype="biog:posses">
    <desc>
        <desc xml:lang="zh-Hant">biog:posses</desc>
        <desc xml:lang="en">biog:posses</desc>
        <placeName ref="#PL"/>
    </desc>
    <note>biog:posses</note>
</state>
…  
```

#### event


```xml
…
<listEvent>
    <event xml:lang="zh-Hant" when="0001" where="#PL" source="#BIB" sortKey="biog:event">
        <head>biog:event</head>
        <label>biog:event</label>
        <desc>biog:event</desc>
        <note>biog:event</note>
    </event>
    <event type="biog:entry" subtype="biog:entry" ref="#ORG" when="0001" where="#PL" sortKey="biog:entry" source="#BIB" role="#BIO">
        <head>entry</head>
        <label xml:lang="zh-Hant">biog:entry</label>
        <label xml:lang="en">biog:entry</label>
        <desc type="biog:entry" subtype="biog:entry">
            <desc xml:lang="zh-Hant" ana="七色補官門">biog:entry</desc>
            <desc xml:lang="en" ana="7specials">biog:entry</desc>
        </desc>
        <note type="field">biog:entry</note>
        <note type="attempts">biog:entry</note>
        <note type="rank">biog:entry</note>
        <note>biog:entry</note>
        <note type="parental-status">
            <trait type="parental-status" key="biog:entry">
                <label xml:lang="zh-Hant">biog:entry</label>
                <label xml:lang="zh-Latn-alalc97">biog:entry</label>
            </trait>
        </note>
    </event>
</listEvent>
…
<event where="#ORG" key="biog:inst-add" from="0001" to="0001" from-custom="D-R-Y" to-custom="D-R-Y" source="#BIB" datingMethod="#chinTrad">
    <desc xml:lang="zh-Hant">biog:inst-add</desc>
    <desc xml:lang="en">biog:inst-add</desc>
    <note>biog:inst-add</note>
</event>
```

#### residence

```xml
…
<residence ref="#PL" key="biog:pers-add" n="biog:pers-add" from="0001-01-01" to="0001-01-01" source="#BIB">
    <state type="natal">
        <desc xml:lang="zh-Hant">biog:pers-add</desc>
        <desc xml:lang="en">biog:pers-add</desc>
    </state>
    <date calendar="#chinTrad" period="#R">Y-D</date>
    <note>biog:pers-add</note>
</residence>
…
```

#### other (idno, sex, linkGrp, note)
For compatibility reasons, the old TTS id of each person is included here, but otherwise omitted throughout the conversion.

```xml
…
<idno type="TTS">biog:biog</idno>
…
<sex value="biog:biog">biog:biog</sex>
…
<note>biog:biog</note>
…
<linkGrp>
    <ptr target="biog:biog"/>
</linkGrp>
<note type="created" target="global:create-mod-by">
    <date when="0001-01-01"/>
</note>
<note type="modified" target="global:create-mod-by">
    <date when="0001-01-01"/>
</note>
</person>
```

### org

```xml
<org ana="historical" xml:id="ORG" role="org:org" source="#BIB">
    <orgName type="main">
        <orgName xml:lang="zh-Hant">org:org</orgName>
        <orgName xml:lang="zh-Latn-alalc97">org:org</orgName>
    </orgName>
    <orgName type="alias">
        <orgName xml:lang="zh-Hant">org:org</orgName>
        <orgName xml:lang="zh-Latn-alalc97">org:org</orgName>
        <date from="0001" to="0001"/>
        <date calendar="#chinTrad" period="#D">org:org</date>
    </orgName>
    <place sameAs="#PL" source="#BIB">
        <location>
            <geo>org:org</geo>
        </location>
    </place>
    <note>org:org</note>
    <note>org:org</note>
</org>
```

### place

```xml
<place xml:id="PL" type="pla:fix-admin-types" source="#BIB">
    <placeName xml:lang="zh-Hant">pla:nest-places</placeName>
    <placeName xml:lang="zh-Latn-alalc97">pla:nest-places</placeName>
    <placeName type="alias">pla:nest-places</placeName>
    <location from="0001" to="0001">
        <geo>pla:nest-places</geo>
    </location>
    <idno type="CHGIS">pla:nest-places</idno>
    <note>pla:nest-places</note>
    <note>pla:nest-places</note>
</place>
```

### bibl

```xml
<bibl xml:id="BIB" type="bib:bib" subtype="bib:bib">
    <idno type="TTS">bib:bib</idno>
    <title type="main" xml:lang="zh-Hant">bib:bib</title>
    <title type="main" xml:lang="zh-Latn-alalc97">bib:bib</title>
    <title type="alt">bib:bib</title>
    <title type="translation" xml:lang="en">bib:bib</title>
    <date type="original" when="0001">
        <ref target="#R">bib:bib</ref>
    </date>
    <date type="published" when="0001">
        <ref target="#R">bib:bib</ref>
    </date>
    <country xml:lang="zh-Hant">bib:bib</country>
    <country xml:lang="en">bib:bib</country>
    <pubPlace>
        <country>bib:bib</country>
    </pubPlace>
    <edition>bib:bib</edition>
    <publisher>bib:bib</publisher>
    <pubPlace>bib:bib</pubPlace>
    <state> <!--needs @type-->
        <ab>bib:bib</ab>
    </state>
    <note>bib:bib</note>
    <bibl>
        <ref target="#BIB"/>
        <biblScope unit="page">bib:bib</biblScope>
    </bibl>
    <ref target="bib:bib">bib:bib</ref>
    <note>bib:bib</note>
    <author>
        <ptr target="#BIO-bib-roles"/> <!--why not ref?-->
    </author>
    <note type="created" target="global:create-mod-by">
        <date when="0001-01-01"/>
    </note>
    <note type="modified" target="global:create-mod-by">
        <date when="0001-01-01"/>
    </note>
</bibl>
```

## Appendix
*   [full xml template](../templates/tei/cbdbTEI-template.xml)
*   [custom ODD template](../templates/tei/cbdbTEI-odd.xml)
