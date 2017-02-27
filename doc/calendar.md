# xQuery Function Documentation

## module: calendar
[Here](https://docs.google.com/spreadsheets/d/15CtYfxx4_LsmLUBDm5MPfZ4StWGlpCTWMyUMR1tPHjM/edit?usp=sharing) is a spreadsheet listing each column used in this conversion. 

#### TODO
*  friggin YEAR_RANGE_CODES.xml
* many nianhaos aren't transliterated hence $NH-py
*  ``DYNASTIES`` contains both translations and transliterations:
     e.g. 'NanBei Chao' but 'Later Shu (10 states) more normalization *yay*
*  make 10states a ``@type`` ? 

### cal:custo-date-point
tricky with the data at hand, consequently not called by other function whenever possible. 
long run switch to CCDB date authority since that also covers korean and japanese dates. 

#### TODO
* getting to a somehwhat noramlized useful representation of Chinese Reign dates is tricky. Inconsinsten pinyin for Nianhao creates ambigous and ugly dates.
* handle ``//no:c_dy[. = 0]`` stuff
* add ``@period`` with ``#d42`` ``#R123``
* find a way to prevent empty attributes more and better logic FTW
* If only a dynasty is known lets hear it, the others are dropped since only a year or nianhao is of little information value. 

### cal:custo-date-range
See cal:custo-date-point

### cal:dynasties

### cal:ganzhi
Just for fun not used in the transformation. Calculate the ganzhi cycle for a given year (postive and negative), in either pinyin or hanzi.  

#### TEST
```
cal:ganzhi(2036, 'zh') -> 丙辰
cal:ganzhi(1981, 'zh') -> 辛酉
cal:ganzhi(1967, 'zh') -> 丁未
cal:ganzhi(0004, 'zh') -> 甲子
cal:ganzhi(0001, 'zh') -> 壬戌
cal:ganzhi(0000, 'zh') -> no such gYear 
cal:ganzhi(-0001, 'zh') -> 庚申
cal:ganzhi(-0247, 'zh') -> 乙卯 = 246BC founding of Qing
```

### cal:isodate

### cal:sexagenary

### cal:sqldate