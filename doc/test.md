# Function Documentation

## Module URI
[http://exist-db.org/apps/cbdb-data/calendar](/db/apps/cbdb-data/modules/calendar.xql)

## Module Description

The calendar module reads the calendar aux tables (GANZHI, DYNASTIES, NIANHAO) and creates a taxonomy element for inclusion in the teiHeader. The taxonomy consists of two elements one for the sexagenary cycle, and one nested taxonomy for reign-titles and dynasties. We are dropping the c_sort value for dynasties since sequential sorting is implicit in the data structure.

*   Author: Duncan Paterson


*   Version: 0.7



## Variables:

*   *$cal:ZH* - *missing description*
*   *$cal:path* - *missing description*

## Function Summary

### cal:custo-date-point
```xQuery
declare function cal:custo-date-point($dynasty as node()*, $reign as node()*, $year as xs:string*, $type as xs:string?) as node()*
```

### Function Detail:

cal:custo-date-point takes Chinese calendar date strings (columns ending in ``*_dy``, ``*_gz``, ``*_nh``) . It returns a single ``tei:date`` element using ``att.datable.custom``. cal:custo-date-range does the same but for date ranges. The normalized format takes ``DYNASTY//no:c_sort`` which is specific to CBDB, followed by the sequence of reigns determined by their position in cal_ZH.xml followed by the Year number: ``D(\d*)-R(\d*)-(\d*)``

#### Parameters:

*   $dynasty - the sort number of the dynasty.

*   $reign - the sequence of the reign period 1st = 1, 2nd = 2, etc.

*   $year - the ordinal year of the reign period 1st = 1, 2nd = 2, etc.

*   $type - can process 5 kinds of date-point:  
    *   'Start' , 'End' preceded by 'u' for uncertainty, defaults to 'when'.

#### Returns:

*   ``<date datingMethod="#chinTrad" calendar="#chinTrad">input string</date>``

### cal:custo-date-range
```xQuery
declare function cal:custo-date-range($dy-start as node()*, $dy-end as node()*, $reg-start as node()*, $reg-end as node()*, $year-start as xs:string*, $year-end as xs:string*, $type as xs:string?) as node()*
```

### Function Detail:

This function takes Chinese calendar date ranges. It's the companion to cal:custo-date-point. It determines the matching end-points automatically when provided a starting point for a date range.

#### Parameters:

*   $dy-start - the sort number of the starting dynasty.

*   $dy-end -

*   $reg-start - the sequence of the starting reign period 1st = 1, 2nd = 2, etc.

*   $reg-end -

*   $year-start - the ordinal year of the starting reign period 1st = 1, 2nd = 2, etc.

*   $year-end -

*   $type - has two options 'uRange' for uncertainty, default to certain ranges.

#### Returns:

*   ``<date datingMethod="#chinTrad" calendar="#chinTrad">input string</date>``

### cal:dynasties
```xQuery
declare function cal:dynasties($dynasties as node()*, $mode as xs:string?) as item()*
```

### Function Detail:

cal:dynasties converts DYNASTIES, and NIANHAO data into categories.

#### Parameters:

*   $dynasties - c_dy

*   $mode - can take three effective values:
    *   'v' = validate; preforms a validation of the output before passing it on.
    *   ' ' = normal; runs the transformation without validation.
    *   'd' = debug; this is the slowest of all modes.

#### Returns:

*   ``<taxonomy xml:id="reign">...</taxonomy>``

#### External Functions that are used by this Function
*Module URI*|*Function Name*
:----|:----
<http://exist-db.org/apps/cbdb-data/global>|[global:validate-fragment](#global:validate-fragment)
### cal:ganzhi
```xQuery
declare function cal:ganzhi($year as xs:integer, $lang as xs:string?) as xs:string*
```

### Function Detail:

Just for fun: cal:ganzhi calculates the ganzhi cycle for a given year. It assumes gYears for calculating BCE dates.

#### Parameters:

*   $year - gYear compatible string.

*   $lang - is either hanzi = 'zh', or pinyin ='py' for output.

#### Returns:

*   ganzhi cycle as string in either hanzi or pinyin.

### cal:isodate
```xQuery
declare function cal:isodate($string as xs:string?) as xs:string*
```

### Function Detail:

cal:isodate turns inconsistent gregorian year strings into proper xs:gYear type strings. Consisting of 4 digits, with leading 0s. This means that BCE dates have to be recalculated. Since '0 AD' -> "-0001"

#### Parameters:

*   $string - year number in western style counting

#### Returns:

*   gYear style string

### cal:sexagenary
```xQuery
declare function cal:sexagenary($ganzhi as node()*, $mode as xs:string?) as item()*
```

### Function Detail:

cal:sexagenary converts GANZHI data into categories.

#### Parameters:

*   $ganzhi - c_ganzhi_code

*   $mode - can take three effective values:
    *   'v' = validate; preforms a validation of the output before passing it on.
    *   ' ' = normal; runs the transformation without validation.
    *   'd' = debug; this is the slowest of all modes.

#### Returns:

*   ``<taxonomy xml:id="sexagenary">...</taxonomy>``

#### External Functions that are used by this Function
*Module URI*|*Function Name*
:----|:----
<http://exist-db.org/apps/cbdb-data/global>|[global:validate-fragment](#global:validate-fragment)
### cal:sqldate
```xQuery
declare function cal:sqldate($timestamp as xs:string?) as xs:string*
```

### Function Detail:

cal:sqldate converts the timestamp like values from CBDBs RLDBMs and converts them into iso compatible date strings, i. e.: gYear-gMonth-gDay

#### Parameters:

*   $timestamp - collection for strings for western style full date

#### Returns:

*   string in the format: YYYY-MM-DD
