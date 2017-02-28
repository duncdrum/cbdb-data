# xQuery Function Documentation

## module: office
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
