# README

The live app contains  a full export of tables from CBDB into xml here. 
Due to size limitations this is not part of the Github repo. 

You can download the SQLite file used to generate the export [here](https://hu-my.sharepoint.com/personal/hongsuwang_fas_harvard_edu/_layouts/15/guestaccess.aspx?guestaccesstoken=3E8k6iahdJx2Ew6k%2BAeKHDuP4DSSFzbpy02BbfjXhKs%3D&docid=09fda1531e3214410a18eb2aece0b003f).

The root element of each file is ```<no:root xmlns="nowhere">```, each table-row is wrapped inside a ```<row>``` element. 

The files are in a dummy namespace for easier processing.
Each file is named after the original table, e.g.:
```BIOG_MAIN``` becomes ```BIOG_MAIN.xml``` etc. 
