# TEI encoding guidelines
## Contents
* [Introduction](#introduction)
    * [About this document](#about%20this%20document)
* [Basic encoding decisions](#basic%20encoding%20decisions)
* [General encoding decisions](#general%20encoding%20decisions)
    * [Languages](#languages)
    * [Dates](#dates)
* [Header](#header)
    * [fileDesc](#fileDesc)
    * [encodingDesc](#encodingDesc)
        * [listPrefixDef](#listPrefixDef)
        * [charDecl](#charDecl)
        * [classDesc](#classDesc)
            * [biblCat](#biblCat)
            * [cal_ZH](#cal_ZH)
            * [office](#office)


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
Contains the mandatory information regarding the file itself, and its creator. In addition, and after corresponding with the owners of *CBDB* it includes the [CC-BY-SA](https://creativecommons.org/licenses/by-sa/4.0/) 4.0 license statement.
 
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
asda

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
                             
 
