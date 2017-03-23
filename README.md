# CBDB in TEI
[![AUR](https://img.shields.io/badge/license-GPLv3.0-blue.svg)](https://choosealicense.com/licenses/gpl-3.0/)
[![GitHub release](https://img.shields.io/badge/release-0.6-green.svg)](https://github.com/duncdrum/cbdb-data/releases/latest)

<img src="icon.png" align="left" width="25%"/>

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
Releases have three flavors pick the one that best suits your needs: [full](#full), [develop](#develop), or [data pack](#data-pack).

### Full 
This is the default version for most users. It contains the xQuery conversion modules, and the complete TEI files. 
But not the CBDB's source files, the index configuration is adapted accordingly. 
   
### Develop
The develop version has both source and converted files. It also contains indexes for both kind of files. 
This version is only of interest to users wishing to experiment with the transformation itself. 

### Data pack
A zip file with just the TEI files.  

## Installation
1. Download either "-dev" or "-full" ``.xar`` from the [releases](https://github.com/duncdrum/cbdb-data/releases) page. 
2.  Go to your running eXist-db and open package manager from the dashboard. 
    1. Click on the "add package" symbol in the upper left corner and select the ``.xar`` file you just downloaded. 

### Building from source
1. Download, fork or clone this GitHub repository
    1. To compile the develop version from source, you need to add your own copy of CBDB's source files as xml in:``cbdb-data/src/xml``
2. In your CLI, go to the folder you just downloaded:``cd cbdb-data``
3. now call ant:``ant`` after a few minutes you should see:``BUILD SUCCESSFUL``
4.  Go to your running eXist-db and open package manager from the dashboard. 
    1. Click on the "add package" symbol in the upper left corner and select the ``.xar`` file you just created which is inside the ``/build`` folder.


## Documentation
* [TEI encoding guidelines](doc/encoding-desc.md)
* [Function documentation](doc/function-doc.md)
 
## License 
The content of this project itself is licensed under the Attribution-NonCommercial-ShareAlike 4.0 license, 
and the underlying source code used to format and display that content is licensed under the GNU GPLv3 license.
