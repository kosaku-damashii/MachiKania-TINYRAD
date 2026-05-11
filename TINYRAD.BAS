REM ===================================
REM  TINYRAD.BAS
REM  for RDA5807M FM Radio Tuner
REM  on MachiKania type P/PU
REM ===================================

USEVAR ADA,ADB,REG,HI,LO,VOL,STC,FREQ,RSSI,ST


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
  CURSOR 0,4
  PRINT "Volume: ";VOL;" "
  RETURN VOL

REM --------------------------------

REM seek up
LABEL SEEKUP
  VAR STC,FREQ,RSSI,ST
  REM RDA registers 0AH-0FH (32bit)
  DIM G((6/2)-1)
  R(0) = R(0) OR $00000300
  GOSUB(WRITEREG,0)
  COLOR 2
  CURSOR 0,3:PRINT "Seek               "
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

  REM Print RSSI level
  RSSI = (PEEK(G+2) AND $FE) >> 1
  CURSOR 0,5:PRINT "Signal: ";RSSI;" "

  REM Print Stereo/Mono
  ST = (PEEK(G) AND $04) >> 2
  CURSOR 0,6
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
