# TEI encoding guidelines

## Introduction
To facilitate my own needs for semi-automated annotation of historical Chinese documents I encountered either competing authority institutions, or an absence of the kind of reference points that enable linked open data applications. In particular with respect to prosopographical data, the most comprehensive data collection [*China Biographical Database*] (http://projects.iq.harvard.edu/cbdb/home) provided only limited means for retrieving machine readable data. *Cbdb in TEI* is a xml application that follows the [TEI-P5](http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ST.html) encoding guidelines. It can be installed and used along other tools that all facilitate xml oriented workflows of academic editing. 

Transforming the contents of a relational database  into TEI is very different from transcribing source documents. The primary challenge consists of finding fitting tei-xml elements for every column in cbdb’s tables. The other challenge was to write performative transformation scripts that can handle missing data points or errors in the input data (such as an event dated to the 30th February).

### About this document
This document describes the encoding decisions behind *cbdb in TEI*. It is not a replacement of the original TEI documentation. It covers only those elements and attributes that are actually used by the project. In addition it also contains the documentation and explanation of the various xQuery programs used in the transformation from SQLite to xml. 

## Basic encoding decisions
 