# Function Documentation

## Module URI
[http://exist-db.org/apps/cbdb-data/institutions](/db/apps/cbdb-data/modules/institutions.xql)

## Module Description
This module does what biographies does for persons for institutions.
*   Author: Duncan Paterson
*   Version: 0.7

## Function Summary

### org:org
```xQuery
declare function org:org($institutions as node()*, $mode as xs:string?) as item()*
```

### Function Detail:
This function transforms data from SOCIAL_INSTITUTION_CODES, SOCIAL_INSTITUTION_NAME_CODES, SOCIAL_INSTITUTION_TYPES, SOCIAL_INSTITUTION_ALTNAME_DATA, SOCIAL_INSTITUTION_ALTNAME_CODES, SOCIAL_INSTITUTION_ADDR, and SOCIAL_INSTITUTION_ADDR_TYPES into TEI. However, the altName tables, and address-type tables are empty!

#### Parameters:
*   $institutions - is a c_inst_code
*   $mode - can take three effective values:
    *   'v' = validate; preforms a validation of the output before passing it on.
    *   ' ' = normal; runs the transformation without validation.
    *   'd' = debug; this is the slowest of all modes.

#### Returns:
*   org

#### External Functions that are used by this Function
*Module URI*|*Function Name*
:----|:----
<http://exist-db.org/apps/cbdb-data/calendar>|[cal:custo-date-range](#cal:custo-date-range)
<http://exist-db.org/apps/cbdb-data/calendar>|[cal:isodate](#cal:isodate)
<http://exist-db.org/apps/cbdb-data/calendar>|[cal:custo-date-point](#cal:custo-date-point)
<http://exist-db.org/apps/cbdb-data/global>|[global:validate-fragment](#global:validate-fragment)
