# xQuery Function Documentation

## module: place
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

