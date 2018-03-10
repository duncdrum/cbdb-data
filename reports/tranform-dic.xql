xquery version "3.1";

declare function local:transform($nodes as node()*) as item()*{
for $n in $nodes/*
        let $new-name := local-name($n/a/../*[2])
        return
            typeswitch ($n)
                case element (p) return if (exists($n/a)) 
                    then (element {$new-name} {attribute xml:lang {'zh-Hant'}, 
                           normalize-space($n/*[1])},
                           element {$new-name} {attribute xml:lang {'en'}, 
                               normalize-space($n/*[2])})
                    else ($n)                            
                case element (ol) return local:transform($n/li)
                case element (table) return local:transform($n/tr/td)
            default return (local:transform($n/*))
};

let $body := html//body

return

element root{
  
(:@class="alt" needs to be wrapped into one text element :)

        local:transform($body)
}     