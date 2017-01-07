xquery version "3.0";

import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.tei-c.org/ns/1.0";


declare variable $src := '/db/apps/cbdb-data/src/xml/';
declare variable $target := '/db/apps/cbdb-data/target/';

declare variable $GANZHI_CODES:= doc(concat($src, 'GANZHI_CODES.xml')); 
declare variable $NIAN_HAO:= doc(concat($src, 'NIAN_HAO.xml')); 
declare variable $DYNASTIES:= doc(concat($src, 'DYNASTIES.xml')); 

declare variable $YEAR_RANGE_CODES:= doc(concat($src, 'YEAR_RANGE_CODES.xml'));

(:calendar.xql reads the calendar aux tables (GANZHI, DYNASTIES, NIANHAO) 
    and creates a taxonomy element for inculsion in the teiHeader via xi:xinclude.
    The taxonomy consists of two elements one for the sexagenarycycle, 
    and one nested taxonomy for reign-titles and dynsties.
    we are dropping the c_sort value for dynasties since sequential sorting
    is implicit in the data structure
:)

(:TODO:
 -  friggin YEAR-RANGE_CODES
 - many nianhaos aren't transliterated hence $NH-py
 - DYNASTIES contains both translations and transliterations:
     e.g. 'NanBei Chao' but 'Later Shu (10 states)'  
   more normalization *yay*
:)


declare function local:isodate ($string as xs:string?)  as xs:string* {

(:This function returns proper xs:gYear type values, "0000", 4 digits, with leading "-" for BCE dates
   <a>-1234</a>    ----------> <gYear>-1234</gYear>
   <b/>    ------------------> <gYear/>
   <c>1911</c> --------------> <gYear>1911</gYear>
   <d>786</d>  --------------> <gYear>0786</gYear>
   
   according to <ref target="http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-att.datable.w3c.html"/>
   "0000" should be "-0001" in TEI.
   
:)
        
    if (empty($string)) then ()
    else if (number($string) eq 0) then ('-0001')
    else if (starts-with($string, "-")) then (concat('-',(concat (string-join((for $i in (string-length(substring($string,2)) to 3) return '0'),'') , substring($string,2)))))
    else (concat (string-join((for $i in (string-length($string) to 3) return '0'),'') , $string))
};

declare function local:sqldate ($timestamp as xs:string?)  as xs:string* {
concat(substring($timestamp, 1, 4), '-', substring($timestamp, 5, 2), '-', substring($timestamp, 7, 2)) 
};

declare function functx:words-to-camel-case
  ( $arg as xs:string? )  as xs:string {

     string-join((tokenize($arg,'\s+')[1],
       for $word in tokenize($arg,'\s+')[position() > 1]
       return functx:capitalize-first($word))
      ,'')
 } ;

declare function local:custodate ($dynasty as node()*, $reign as node()*,
    $year as xs:integer?, $type as xs:string?) 
    as node()*{
(:this function transforms chinese calendar dates ending in *_dy, *_gz, *_nh.
It returns a single tei:date element using att.datable.custom. 
:)

(:TODO
- 
:)

(:Since ASCII pinyin in $NH-py is not sufficient to disambiguate reign-periods
we always need HZ as well.
This normalizes to pinyin without tones, in cases of syllabic ambiguities
or reigns with more then two syllables it uses camelCase.:)
let $NH-py := map{
 '白龍' := 'bailong',
 '白雀' := 'baique',
 '寶大' := 'baoda',
 '保大' := 'baoda',
 '寶鼎' := 'baoding',
 '保定' := 'baoding',
 '寶曆' := 'baoli',
 '保寧' := 'baoning',
 '寶慶' := 'baoqing',
 '寶太(寶大)' := 'baotai',
 '寶義' := 'baoyi',
 '寶應' := 'baoying',
 '寶祐' := 'baoyou',
 '寶元' := 'baoyuan',
 '寶貞(寶正)' := 'baozhen',
 '保貞(寶正)' := 'baozhen',
 '寶正' := 'baozheng',
 '本初' := 'benchu',
 '本始' := 'benshi',
 '長安' := 'changan',
 '長樂' := 'changle',
 '長慶' := 'changqing',
 '長壽' := 'changshou',
 '昌武' := 'changwu',
 '長興' := 'changxing',
 '承安' := 'chengan',
 '承光' := 'chengguang',
 '成化' := 'chenghua',
 '承明' := 'chengming',
 '承平' := 'chengping',
 '承聖' := 'chengsheng',
 '赤烏' := 'chiwu',
 '崇德' := 'chongde',
 '崇福' := 'chongfu',
 '崇寧' := 'chongning',
 '崇慶' := 'chongqing',
 '崇禎' := 'chongzhen',
 '垂拱' := 'chuigong',
 '淳化' := 'chunhua',
 '淳熙' := 'chunxi',
 '淳祐' := 'chunyou',
 '初平' := 'chuping',
 '初始' := 'chushi',
 '初元' := 'chuyuan',
 '大安' := 'daAn',
 '大寶' := 'dabao',
 '大成' := 'dacheng',
 '大德' := 'dade',
 '大定' := 'dading',
 '大觀' := 'daguan',
 '大和' := 'dahe',
 '大曆' := 'dali',
 '大明' := 'daming',
 '大慶' := 'daqing',
 '大順' := 'dashun',
 '大通' := 'datong',
 '大同' := 'datong',
 '大統' := 'datong',
 '大象' := 'daxiang',
 '大業' := 'daye',
 '大有' := 'dayou',
 '大中' := 'dazhong',
 '大足' := 'dazu',
 '地節' := 'dejie',
 '登國' := 'dengguo',
 '德祐' := 'deyou',
 '調露' := 'diaolu',
 '地皇' := 'dihuang',
 '定宗' := 'dingzong',
 '端拱' := 'duangong',
 '端平' := 'duanping',
 '奲都' := 'duodou',
 '鳳凰' := 'fenghuang',
 '鳳翔' := 'fengxiang',
 '阜昌' := 'fuchang',
 '甘露' := 'ganlu',
 '更始' := 'gengshi',
 '拱化' := 'gonghua',
 '光初' := 'guangchu',
 '光大' := 'guangda',
 '廣大(光大)' := 'guangda',
 '廣德' := 'guangde',
 '光定' := 'guangding',
 '光和' := 'guanghe',
 '光化' := 'guanghua',
 '廣明' := 'guangming',
 '光啟' := 'guangqi',
 '光始' := 'guangshi',
 '光壽' := 'guangshou',
 '廣順' := 'guangshun',
 '光天(光大)' := 'guangtian',
 '光天' := 'guangtian',
 '光熹' := 'guangxi',
 '光熙' := 'guangxi',
 '光興' := 'guangxing',
 '光緒' := 'guangxu',
 '廣運' := 'guangyun',
 '光宅' := 'guangzhai',
 '廣政' := 'guangzheng',
 '海迷失后' := 'haimishihou',
 '漢安' := 'hanan',
 '河平' := 'heping',
 '和平' := 'heping',
 '河清' := 'heqing',
 '河瑞' := 'herui',
 '弘昌' := 'hongchang',
 '弘道' := 'hongdao',
 '弘光' := 'hongguang',
 '鴻嘉' := 'hongjia',
 '弘始' := 'hongshi',
 '洪武' := 'hongwu',
 '洪熙' := 'hongxi',
 '弘治' := 'hongzhi',
 '後元' := 'houyuan',
 '黃初' := 'huangchu',
 '皇初' := 'huangchu',
 '皇建' := 'huangjian',
 '黃龍' := 'huanglong',
 '皇慶' := 'huangqing',
 '皇始' := 'huangshi',
 '皇統' := 'huangtong',
 '黃武' := 'huangwu',
 '皇興' := 'huangxing',
 '皇祐' := 'huangyou',
 '會昌' := 'huichang',
 '會同' := 'huitong',
 '嘉定' := 'jiading',
 '嘉禾' := 'jiahe',
 '嘉靖' := 'jiajing',
 '建安' := 'jianan',
 '建初' := 'jianchu',
 '建德' := 'jiande',
 '建光' := 'jianguang',
 '建和' := 'jianhe',
 '建衡' := 'jianheng',
 '建弘' := 'jianhong',
 '嘉寧' := 'jianing',
 '建康' := 'jiankang',
 '建隆' := 'jianlong',
 '建明' := 'jianming',
 '建寧' := 'jianning',
 '建平' := 'jianping',
 '建始' := 'jianshi',
 '建文' := 'jianwen',
 '建武' := 'jianwu',
 '建熙' := 'jianxi',
 '建興' := 'jianxing',
 '建炎' := 'jianyan',
 '建義' := 'jianyi',
 '建元' := 'jianyuan',
 '建昭' := 'jianzhao',
 '建中' := 'jianzhong',
 '交泰' := 'jiaotai',
 '嘉平' := 'jiaping',
 '嘉慶' := 'jiaqing',
 '嘉泰' := 'jiatai',
 '嘉熙' := 'jiaxi',
 '嘉興' := 'jiaxing',
 '嘉祐' := 'jiayou',
 '景初' := 'jingchu',
 '景德' := 'jingde',
 '景定' := 'jingding',
 '景福' := 'jingfu',
 '景和' := 'jinghe',
 '靖康' := 'jingkang',
 '景龍' := 'jinglong',
 '景明' := 'jingming',
 '竟寧' := 'jingning',
 '景平' := 'jingping',
 '景泰' := 'jingtai',
 '景炎' := 'jingyan',
 '景耀' := 'jingyao',
 '景祐' := 'jingyou',
 '景元' := 'jingyuan',
 '景雲' := 'jingyun',
 '久視' := 'jiushi',
 '居攝' := 'jushe',
 '開寶' := 'kaibao',
 '開成' := 'kaicheng',
 '開皇' := 'kaihuang',
 '開明' := 'kaiming',
 '開平' := 'kaiping',
 '開慶' := 'kaiqing',
 '開泰' := 'kaitai',
 '開禧' := 'kaixi',
 '開興' := 'kaixing',
 '開耀' := 'kaiyao',
 '開元' := 'kaiyuan',
 '開運' := 'kaiyun',
 '康定' := 'kangding',
 '康國' := 'kangguo',
 '康熙' := 'kangxi',
 '麟德' := 'linde',
 '麟嘉' := 'linjia',
 '隆安' := 'longan',
 '隆昌' := 'longchang',
 '龍德' := 'longde',
 '龍飛' := 'longfei',
 '隆和' := 'longhe',
 '隆化' := 'longhua',
 '龍紀' := 'longji',
 '龍啟' := 'longqi',
 '隆慶' := 'longqing',
 '龍昇' := 'longsheng',
 '龍朔' := 'longshuo',
 '隆武' := 'longwu',
 '隆興' := 'longxing',
 '明昌' := 'mingchang',
 '明道' := 'mingdao',
 '明德' := 'mingde',
 '寧康' := 'ningkang',
 '普泰' := 'putai',
 '普通' := 'putong',
 '乾道' := 'qiandao',
 '乾德' := 'qiande',
 '乾定' := 'qianding',
 '乾封' := 'qianfeng',
 '乾符' := 'qianfu',
 '乾和' := 'qianhe',
 '乾亨' := 'qianheng',
 '乾化' := 'qianhua',
 '乾隆' := 'qianlong',
 '乾明' := 'qianming',
 '乾寧' := 'qianning',
 '乾統' := 'qiantong',
 '乾興' := 'qianxing',
 '乾祐' := 'qianyou',
 '乾元' := 'qianyuan',
 '乾貞' := 'qianzhen',
 '乾正' := 'qianzheng',
 '慶曆' := 'qingli',
 '青龍' := 'qinglong',
 '清寧' := 'qingning',
 '清泰' := 'qingtai',
 '慶元' := 'qingyuan',
 '人慶' := 'renqing',
 '仁壽' := 'renshou',
 '如意' := 'ruyi',
 '上元' := 'shangyuan',
 '紹定' := 'shaoding',
 '紹聖' := 'shaosheng',
 '紹泰' := 'shaotai',
 '紹武' := 'shaowu',
 '紹熙' := 'shaoxi',
 '紹興' := 'shaoxing',
 '神冊' := 'shence',
 '神鼎' := 'shending',
 '神鳳' := 'shenfeng',
 '聖曆' := 'shengli',
 '昇明' := 'shengming',
 '神功' := 'shengong',
 '升平' := 'shengping',
 '神龜' := 'shengui',
 '昇元' := 'shengyuan',
 '神麚' := 'shenjia',
 '神爵' := 'shenjue',
 '神龍' := 'shenlong',
 '神瑞' := 'shenrui',
 '神璽' := 'shenxi',
 '始光' := 'shiguang',
 '始建國' := 'shijianguo',
 '始元' := 'shiyuan',
 '壽昌' := 'shouchang',
 '壽光' := 'shouguang',
 '收國' := 'shouguo',
 '順義' := 'shunyi',
 '嗣聖' := 'sisheng',
 '綏和' := 'suihe',
 '太安' := 'taian',
 '泰常' := 'taichang',
 '太昌' := 'taichang',
 '泰昌' := 'taichang',
 '太初' := 'taichu',
 '泰定' := 'taiding',
 '太和' := 'taihe',
 '泰和' := 'taihe',
 '太極' := 'taiji',
 '太建' := 'taijian',
 '太康' := 'taikang',
 '太寧' := 'taining',
 '太平' := 'taiping',
 '太清' := 'taiqing',
 '太上' := 'taishang',
 '太始' := 'taishi',
 '泰始' := 'taishi',
 '太熙' := 'taixi',
 '太興' := 'taixing',
 '太延' := 'taiyan',
 '泰豫' := 'taiyu',
 '太元' := 'taiyuan',
 '太宗' := 'taizong',
 '太祖' := 'taizu',
 '唐隆' := 'tanglong',
 '天安' := 'tianan',
 '天保' := 'tianbao',
 '天寶' := 'tianbao',
 '天成' := 'tiancheng',
 '天盛' := 'tiancheng',
 '天賜' := 'tianci',
 '天聰' := 'tiancong',
 '天德' := 'tiande',
 '天鳳' := 'tianfeng',
 '天復' := 'tianfu',
 '天福' := 'tianfu',
 '天輔' := 'tianfu',
 '天光' := 'tianguang',
 '天漢' := 'tianhan',
 '天和' := 'tianhe',
 '天會' := 'tianhui',
 '天紀' := 'tianji',
 '天嘉' := 'tianjia',
 '天監' := 'tianjian',
 '天眷' := 'tianjuan',
 '天康' := 'tiankang',
 '天曆' := 'tianli',
 '天祿' := 'tianlu',
 '天命' := 'tianming',
 '天平' := 'tianping',
 '天啟' := 'tianqi',
 '天慶' := 'tianqing',
 '天聖' := 'tiansheng',
 '天授' := 'tianshou',
 '天順' := 'tianshun',
 '天統' := 'tiantong',
 '天璽' := 'tianxi',
 '天禧' := 'tianxi',
 '天顯' := 'tianxian',
 '天興' := 'tianxing',
 '天鍹' := 'tianxuan',
 '天祐' := 'tianyou',
 '天贊' := 'tianzan',
 '天正' := 'tianzheng',
 '天祚' := 'tianzuo',
 '同光' := 'tongguang',
 '統和' := 'tonghe',
 '通文' := 'tongwen',
 '通正' := 'tongzheng',
 '同治' := 'tongzhi',
 '萬曆' := 'wanli',
 '未詳' := 'weixiang',
 '文德' := 'wende',
 '文明' := 'wenming',
 '武成' := 'wucheng',
 '武德' := 'wude',
 '武定' := 'wuding',
 '五鳳' := 'wufeng',
 '武平' := 'wuping',
 '武泰' := 'wutai',
 '武義' := 'wuyi',
 '道光' := 'xaoguang',
 '咸安' := 'xianan',
 '咸淳' := 'xianchun',
 '顯道' := 'xiandao',
 '顯德' := 'xiande',
 '咸豐' := 'xianfeng',
 '祥興' := 'xiangxing',
 '咸和' := 'xianhe',
 '咸亨' := 'xianheng',
 '咸康' := 'xiankang',
 '咸寧' := 'xianning',
 '咸平' := 'xianping',
 '顯慶' := 'xianqing',
 '咸清' := 'xianqing',
 '先天' := 'xiantian',
 '咸通' := 'xiantong',
 '咸熙' := 'xianxi',
 '咸雍' := 'xianyong',
 '憲宗' := 'xianzong',
 '孝昌' := 'xiaochang',
 '孝建' := 'xiaojian',
 '興安' := 'xingan',
 '興定' := 'xingding',
 '興光' := 'xingguang',
 '興和' := 'xinghe',
 '興寧' := 'xingning',
 '興平' := 'xingping',
 '興元' := 'xingyuan',
 '熙寧' := 'xining',
 '熹平' := 'xiping',
 '熙平' := 'xiping',
 '宣德' := 'xuande',
 '宣光' := 'xuanguang',
 '宣和' := 'xuanhe',
 '玄始' := 'xuanshi',
 '宣統' := 'xuantong',
 '宣政' := 'xuanzheng',
 '延昌' := 'yanchang',
 '陽嘉' := 'yangjia',
 '陽朔' := 'yangshuo',
 '延光' := 'yanguang',
 '延和' := 'yanhe',
 '延康' := 'yankang',
 '延平' := 'yanping',
 '晏平' := 'yanping',
 '燕平' := 'yanping',
 '延慶' := 'yanqing',
 '延熹' := 'yanxi',
 '延熙' := 'yanxi',
 '炎興' := 'yanxing',
 '延興' := 'yanxing',
 '燕興' := 'yanxing',
 '延祐' := 'yanyou',
 '燕元' := 'yanyuan',
 '延載' := 'yanzai',
 '儀鳳' := 'yifeng',
 '義和' := 'yihe',
 '應曆' := 'yingli',
 '應乾' := 'yingqian',
 '應順' := 'yingshun',
 '應天' := 'yingtian',
 '義寧' := 'yining',
 '義熙' := 'yixi',
 '永安' := 'yongan',
 '永昌' := 'yongchang',
 '永初' := 'yongchu',
 '永淳' := 'yongchun',
 '永定' := 'yongding',
 '永鳳' := 'yongfeng',
 '永光' := 'yongguang',
 '永漢' := 'yonghan',
 '永和' := 'yonghe',
 '永弘' := 'yonghong',
 '永徽' := 'yonghui',
 '永嘉' := 'yongjia',
 '永建' := 'yongjian',
 '永康' := 'yongkang',
 '永樂' := 'yongle',
 '永曆' := 'yongli',
 '永隆' := 'yonglong',
 '永明' := 'yongming',
 '永寧' := 'yongning',
 '雍寧' := 'yongning',
 '永平' := 'yongping',
 '永始' := 'yongshi',
 '永壽' := 'yongshou',
 '永泰' := 'yongtai',
 '永喜' := 'yongxi',
 '永熙' := 'yongxi',
 '雍熙' := 'yongxi',
 '永興' := 'yongxing',
 '永元' := 'yongyuan',
 '永貞' := 'yongzhen',
 '雍正' := 'yongzheng',
 '元初' := 'yuanchu',
 '元德' := 'yuande',
 '元鼎' := 'yuanding',
 '元封' := 'yuanfeng',
 '元鳳' := 'yuanfeng',
 '元豐' := 'yuanfeng',
 '元符' := 'yuanfu',
 '元光' := 'yuanguang',
 '元和' := 'yuanhe',
 '元徽' := 'yuanhui',
 '元嘉' := 'yuanjia',
 '元康' := 'yuankang',
 '元平' := 'yuanping',
 '元始' := 'yuanshi',
 '元狩' := 'yuanshou',
 '元壽' := 'yuanshou',
 '元朔' := 'yuanshuo',
 '元統' := 'yuantong',
 '元熙' := 'yuanxi',
 '元璽' := 'yuanxi',
 '元象' := 'yuanxiang',
 '元興' := 'yuanxing',
 '元延' := 'yuanyan',
 '元祐' := 'yuanyou',
 '元貞' := 'yuanzhen',
 '玉衡' := 'yuheng',
 '玉恒' := 'yuheng',
 '載初' := 'zaichu',
 '章和' := 'zhanghe',
 '章武' := 'zhangwu',
 '昭寧' := 'zhaoning',
 '正大' := 'zhengda',
 '正德' := 'zhengde',
 '正光' := 'zhengguang',
 '征和' := 'zhenghe',
 '政和' := 'zhenghe',
 '正隆' := 'zhenglong',
 '正平' := 'zhengping',
 '證聖' := 'zhengsheng',
 '正始' := 'zhengshi',
 '正統' := 'zhengtong',
 '貞觀' := 'zhenguan',
 '正元' := 'zhengyuan',
 '禎明' := 'zhenming',
 '貞明' := 'zhenming',
 '真興' := 'zhenxing',
 '貞祐' := 'zhenyou',
 '貞元' := 'zhenyuan',
 '至大' := 'zhida',
 '至道' := 'zhidao',
 '至德' := 'zhide',
 '至和' := 'zhihe',
 '致和' := 'zhihe',
 '至寧' := 'zhining',
 '治平' := 'zhiping',
 '至順' := 'zhishun',
 '至元' := 'zhiyuan',
 '至正' := 'zhizheng',
 '至治' := 'zhizhi',
 '中和' := 'zhonghe',
 '重和' := 'zhonghe',
 '中平' := 'zhongping',
 '中統' := 'zhongtong',
 '重熙' := 'zhongxi',
 '中興' := 'zhongxing',
 '總章' := 'zongzhang',
 '大中祥符' := 'dazhongXiangfu',
 '福聖承道' := 'fushengChengdao',
 '建武中元' := 'jianwuZhongyuan',
 '建中靖國' := 'jianzhongJingguo',
 '乃馬真后' := 'naimaZhenhou',
 '順治' := 'shunzhi',
 '太平興國' := 'taipingXingguo',
 '太平真君' := 'taipingZhenjun',
 '天安禮定' := 'tiananLiding',
 '天冊萬歲' := 'tianceWansui',
 '天賜禮盛國慶' := 'tianciLichengGuoqing',
 '天授禮法延祚' := 'tianshouLifaYanzuo',
 '天儀治平' := 'tianyiZhiping',
 '天祐垂聖' := 'tianyouChuisheng',
 '天祐民安' := 'tianyouMinan',
 '萬歲登封' := 'wansuiDengfeng',
 '萬歲通天' := 'wansuiTongtian',
 '延嗣寧國' := 'yansiNingguo',
 '中大通' := 'zhongDatong',
 '中大同' := 'zhongDatong',
 '中華民國' := 'zhonghuaMinguo'
 }
 
 
let $date_PY := 
    for $dy in $DYNASTIES//c_dy[. = $dynasty/text()][ . != 0],        
        $motto in $NIAN_HAO//c_nianhao_id[. = $reign/text()][ . != 0], 
        $num in $year/text()[ . != 0]
    return
        string-join(
            (functx:words-to-camel-case(functx:substring-before-match($dy/../c_dynasty/text(), '\s\(')),
            $NH-py($motto/../c_nianhao_chn/text()), 
            $num/text()),
        '-')


let $date_ZH := 
    for $dy in $DYNASTIES//c_dy[. = $dynasty/text()][ . != 0],        
        $motto in $NIAN_HAO//c_nianhao_id[. = $reign/text()][ . != 0], 
        $num in $year/text()[ . != 0]
    return
        string-join(($dy/../c_dynasty_chn/text(), $motto/../c_nianhao_chn/text(), $num/text()), '-')

return        
element date { attribute datingMethod {'#chinTrad'}, 
    attribute calendar {'#chinTrad'},
    switch
        ($type)
            case 'notBefore'return attribute notBefore-custom {$date_PY}
            case 'notAfter' return attribute notAfter-custom {$date_PY}
            case 'from' return attribute from-custom {$date_PY}
            case 'to' return attribute to-custom {$date_PY}
            default return  attribute when-custom  {$date_PY},
         $date_ZH   
        
}
};

declare function local:ganzhi ($year as xs:integer, $lang as xs:string?)  as xs:string* {

(:Just for fun: calculate the ganzhi cycle for gYears where $year is an integer,
and $lang is either hanzi = 'zh', or pinyin ='py' for output. 

The function assumes that $year is an isoyear using astronomical calendar conventions so:
AD 1 = year 1, = 0001 xs:gYear
1 BC = year 0, = -0001 xs:gYear
2 BC = year −1, = -0002 xs:gYear
etc. :)

(: TEST:

local:ganzhi(2036, 'zh') -> 丙辰
local:ganzhi(1981, 'zh') -> 辛酉
local:ganzhi(1967, 'zh') -> 丁未
local:ganzhi(0004, 'zh') -> 甲子
local:ganzhi(0001, 'zh') -> 壬戌
local:ganzhi(0000, 'zh') -> no such gYear 
local:ganzhi(-0001, 'zh') -> 庚申
local:ganzhi(-0247, 'zh') -> 乙卯 = 246BC founding of Qing

:)

    let $ganzhi_zh := 
        for $step in (1 to 60)
        
        let $stem_zh := ('甲', '乙','丙','丁','戊','己','庚','辛','壬','癸') 
        let $branch_zh := ('子','丑','寅,','卯','辰','巳','午','未','申','酉','戌','亥')            
        
        return
            if ($step = 60) then (concat($stem_zh[10], $branch_zh[12]))
            else if ($step mod 10 = 0) then (concat($stem_zh[10], $branch_zh[$step mod 12]))
            else if ($step mod 12 = 0) then (concat($stem_zh[$step mod 10], $branch_zh[12]))
            else concat($stem_zh[$step mod 10], $branch_zh[$step mod 12])  
            
   let $ganzhi_py :=
        for $step in (1 to 60)        
        
        let $stem_py := ('jiǎ', 'yǐ', 'bǐng', 'dīng', 'wù', 'jǐ', 'gēng', 'xīn', 'rén', 'guǐ')
        let $branch_py := ('zǐ', 'chǒu', 'yín, ', 'mǎo', 'chén', 'sì', 'wǔ', 'wèi', 'shēn', 'yǒu', 'xū', 'hài')
        
         return
            if ($step = 60) then (concat($stem_py[10], ' ', $branch_py[12]))
            else if ($step mod 10 = 0) then (concat($stem_py[10], ' ', $branch_py[$step mod 12]))
            else if ($step mod 12 = 0) then (concat($stem_py[$step mod 10], ' ', $branch_py[12]))
            else concat($stem_py[$step mod 10], ' ', $branch_py[$step mod 12])          
            
    
   let $sexagenary_zh :=
        map:new(
        for $ganzhi at $pos in $ganzhi_zh
        return
            map:entry($pos, $ganzhi)
                )
    
    let $sexagenary_py :=
           map:new(
           for $ganzhi at $pos in $ganzhi_py
           return
               map:entry($pos, $ganzhi)
                   )
                   
    return
        switch ($lang)
        case 'zh'
            return     
                if  ($year > 3)  then ($sexagenary_zh((($year -3) mod 60)))
                    else if ($year = 3)  then ($sexagenary_zh(60))
                    else if ($year = 2)  then ($sexagenary_zh(59))
                    else if ($year = 1)  then ($sexagenary_zh(58))
                    else if ($year = -1)  then ($sexagenary_zh(57))
                    else if ($year < -1)  then ($sexagenary_zh((60 - (($year * -1) +1) mod 60)))        
                else "0年 …太複雜"
        case 'py'
            return     
                if  ($year > 3)  then ($sexagenary_py((($year -3) mod 60)))
                    else if ($year = 3)  then ($sexagenary_py(60))
                    else if ($year = 2)  then ($sexagenary_py(59))
                    else if ($year = 1)  then ($sexagenary_py(58))
                    else if ($year = -1)  then ($sexagenary_py(57))
                    else if ($year < -1)  then ($sexagenary_py((60 - (($year * -1) +1) mod 60)))        
                else "0 AD/CE  … it's complicated"
        default return "please specify either 'py' or 'zh'"    
            
};

declare function local:sexagenary ($ganzhi as node()*) as node() {
<taxonomy xml:id="sexagenary"> 
{ 
for $gz in $ganzhi
return         
    <category xml:id="{concat('S', $gz/c_ganzhi_code/text())}">
        <catDesc xml:lang="zh-Hant">{$gz/c_ganzhi_chn/text()}</catDesc>
        <catDesc xml:lang="zh-alalc97">{$gz/c_ganzhi_py/text()}</catDesc>
    </category>
            }
</taxonomy>
};

declare function local:dynasties ($dynasties as node()*) as node() {
<taxonomy xml:id="reign">
    {
    for $dy in $dynasties
    let $dy_id := $dy/c_dy
    where $dy/c_dy > '0'
    return                
        <category xml:id="{concat('D', $dy/c_dy/text())}">
            <catDesc>
                <date from="{local:isodate($dy/c_start)}" to="{local:isodate($dy/c_end)}"/>
        </catDesc>
        <catDesc xml:lang="zh-Hant">{$dy/c_dynasty_chn/text()}</catDesc>
        <catDesc xml:lang="en">{$dy/c_dynasty/text()}</catDesc>
        {
        for $nh in $NIAN_HAO//row 
        where $nh/c_dy = $dy_id
        return
            if ($nh/c_nianhao_pin != '')
            then (<category xml:id="{concat('R' , $nh/c_nianhao_id/text())}">
                        <catDesc>
                            <date from="{local:isodate($nh/c_firstyear)}" to="{local:isodate($nh/c_lastyear)}"/>
                        </catDesc>
                        <catDesc xml:lang="zh-Hant">{$nh/c_nianhao_chn/text()}</catDesc>
                        <catDesc xml:lang="zh-alalc97">{$nh/c_nianhao_pin/text()}</catDesc>
                   </category>) 
            else (<category xml:id="{concat('R' , $nh/c_nianhao_id/text())}">
                        <catDesc>
                            <date from="{local:isodate($nh/c_firstyear)}" to="{local:isodate($nh/c_lastyear)}"/>                    
                        </catDesc>
                        <catDesc xml:lang="zh-Hant">{$nh/c_nianhao_chn/text()}</catDesc>
                    </category>)                           
        }
        </category>
    }
</taxonomy>
};

xmldb:store($target, 'cal_ZH.xml', 
    <taxonomy xml:id="cal_ZH">                
        {local:sexagenary($GANZHI_CODES//row)}
        {local:dynasties($DYNASTIES//row)}
    </taxonomy>
)

            

        