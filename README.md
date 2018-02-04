# CBDB in TEI
[![AUR](https://img.shields.io/badge/license-GPLv3.0-blue.svg)](https://choosealicense.com/licenses/gpl-3.0/)
[![GitHub release](https://img.shields.io/badge/release-0.6.3-green.svg)](https://github.com/duncdrum/cbdb-data/releases/latest)
[![CBDB version](https://img.shields.io/badge/CBDB-20150202-red.svg)](https://hu-my.sharepoint.com/personal/hongsuwang_fas_harvard_edu/_layouts/15/guestaccess.aspx?guestaccesstoken=3E8k6iahdJx2Ew6k%2BAeKHDuP4DSSFzbpy02BbfjXhKs%3D&docid=09fda1531e3214410a18eb2aece0b003f)
[![TEI version](https://img.shields.io/badge/TEI_P5-3.1.0-yellow.svg)](http://www.tei-c.org/release/doc/tei-p5-doc/en/html/index.html)

<img src="icon.png" align="left" width="25%"/>

*CBDB in TEI* brings the data of the [China Biographical Database](http://projects.iq.harvard.edu/cbdb/home)
to [eXist-db](http://exist-db.org/exist/apps/homepage/index.html) by converting it into [TEI](http://www.tei-c.org/index.xml).

Currently, the application focuses on the data conversion, and integration of the contents with other TEI tools in exist-db.
For a more detailed account please consult the [Documentation](#documentation) below. Future updates will bring the familiar query
tools of *CBDB* to the browser along with means for exporting and visualizing the data.
Because *CBDB* consists of roughly ~350k records, users are strongly encouraged to use *cbdb in TEI* in combination with an xml database, see [installation](#installation) below.


## Requirements
*   eXist-db version `3.0` or greater with min. `2gb` (!) allocated memory.
*   (ant version `1.10.1` for compiling from source)



## Releases
GitHub Releases consists of three files: [App](#application), [source](#source), and [data](#data).

To install and use the *cbdb in TEI* application with eXist-db you only need to follow the installation instructions for the app file.
The other two zip files are provided as a courtesy, the first includes the cleaned up source files of CBDB in xml, and the second
just the converted tei files.

### Application
The eXist-db app is a `.xar` package that contains the xQuery conversion modules, and the complete TEI files.
But not the CBDB's source files.

### Source
A zip file that contains a cleaned up (fixing illegal unicode characters) export of CBDB as xml.
The root element of each file is `<root xmlns="http://none">`, each table-row is wrapped inside a `<row>` element.

The files are in a dummy namespace for easier processing.
Each file is named after the original table, e.g.:
`BIOG_MAIN` becomes `BIOG_MAIN.xml` etc. .

### Data
A zip file with just the TEI files. See the encoding [guidelines](doc/encoding-desc.md) for details.

## Installation
1.  Download  the `.xar` file from the [releases](https://github.com/duncdrum/cbdb-data/releases) page.
2.  Go to your running eXist-db instance and open the package manager from the dashboard.
    1.  Click on the "add package" symbol in the upper left corner and select the `.xar` file you just downloaded.

### Building from source
1.  Download, fork or clone this GitHub repository
2.  There are four build targets in `build.xml`:
    *   `dev` includes *all* files from the source folder including those with potentially sensitive information.
    *   `deploy` is the official release. It excludes files necessary for development but that have no effect upon deployment.
    *   `src` the unmodified sources as xml
    *   `tei` just the tei file
3.  Calling `ant` in your CLI will build all files:    
```bash
cd cbdb-data
ant
```
  1. to only build a specific target call either `dev` or `deploy` like this:
  ```bash   
  ant deploy
  ```   

If you see `BUILD SUCCESSFUL` ant has generated a `cbdb-data-0.0.7.xar` file in the `build/` folder. To install it, follow the instructions [above](#installation).



## Documentation
*   [TEI encoding guidelines](doc/encoding-desc.md)
*   [Function documentation](doc/function-doc.md)

## License
The content of this project itself is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 license,
and the underlying source code used to format and display that content is licensed under the GNU GPLv3 license.
