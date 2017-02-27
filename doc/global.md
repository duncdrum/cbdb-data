# xQuery Function Documentation

This module holds all the variables and paths used in the app. 

The list of variable decleartions pointing to the imported tables, is generated via ``local:table-variables`` in the ``aux.xql`` module. 

## module: global
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each table of CBDB and their use in  cbdbTEI. 

### global:create-mod-by
Processes the created-by and midfied by data found on each table. Only called for main tables. 

### global:validate-fragment
Helper function called by every write operation, to ease the burden of validating the whole file when working on a specific section.

