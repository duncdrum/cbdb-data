xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

import module namespace global="http://exist-db.org/apps/cbdb-data/global" at "global.xqm";
import module namespace cal="http://exist-db.org/apps/cbdb-data/calendar" at "calendar.xql";
import module namespace pla="http://exist-db.org/apps/cbdb-data/place" at "place.xql";
import module namespace biog="http://exist-db.org/apps/cbdb-data/biographies" at "biographies.xql";
import module namespace bib="http://exist-db.org/apps/cbdb-data/bibliography" at "bibliography.xql";
import module namespace org="http://exist-db.org/apps/cbdb-data/institutions" at "institutions.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace no="http://none";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare default element namespace "http://www.tei-c.org/ns/1.0";

(:~
 This file imports all modules present in the database for easy testing. 
:)

(:
'biog:kin'
'biog:name'
'biog:alias'
'biog:asso'
'biog:status'
'biog:event'
'biog:entry'
'biog:new-post'
'biog:posses'
'biog:pers-add'
'biog:inst-add'
'biog:biog'
:)

element person {
    attribute ana {'historical'},               
    attribute xml:id {'BIO'},
    attribute source{'#BIB'},
    attribute resp {'selfbio'},
    element idno { attribute type {'TTS'}, 'biog:biog'}, 
    element persName { attribute type {'main'},
        element persName { attribute xml:lang {'zh-Hant'}, 
            element surname {'biog:name'},
            element forename {'biog:name'},
            element addName { attribute type {'choronym'}, 'biog:name'}
        },
        element persName { attribute xml:lang {'zh-Latn-alalc97'}, 
            element surname {'biog:name'},
            element forename {'biog:name'},
            element addName { attribute type {'choronym'}, 'biog:name'}
        },
        element persName { attribute type {'original'}, 
            element surname {'biog:name'},
            element forename {'biog:name'}
        },
        element persName { attribute type {'original'}, 'biog:name'}           
    },
    element persName { attribute type {'alias'},          
        attribute key {'AKA'},
        attribute source {'#BIB'},
        element addName {attribute xml:lang {'zh-Hant'}, 'biog:alias'},
            element term {'biog:alias'},    
        element addName {attribute xml:lang {'zh-Latn-alalc97'}, 'biog:alias'},
            element term {'biog:alias'},
        element note {'biog:alias'}},  
    element sex { attribute value {'biog:biog'}, 'biog:biog'},
    element birth {attribute when {'YYYY-MM_DD'},
        attribute datingMethod {'#chinTrad'}, 
        attribute when-custom {'D-R-Y'},
    element date { attribute calendar {'#chinTrad'},
        attribute period {'#R'}, 'biog:biog'}
    },
    element death {attribute when {'YYYY-MM_DD'},
        attribute datingMethod {'#chinTrad'}, 
        attribute when-custom {'D-R-Y'},
    element date { attribute calendar {'#chinTrad'},
        attribute period {'#R'}, 'biog:biog'}
    },
    element floruit { attribute notBefore {'cal:isodate'}, 
        attribute notAfter {'cal:isodate'},     
    element date { attribute when {'cal:isodate'},  
        attribute datingMethod {'#chinTrad'}, 
        attribute period {'#D'}, 'biog:biog'}, 
        element note {'biog:biog'}                                
    },                
    element age { attribute cert {'medium'}, 'biog:biog'},
    element trait { attribute type {'household'},
        attribute key {'biog:biog'},
        element label { attribute xml:lang {'zh-Hant'}, 'biog:biog'},
        element label { attribute xml:lang {'en'}, 'biog:biog'}
   },
    element trait { attribute type {'ethnicity'}, 
        attribute key {'biog:biog'}, 
    element label {'biog:biog'},
    element desc { attribute xml:lang {'zh-Hant'}, 'biog:biog'},
    element desc { attribute xml:lang {'zh-Latn-alalc97'}, 'biog:biog'},
    element desc { attribute xml:lang {'en'}, 'biog:biog'},
    element note {'biog:biog'}
    },
    element trait { attribute type {'tribe'}, 'biog:biog'},
    element note {'biog:biog'},                   
    element affiliation {
        element note {
            element listPerson {
                element personGrp { attribute role {'kin'}},
                element listRelation { attribute type {'kinship'},
                    element relation { attribute active {'#BIO'},
                        attribute passive {'#BIO'},
                        attribute key {'biog:kin'},
                        attribute sortKey{'biog:kin'},
                        attribute name {'biog:kin'},
                        attribute source {'biog:kin'},
                        attribute type {'auto-generated'},
                        element desc { attribute type {'kin-tie'}, 
                            element label {'biog:kin'}, 
                            element desc { attribute xml:lang {'zh-Hant'},'biog:kin'},
                            element desc { attribute xml:lang {'en'},'biog:kin'},                               
                            element trait { attribute type {'mourning'},
                                attribute subtype {'biog:kin'},
                                element label { attribute xml:lang {'zh-Hant'},'biog:kin'},
                                element desc { attribute xml:lang {'zh-Hant'},'biog:kin'},        
                                element desc {attribute xml:lang {'en'},'biog:kin'}
                                }     
                            }
                        }                        
                    }
                }
            },
        element note {
            element listPerson {
                element personGrp { attribute role {'associates'}},
                    element listRelation { attribute type {'associations'},
                        element relation { attribute mutual {'biog:asso'},
                        attribute name {'biog:asso'},
                        attribute key {'biog:asso'},
                        attribute sortKey {'biog:asso'},
                        attribute source {'#BIB'},
                    element desc { attribute type {'biog:asso'},
                        attribute n {'biog:asso'},
                        element label {'biog:asso'},
                        element desc { attribute xml:lang {"zh-Hant"}, 'biog:asso',
                            element label {'biog:asso'}
                        },
                        element desc { attribute xml:lang {"en"}, 'biog:asso',
                            element label {'biog:asso'}
                        },
                    element state { attribute ref {'#PL #ORG'},
                        attribute when {'cal:isodate'},
                        attribute ana {'biog:asso'},
                        attribute type {'biog:asso'},
                        attribute subtype {'biog:asso'},
                        element label { attribute xml:lang {'zh-Hant'}, 'biog:asso'},
                        element label { attribute xml:lang {'zh-Latn-alalc97'}, 'biog:asso'},
                        element desc {attribute ana {'topic'}, 'biog:asso'},
                        element desc {attribute xml:lang {'zh-Hant'},'biog:asso',
                            element label {'biog:asso'}},
                        element desc { attribute xml:lang {'en'},'biog:asso',
                            element label {'biog:asso'}}
                     },
                     element desc { attribute ana {'genre'},                                
                        element label {attribute xml:lang {'zh-Hant'}, 'biog:asso'}, 
                        element label { attribute xml:lang {'en'}, 'biog:asso'}
                     },
                     element desc {
                        element persName { attribute role {'mediator'},
                            attribute ref {'#BIO'}}
                     }
                     }                     
                 }
        }
                    }
                }
            },
    element socecStatus {
        element state { attribute type {'status'},
            attribute subtype {'biog:status'},
            attribute from {'cal:isodate'},
            attribute to {'cal:isodate'},
            attribute n {'biog:status'},
            attribute source {'#BIB'},
            element desc { attribute xml:lang {'zh-Hant'}, 'biog:status'},
            element desc { attribute xml:lang {'en'}, 'biog:status'}
        }
    },
    element socecStatus{ attribute scheme {'#office'}, 
        attribute code {'#OFF'},
        element state { attribute type {'posting'},
            attribute ref {'#PL'},
            attribute n {'biog:new-post'},
            attribute key {'biog:new-post'},
            attribute notBefore {'cal:isodate'},
            attribute notAfter {'cal:isodate'},
            attribute source {'#BIB'},
            element desc {
                element label {'appointment'},
                element desc { attribute xml:lang {'zh-Hant'},'biog:new-post'},
                element desc { attribute xml:lang {'en'}, 'biog:new-post'}
            },
            element desc {
                element label {'assumes'},
                element desc { attribute xml:lang {'zh-Hant'}, 'biog:new-post'}, 
                element desc { attribute xml:lang {'en'}, 'biog:new-post'}},                                        
                element note {'biog:new-post'}
            },
            element state { attribute type {'office-type'},
                attribute n {'biog:new-post'},
            element desc { attribute xml:lang {'zh-Hant'}, 'biog:new-post'},
            element desc { attribute xml:lang {'en'}, 'biog:new-post'}, 
            element note {'biog:new-post'}
            }
    },
    element listEvent {
        element event { attribute xml:lang {'zh-Hant'},
            attribute when {'cal:isodate'},
            attribute where {'#PL'},
            attribute source {'#BIB'},
            attribute sortKey {'biog:event'},    
            element desc {'biog:event'},
                element head {'biog:event'}, 
                element label {'biog:event'},
                element desc {'biog:event'},
                element note {'biog:event'}
        },
        element event { attribute type {'biog:entry'},
            attribute subtype {'biog:entry'},
            attribute ref {'#ORG'},
            attribute when {'cal:isodate'},
            attribute where {'#PL'},
            attribute sortKey {'biog:entry'},
            attribute source {'#BIB'},
            attribute role {'#BIO'},             
            element head {'entry'},
            element label { attribute xml:lang {'zh-Hant'}, 'biog:entry'},
            element label { attribute xml:lang{'en'}, 'biog:entry'},   
            element desc { attribute type {'biog:entry'},
                attribute subtype {'biog:entry'},
                element desc { attribute xml:lang {'zh-Hant'},
                    attribute ana {'七色補官門'}, 'biog:entry'},
                element desc { attribute xml:lang{'en'},
                    attribute ana {'7specials'},'biog:entry'}
             },
             element note { attribute type {'field'}, 'biog:entry'},
             element note { attribute type {'attempts'}, 'biog:entry'},
             element note { attribute type {'rank'}, 'biog:entry'},
             element note {'biog:entry'},
             element note { attribute type {'parental-status'}, 
                element trait { attribute type {'parental-status'},
                    attribute key {'biog:entry'},
                     element label {attribute xml:lang {'zh-Hant'},'biog:entry'}, 
                     element label { attribute xml:lang {'zh-Latn-alalc97'},'biog:entry'}
                }
             }
             }                      
    },
    element state { attribute type {'possession'},       
        attribute xml:id {'POS'},
        attribute unit {'biog:posses'},
        attribute quantity {'biog:posses'},
        attribute n {'biog:posses'},
        attribute when {'cal:isodate'},
        attribute source {'#BIB'},
        attribute subtype {'biog:posses'},
        element desc {
            element desc { attribute xml:lang {'zh-Hant'}, 'biog:posses'},
            element desc { attribute xml:lang {'en'}, 'biog:posses'},
            element placeName { attribute ref { '#PL'}},
            element note {'biog:posses'}
        }       
    }, 
    element residence { attribute ref {'#PL'},
        attribute key {'biog:pers-add'},
        attribute n {'biog:pers-add'},
        attribute from {'YYYY-MM-DD'},
        attribute to {'YYYY-MM-DD'},
        attribute source {'#BIB'},
        element state { attribute type {'natal'},
            element desc { attribute xml:lang {'zh-Hant'}, 'biog:pers-add'},
            element desc {attribute xml:lang {'en'}, 'biog:pers-add'}
        },
        element date { attribute calendar {'#chinTrad'},
            attribute period {'#R'},'Y-D'},
        element note {'biog:pers-add'}
    }, 
    element event { attribute where {'#ORG'},
        attribute key {'biog:inst-add'},
        attribute from {'cal:isodate'},
        attribute to {'cal:isodate'},
        attribute from-custom { 'D-R-Y'},
        attribute to-custom {'D-R-Y'},
        attribute source {'#BIB'},
        attribute datingMethod {'#chinTrad'},          
        element desc { attribute xml:lang {'zh-Hant'},'biog:inst-add'},
        element desc {attribute xml:lang {'en'},'biog:inst-add'},       
        element note {'biog:inst-add'}
    },
    element linkGrp {
        element ptr { attribute target {'biog:biog'}}                                
    },
    element note { attribute  type{"created"}, 
        attribute target{"global:create-mod-by"},
        element date {attribute when {"cal:sqldate"}
    }},
    element note { attribute  type{"modified"}, 
        attribute target{"global:create-mod-by"},
        element date {attribute when {"cal:sqldate"}
    }}
}