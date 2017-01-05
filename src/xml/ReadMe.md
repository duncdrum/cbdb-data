# README

There is a full export of all tables from CBDB into xml here. 
Due to size limitations this is not part of the Github repo. 

You can download the SQLite file used to generate the full export [here](https://hu-my.sharepoint.com/personal/hongsuwang_fas_harvard_edu/_layouts/15/guestaccess.aspx?guestaccesstoken=3E8k6iahdJx2Ew6k%2BAeKHDuP4DSSFzbpy02BbfjXhKs%3D&docid=09fda1531e3214410a18eb2aece0b003f).

The root element of each file is ```<root>```, each table-row is wrapped inside a ```<row>``` element. 

The xml files without a namespace, and are named after the original tables, e.g.:
```BIOG_MAIN``` becomes ```BIOG_MAIN.xml``` etc. 
