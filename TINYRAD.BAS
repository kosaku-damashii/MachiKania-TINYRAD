REM ===================================
REM  TINYRAD.BAS
REM  for RDA5807M FM Radio Tuner
REM  on MachiKania type P/PU
REM ===================================

USECLASS CKNJ8

USEVAR ADA,ADB,REG,HI,LO,VOL,STC,FREQ,RSSI,ST,NE,NJ

REM I2C 7bit slave addresses
ADA = $10
ADB = $11

REM RDA registers 02H-07H (32bit)
DIM R(5)

REM initialize register values
REM BAND:76-108 MHz (world wide)
REM SPACE:100 kHz
R(0) = $0000D005
R(1) = $00000008
R(2) = $00000A00
R(3) = $00008880
R(4) = 0
R(5) = 0


REM Volume (0-15)
V = 1

REM Clock (kHz)
I2C 100

CLS
COLOR 5
PRINT "Tiny Radio"
COLOR 6
PRINT "[FIRE]=Quit [START]=Seek [";CHR$($1E);"]/[";CHR$($1F);"]=Vol"
COLOR 7

GOSUB RDAINIT
GOSUB(SETVOL,V)
GOSUB SEEKUP

DO
  K = KEYS()
  IF K==0 THEN
    WAIT 10
    CONTINUE
  ELSEIF K==16 THEN
    GOSUB SEEKUP
  ELSEIF K==1 THEN
    IF V<15 THEN
      V = V + 1
      V = GOSUB(SETVOL,V)
    ENDIF
  ELSEIF K==2 THEN
    IF V>0 THEN
      V = V - 1
      V = GOSUB(SETVOL,V)
    ENDIF
  ELSEIF K==32 THEN
    END
  ENDIF
  WAIT 10
LOOP

REM --------------------------------
REM get high byte of R(reg)
LABEL GETHI
  VAR REG
  REG = ARGS(1)
  RETURN PEEK(R + REG*4 + 1)

REM get low byte of R(reg)
LABEL GETLO
  VAR REG
  REG = ARGS(1)
  RETURN PEEK(R + REG*4 + 0)

REM --------------------------------
REM write one register
LABEL WRITEREG
  VAR REG,HI,LO
  REG = ARGS(1)
  HI = GOSUB(GETHI,REG)
  LO = GOSUB(GETLO,REG)
  I2CWRITE ADB,2+REG,HI,LO
  WAIT 1
  REM PRINT "[0";2+REG;"] ";HEX$(HI,2);HEX$(LO,2)
  RETURN 0

REM --------------------------------
REM write all registers 0x02-0x07
LABEL WRITEALL
  VAR I
  FOR I=0 TO 5
    GOSUB(WRITEREG,I)
  NEXT
  RETURN 0

REM --------------------------------
REM set volume
LABEL SETVOL
  VAR VOL
  VOL = ARGS(1)
  R(3) = (R(3) AND $FFFFFFF0) OR VOL
  GOSUB(WRITEREG,3)
  CURSOR 0,5
  PRINT "Volume: ";VOL;"  "
  RETURN VOL

REM --------------------------------

REM seek up
LABEL SEEKUP
VAR STC,FREQ,RSSI,ST,F,NE,NJ

  REM RDA registers 0AH-0FH (32bit)
  DIM G((6/2)-1)
  R(0) = R(0) OR $00000300
  GOSUB(WRITEREG,0)
  COLOR 2
  CURSOR 0,3:PRINT "Seek               "
  CURSOR 0,4:PRINT "                                      "
  CURSOR 0,6:PRINT "           "
  CURSOR 0,7:PRINT "      "

  DO
    I2CREADDATA ADA,G,6*4
    WAIT 1
    STC = PEEK(G) AND $40
  LOOP UNTIL (STC != 0)
  COLOR 7

  REM Print Frequency
  FREQ = (PEEK(G) AND $03) << 8
  FREQ = FREQ + PEEK(G+1) + 760
  CURSOR 0,3:PRINT "Frequency: ";FREQ/10;".";FREQ%10;" MHz "

  REM Print Station Name
  RESTORE STA
  DO

   F=READ()
   NE$=READ$()
   NJ$=READ$()
   IF F==FREQ OR F==0 THEN
REM     CURSOR 0,4:PRINT "Name:   ";NE$
    K=NEW(CKNJ8,"UTF-8")
    CURSOR 0,4:PRINT "Name:   ";:K.PRT(NJ$)
    DELETE K
    BREAK
   ENDIF
  LOOP WHILE F>0

  REM Print RSSI level
  RSSI = (PEEK(G+2) AND $FE) >> 1
  CURSOR 0,6:PRINT "Signal: ";RSSI;" "

  REM Print Stereo/Mono
  ST = (PEEK(G) AND $04) >> 2
  CURSOR 0,7
  IF ST==0 THEN 
    PRINT "Mono  "
  ELSE
    PRINT "Stereo"
  ENDIF

  RETURN 0


REM --------------------------------
REM RDA init
LABEL RDAINIT
  R(0) = R(0) OR $00000002
  R(0) = R(0) AND $FFFFFFFD
  GOSUB(WRITEALL)
  RETURN 0


REM -------------------------------
REM 
LABEL STA
DATA 761,"FM Iwate","エフエム岩手",
     761,"FM Fukui","FM福井",
     761,"LOVE FM","LOVE FM",
     764,"RADIO BERRY","RADIO BERRY",
     764,"AIR-G' (Asahikawa)","AIR-G'（旭川）",
     765,"FM COCOLO", "FM COCOLO",
     768,"FM Okayama","FM岡山",
     770,"e-radio","e-radio",
     771,"Date fm","Date fm",
     774,"FM San-in","V-air エフエム山陰",
     774,"FMK","FMK エフエム・クマモト",
     775,"FM NIIGATA","FM-NIIGATA",
     778,"ZIP-FM","ZIP-FM",
     779,"FM Saga","エフエム佐賀",
     780,"bayfm78","bayfm78",
     782,"HFM","HFM",
     785,"AIR-G' (Obihiro)","AIR-G'（帯広）",
     786,"FM Kagawa","FM香川",
     787,"CROSS FM","CROSS FM",
     789,"FM Mie","レディオキューブFM三重",
     792,"K-MIX","K-MIX",
     792,"FM Yamaguchi","エフエム山口",
     795,"NACK5","FM NACK5",
     795,"FM Nagasaki","エフエム長崎",
     797,"FM Nagano","FM長野",
     797,"FM Ehime","FM愛媛",
     798,"FM Kagoshima","μFM エフエム鹿児島",
     800,"TOKYO FM","TOKYO FM",
     800,"FM Aomori","エフエム青森",
     800,"FM GIFU","FM GIFU",
     802,"FM802","FM802",
     804,"AIR-G'","AIR-G'",
     804,"FM Yamagata","エフエム山形",
     805,"FM Ishikawa","エフエム石川",
     807,"FM AICHI","FM AICHI",
     807,"FM Tokushima","エフエム徳島",
     807,"FM FUKUOKA","FM FUKUOKA",
     813,"J-WAVE","J-WAVE",
     816,"NHK-FM (Gunma)","NHK-FM 群馬",
     816,"FM Kochi","FM高知",
     818,"Fukushima FM","ふくしまFM",
     819,"NHK-FM (Kanagawa)","NHK-FM 神奈川",
     821,"NHK-FM (Yamagata)","NHK-FM 山形",
     823,"NHK-FM (Niigata)","NHK-FM 新潟",
     825,"NHK-FM (Tokyo)","NHK-FM 東京",
     825,"FM NORTH WAVE","NORTH WAVE",
     825,"NHK-FM (Aichi)","NHK-FM 愛知",
     827,"FM Toyama","FMとやま",
     828,"FM Akita","エフエム秋田",
     828,"NHK-FM (Kyoto)","NHK-FM 京都",
     830,"FM FUJI","FM FUJI",
     831,"NHK-FM (Iwate)","NHK-FM 岩手",
     832,"NHK-FM (Ibaraki)","NHK-FM 茨城",
     832,"JOY FM","JOY FM FM宮崎",
     834,"NHK-FM (Fukui)","NHK-FM 福井",
     834,"NHK-FM (Tokushima)","NHK-FM 徳島",
     836,"NHK-FM (Gifu)","NHK-FM 岐阜",
     840,"NHK-FM (Nagano)","NHK-FM 長野",
     840,"NHK-FM (Shiga)","NHK-FM 滋賀",
     847,"FM YOKOHAMA","FMヨコハマ",
     847,"NHK-FM (Wakayama)","NHK-FM 和歌山",
     845,"NHK-FM (Shimane)","NHK-FM 島根",
     845,"NHK-FM (Nagasaki)","NHK-FM 長崎",
     851,"FM OSAKA","FM大阪",
     853,"NHK-FM (Fukushima)","NHK-FM 福島",
     853,"NHK-FM (Yamaguchi)","NHK-FM 山口",
     858,"NHK-FM (Asahikawa)","NHK-FM 北海道（旭川）",
     858,"NHK-FM (Tottori)","NHK-FM 鳥取",
     862,"NHK-FM (Miyazaki)","NHK-FM 宮崎",
     863,"FM GUNMA","FMぐんま",
     865,"NHK-FM (Hyogo)","NHK-FM 兵庫",
     867,"NHK-FM (Akita)","NHK-FM 秋田",
     870,"NHK-FM (Hokkaido)","NHK-FM 北海道（函館）",
     873,"FM Okinawa", "エフエム沖縄",
     874,"NHK-FM (Nara)","NHK-FM 奈良",
     877,"NHK-FM (Ehime)","NHK-FM 愛媛",
     880,"NHK-FM (Muroran)","NHK-FM 北海道（室蘭）",
     880,"FM Oita","エフエム大分",
     881,"NHK-FM (Osaka)","NHK-FM 大阪",
     881,"NHK-FM (Okinawa)","NHK-FM 沖縄",
     885,"NHK-FM (Kushiro)","NHK-FM 北海道（釧路）",
     888,"NHK-FM (Shizuoka)","NHK-FM 静岡",
     889,"NHK-FM (Oita)","NHK-FM 大分",
     894,"AIR-G' (Muroran)","AIR-G'（室蘭）",
     894,"Alpha Station","α-STATION",
     897,"interfm","InterFM897",
     899,"Kiss FM KOBE","Kiss FM KOBE",
     901,"ABS Radio","秋田放送",
     902,"Radio Fukushima","ラジオ福島",
     902,"KNB Radio","北日本放送",
     902,"KBC Radio","KBCラジオ",
     903,"RNC Radio","西日本放送",
     904,"STV Radio","STVラジオ",
     904,"Gifu Radio","ぎふチャン",
     904,"MRT Radio","MRTラジオ",
     905,"TBS Radio","TBSラジオ",
     906,"IBC Radio","IBC岩手放送",
     906,"MBS Radio","MBSラジオ",
     908,"Radio Fukushima","ラジオ福島",
     908,"RKC Radio","RKC高知放送",
     909,"YBS Radio","YBSラジオ",
     910,"RKB Radio","RKBラジオ",
     911,"Radio Kansai","ラジオ関西",
     914,"RSK Radio","RSKラジオ",
     914,"RKK Radio","RKKラジオ",
     915,"HBC Radio","HBCラジオ",
     916,"Bunka Hoso","文化放送",
     917,"RAB Radio","RAB青森放送",
     917,"RNB Radio","南海放送",
     919,"OBC Radio Osaka","OBCラジオ大阪",
     921,"RBCi Radio","RBCiラジオ",
     922,"SBC Radio","SBCラジオ",
     922,"BSS Radio","BSSラジオ",
     923,"KRY Radio","KRY山口放送",
     924,"Radio Nippon","ラジオ日本",
     924,"YBC Radio","YBC山形放送",
     926,"NBC Radio","NBCラジオ",
     927,"BSN Radio","BSNラジオ",
     928,"MBC Radio","MBCラジオ",
     929,"TOKAI RADIO","TOKAI RADIO",
     930,"Nippon Broadcasting System","ニッポン放送",
     930,"JRT Shikoku Broadcasting","JRT四国放送",
     931,"ROK Radio","ラジオ沖縄",
     933,"ABC Radio","ABCラジオ",
     933,"OBS Radio","OBSラジオ",
     935,"TBC Radio","tbcラジオ",
     937,"CBC Radio","CBCラジオ",
     939,"SBS Radio","SBSラジオ",
     940,"MRO Radio","MROラジオ",
     941,"CRT Radio","CRT栃木放送",
     942,"WBS Radio","WBS和歌山放送ラジオ",
     946,"LuckyFM","LuckyFM茨城放送",
     946,"FBC Radio","FBCラジオ",
     946,"RCC Radio","RCCラジオ",
     949,"KBS Kyoto Radio","KBS京都ラジオ",
     0,  "Unknown","不明"
