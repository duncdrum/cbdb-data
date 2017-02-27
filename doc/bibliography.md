# xQuery Function Documentation

## module: bibliography
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

