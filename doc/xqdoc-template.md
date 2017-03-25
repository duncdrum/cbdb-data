# Function Documentation

## Module URI
default.xqy
[view code](../modules/default.xqy)

```xml
<root>test</root>
```
## Library Modules
xqdoc/xqdoc-display

## Main Modules
default.xqy
get-code.xqy
get-module.xqy

## Module Description
This main module controls the presentation of the home page for xqDoc. The home page will list all of the library and main modules contained in the 'xqDoc' collection. The mainline function invokes only the method to generate the HTML for the xqDoc home page. A parameter of type xs:boolean is passed to indicate whether links on the page should be constructed to static HTML pages (for off-line viewing) or to XQuery scripts for dynamic real-time viewing.

*   Author:  Darin McBeath
*   Version:  1.1
*   Since:  February 27, 2005

## Imported Modules
[xqdoc/xqdoc-display]()

## Variables
### $app:var1
```xml
<root>test</root>
```
explain

### Internal Functions that reference this Variable  
Module URI|Function Name  
:----|:----
blah | blah

## Function Summary
[xqDoc-main](#Function)

### Function Detail
[xqDoc-main](#Function)  
[view code](../modules/default.xqy)

#### Parameters:
*   *$var1* - explained - as xs:type
*   *$var2* - explained - as xs:type

#### Return:
*   ``stuff``

#### External Functions that are used by this Function
Module URI|Function Name  
:----|:----
``http://marklogic.com/xdmp``|add-response-header  
| set-response-content-type
``xqdoc/xqdoc-display``| [get-default-html](get-default-html)
