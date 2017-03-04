# CBDB in TEI
<img src="icon.png" align="left" width="25%" hspace="10" vspace="6"/>

*CBDB in TEI* brings the data of the [China Biographical Database](http://projects.iq.harvard.edu/cbdb/home) 
to [eXist-db](http://exist-db.org/exist/apps/homepage/index.html) by converting it into [TEI](http://www.tei-c.org/index.xml).

Currently, the application focuses on the data conversion, and integration of the contents with other TEI tools in exist-db. 
For a more detailed account please consult the [Documentation](#documentation) below. Future updates will bring the familiar query 
tools of *CBDB* to the browser along with means for exporting and visualizing the data. 
Because *CBDB* consists of roughly ~350k records, users are strongly encouraged to use *cbdb in TEI* in combination with an xml database, see [installation](#installation) below.

The current release ``0.6`` is based on the ``20150202`` version of *CBDB*.

## Requirements
* eXist-db version ``2.2 <`` with min. ``2gb`` (!) allocated memory.
* (ant version ``1.10.1`` for compiling from source)

## Releases
Releases have three flavors:

* [regular](#regular)
* [full](#full)  
* [data pack](#data-pack)

### Regular 
This is the default version for most users. It contains the xQuery conversion modules, and the complete TEI files. 
But not the CBDB's source files, the index configuration is adapted accordingly. 
   
### Full
The full version contains both source and converted files. Also contains indexes on both files. 
This version is only of interest to users wishing to experiment with the transformation itself. 

### Data pack
A zip file with just the TEI files. Only releases with updates to the converted data files include this. 

### Installation
1. Download either full or regular ``.xar`` from the [releases](https://github.com/duncdrum/cbdb-data/releases) page. 
2.  Go to your running eXist-db and open package manager from the dashboard. 
  1. Click on the "add package" symbol in the upper left corner and select the ``.xar`` file you just downloaded. 

#### Building from source
Because of GitHub’s restrictions on file sizes, compiling from source will generate the regular version. 

1. Download, fork or clone this GitHub repository
2. Open the folder you just downloaded in CLI, type:  
``` cd cbdb-data ```
3. call ant by typing:
``` ant ```
you should see:
```BUILD SUCCESSFUL```
4.  Go to your running eXist-db and open package manager from the dashboard. 
  1. Click on the "add package" symbol in the upper left corner and select the ``.xar`` file you just created which is inside the ``/build`` folder.


## Documentation
* [TEI encoding guidelines](doc/encoding-desc.md)
* [Function documentation](doc/function-doc.md)
