REM ===================================
REM  TINYRAD.BAS
REM  for RDA5807M FM Radio Tuner
REM  on MachiKania type P/PU
REM ===================================

USECLASS CKNJ8

USEVAR ADA,ADB,REG,HI,LO,VOL,STC,FREQ,RSSI,ST,NE,NJ

K=NEW(CKNJ8,"UTF-8")

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
PRINT "[START]=Seek  [UP]/[DOWN]=Vol"
COLOR 7

GOSUB RDAINIT
GOSUB(SETVOL,V)
GOSUB SEEKUP

DO
  K = KEYS()
  IF K==0 THEN
    WAIT 10
    CONTINUE
  ENDIF
  IF (K==16) THEN
    GOSUB SEEKUP
  ENDIF
  IF (K==1) THEN
    IF V < 15 THEN
      V = V + 1
      V = GOSUB(SETVOL,V)
    ENDIF
  ENDIF
  IF (K==2) THEN
    IF V > 0 THEN
      V = V - 1
      V = GOSUB(SETVOL,V)
    ENDIF
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
  PRINT "Volume: ";VOL;" "
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

  DO
    I2CREADDATA ADA,G,6*4
    WAIT 1
    STC = PEEK(G) AND $40
  LOOP UNTIL (STC != 0)
  COLOR 7

  REM Print Frequency
  FREQ = (PEEK(G) AND $03) << 8
  FREQ = FREQ + PEEK(G+1) + 760
  CURSOR 0,3:PRINT "Frequency: ";FREQ/10;".";FREQ%10;" MHz"

  REM Print Station Name
  RESTORE STA
  DO

   F=READ()
   NE$=READ$()
   NJ$=READ$()
   IF F==FREQ OR F==0 THEN
    CURSOR 0,4:PRINT "Name:   ";NE$
    REM CURSOR 0,4:PRINT "Name:   ";:K.PRT(NJ$)
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
DATA 761, "FM Iwate", "エフエム岩手",
     761, "FM Fukui", "エフエム福井",
     761, "LOVE FM", "ラブエフエム",
     762, "NHK-FM Toyama", "NHK-FM 富山",
     763, "FM Oita", "エフエム大分",
     763, "NHK-FM Oita", "NHK-FM 大分",
     764, "NHK-FM Aomori", "NHK-FM 青森",
     765, "FM COCOLO", "エフエムココロ",
     765, "NHK-FM Nagasaki", "NHK-FM 長崎",
     766, "NHK-FM Yamaguchi", "NHK-FM 山口",
     767, "NHK-FM Kochi", "NHK-FM 高知",
     768, "FM Okayama", "エフエム岡山",
     768, "NHK-FM Okayama", "NHK-FM 岡山",
     769, "NHK-FM Kumamoto", "NHK-FM 熊本",
     770, "e-radio", "エフエム滋賀",
     770, "NHK-FM Shiga", "NHK-FM 滋賀",
     771, "Date fm", "エフエム仙台",
     772, "NHK-FM Miyagi", "NHK-FM 宮城",
     773, "NHK-FM Kagoshima", "NHK-FM 鹿児島",
     774, "FM Sanin", "エフエム山陰",
     774, "NHK-FM Shimane", "NHK-FM 島根",
     775, "FM Niigata", "エフエム新潟",
     775, "NHK-FM Niigata", "NHK-FM 新潟",
     776, "NHK-FM Hiroshima", "NHK-FM 広島",
     777, "NHK-FM Ehime", "NHK-FM 愛媛",
     778, "ZIP-FM", "ジップエフエム",
     778, "NHK-FM Aichi", "NHK-FM 愛知",
     780, "bayfm", "ベイエフエム",
     781, "NHK-FM Wakayama", "NHK-FM 和歌山",
     782, "Hiroshima FM", "広島エフエム",
     782, "NHK-FM Hiroshima", "NHK-FM 広島",
     783, "NHK-FM Gifu", "NHK-FM 岐阜",
     784, "NHK-FM Yamanashi", "NHK-FM 山梨",
     785, "NHK-FM Akita", "NHK-FM 秋田",
     786, "FM Kagawa", "エフエム香川",
     786, "NHK-FM Kagawa", "NHK-FM 香川",
     787, "CROSS FM", "クロスエフエム",
     787, "NHK-FM Fukuoka", "NHK-FM 福岡",
     790, "FM Kumamoto", "エフエム熊本",
     791, "NHK-FM Kyoto", "NHK-FM 京都",
     792, "K-MIX", "ケーミックス（静岡FM）",
     792, "NHK-FM Shizuoka", "NHK-FM 静岡",
     793, "NHK-FM Ibaraki", "NHK-FM 茨城",
     794, "NHK-FM Tochigi", "NHK-FM 栃木",
     795, "NACK5", "エフエムナックファイブ",
     795, "NHK-FM Saitama", "NHK-FM 埼玉",
     796, "NHK-FM Gunma", "NHK-FM 群馬",
     797, "FM Nagano", "長野エフエム",
     797, "FM Ehime", "エフエム愛媛",
     797, "NHK-FM Nagano", "NHK-FM 長野",
     800, "TOKYO FM", "東京エフエム",
     800, "FM Aomori", "エフエム青森",
     801, "NHK-FM Tokyo", "NHK-FM 東京",
     802, "FM802", "エフエム802",
     803, "NHK-FM Osaka", "NHK-FM 大阪",
     804, "AIR-G'", "エフエム北海道",
     804, "FM Yamagata", "エフエム山形",
     805, "FM Ishikawa", "エフエム石川",
     805, "NHK-FM Ishikawa", "NHK-FM 石川",
     806, "NHK-FM Tottori", "NHK-FM 鳥取",
     807, "FM AICHI", "エフエム愛知",
     807, "FM Tokushima", "エフエム徳島",
     807, "NHK-FM Tokushima", "NHK-FM 徳島",
     813, "J-WAVE", "ジェイウェーブ",
     814, "NHK-FM Kanagawa", "NHK-FM 神奈川",
     815, "FM Kochi", "エフエム高知",
     815, "NHK-FM Kochi", "NHK-FM 高知",
     818, "Fukushima FM", "ふくしまFM",
     819, "NHK-FM Fukushima", "NHK-FM 福島",
     825, "NHK-FM Tokyo", "NHK-FM 東京",
     825, "FM NORTH WAVE", "エフエム・ノースウェーブ",
     827, "FM Toyama", "エフエムとやま",
     828, "FM Akita", "エフエム秋田",
     830, "FM FUJI", "エフエム富士",
     831, "NHK-FM Hokkaido", "NHK-FM 北海道",
     832, "FM Miyazaki", "エフエム宮崎",
     833, "NHK-FM Miyazaki", "NHK-FM 宮崎",
     847, "FM Yokohama", "エフエムヨコハマ",
     851, "FM OSAKA", "エフエム大阪",
     852, "NHK-FM Sapporo", "NHK-FM 札幌",
     873, "FM Okinawa", "エフエム沖縄",
     874, "NHK-FM Okinawa", "NHK-FM 沖縄",
     894, "FM Kyoto", "エフエム京都",
     897, "InterFM897", "インターエフエム",
     902, "KNB Radio", "北日本放送",
     905, "TBS Radio", "TBSラジオ",
     909, "YBS Radio", "山梨放送",
     916, "Bunka Hoso", "文化放送",
     922, "SBC Radio", "信越放送",
     924, "Radio Nippon", "ラジオ日本",
     927, "BSN Radio", "新潟放送",
     930, "Nippon Broadcasting", "ニッポン放送",
     940, "MRO Radio", "北陸放送",
     941, "Tochigi Broadcasting", "栃木放送",
     946, "LuckyFM Ibaraki", "LuckyFM茨城放送",
     946, "FBC Radio", "福井放送",
     0,   "Unknown","不明"
