xquery version "3.1";

declare namespace html="http://www.w3.org/1999/xhtml";
let $body := html//body
let $lvl1 := $body//a/span/@class[starts-with(., "s1")]

for $n in $body//a
let $new-name := $n/span/../../*[2]/name()
return 
$n/span/../../*