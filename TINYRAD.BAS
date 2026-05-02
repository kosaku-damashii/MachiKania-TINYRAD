REM ===================================
REM  TINYRAD.BAS
REM  for RDA5807M FM Radio Tuner
REM  on MachiKania type P/PU
REM ===================================

USEVAR REG,HI,LO,VOL

REM I2C 7bit slave addresses
A = $10
B = $11

REM RDA registers 0x02..0x07 (32bit)
DIM R(5)

REM initialize register values
REM BAND:76-108 MhZ
REM SPACE:100 kHz
R(0) = $0000D005
R(1) = $00000008
R(2) = $00000A00
R(3) = $00008880
R(4) = 0
R(5) = 0


REM Volume (0-15)
V = 1

K = 0

I2C 100

CLS
PRINT "TinyRadio"
PRINT "START=Seek  UP/DOWN=Vol"

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
  I2CWRITE B,2+REG,HI,LO
  PRINT "[0";2+REG;"] ";HEX$(HI,2);HEX$(LO,2)
  RETURN 0

REM --------------------------------
REM write all registers 0x02-0x07
LABEL WRITEALL
  cls
  GOSUB(WRITEREG,0)
  GOSUB(WRITEREG,1)
  GOSUB(WRITEREG,2)
  GOSUB(WRITEREG,3)
  GOSUB(WRITEREG,4)
  GOSUB(WRITEREG,5)
  PRINT
  RETURN 0

REM --------------------------------
REM set volume
LABEL SETVOL
  VAR VOL
  VOL = ARGS(1)
  R(3) = (R(3) AND $FFFFFFF0) OR VOL
  GOSUB(WRITEREG,3)
  PRINT
  RETURN VOL

REM --------------------------------
REM seek up
LABEL SEEKUP
  R(0) = R(0) OR $00000300
  GOSUB(WRITEREG,0)
  PRINT
  RETURN 0

REM --------------------------------
REM RDA init
LABEL RDAINIT
  R(0) = R(0) OR $00000002
  GOSUB(WRITEALL)
  R(0) = R(0) AND $FFFFFFFD
  GOSUB(WRITEREG,0)
  PRINT
  RETURN 0
