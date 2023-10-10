***************************************************
*                                                 *
*                Block Buster 2.0                 *
*        The Next Generation Block Editor         *
*                                                 *
*            Originally written in the            *
*               1985-1992 timeframe.              *
*                                                 *
*                 Code Repository                 *
*   https://github.com/d5aa962e/BlockBuster2      *
*                                                 *
*              License: CC BY-SA 4.0              *
*      Creative Commons Attribution-ShareAlike    *
* https://creativecommons.org/licenses/by-sa/4.0  *
*                                                 *
***************************************************

********************************
*                              *
*        File: EDITE.S         *
*                              *
*           Contents           *
*           --------           *
*                              *
* - Scrolling logic            *
* - Print Screen               *
* - Keyboard Get Byte Logic    *
* - eXchange logic             *
* - Convert Hex<->Decimal      *
* - More Program text          *
*                              *
********************************

LEFT     STX   :XSave
         LDA   PTR
         BNE   :1
         LDA   PTR+1
         CMP   #>BLKBUF
         BEQ   :5         ;Already at 1st byte
:1       DEC   PTR        ;else go back one
         LDA   PTR
         CMP   #$FF       ;point to previous page
         BNE   :2
         DEC   PTR+1      ;here
:2       DEC   OURCH      ;Move cursor
         DEC   OURCH
         LDA   OURCH
         CMP   #2         ;If not at left edge then
         BEQ   :4
         CMP   #36        ;check if at center
         BNE   :6
         LDA   #34
         STA   OURCH
:3       RTS
:4       LDA   #68        ;else move to far right
         STA   OURCH
         TXA
         PHA
         JMP   EUP1       ;and move up a line
:5       LDA   Hilitng    ;If hilighting, then
         BNE   :6         ; don't go back a block
         LDA   EOBFlag    ;EOBFlag=1 if we should
         BEQ   :6         ; goto the previous block
         JSR   DECRBLK
         BCS   :6
         JSR   BLKREAD
         BCS   :6
         JSR   BAKUP
         JSR   PRBLKNUM
         LDA   #$FF
         STA   WORKAREA
         LDY   BUFEND
         DEY
         STY   WORKAREA+1
         JSR   MOV2
         CLC
:6       LDX   :XSave
         RTS
:XSave   DS    1

RIGHT    STX   :XSave
         LDA   BUFEND
         CLC
         SBC   PTR+1
         BMI   :6         ;We are at the last byte
         BNE   :1
         LDA   PTR
         CMP   #$FF
         BEQ   :5
:1       INCW  PTR        ;No, so advance to next
:2       INC   OURCH      ;Move cursor
         INC   OURCH
         LDA   OURCH      ;If we're at the middle of
         CMP   #36        ;the screen, then
         BNE   :2A        ;leave two spaces
         INC   OURCH
         INC   OURCH
         LDA   OURCH
:2A      CMP   #70        ;At right edge?
         BNE   :6
:4       LDA   #4         ;Yes, so move to left edge
         STA   OURCH
         LDX   :XSave
         JMP   DOWN1      ;and move down a line
:5       LDA   Hilitng    ;If hilighting, then don't
         BNE   :6         ; increment block number
         LDA   EOBFlag    ;EOBFlag=1 if we should goto
         BEQ   :6         ; the next block
         JSR   INCRBLK
         BCS   :6
         JSR   BLKREAD
         BCS   :6
         JSR   BAKUP
         JSR   PRBLKNUM
         LDA   #0
         STA   WORKAREA
         LDA   #>BLKBUF
         STA   WORKAREA+1
         JSR   MOV2
         CLC
:6       LDX   :XSave
         RTS
:XSave   DS    1

EUP      TXA              ;Save X
         PHA
         LDA   PTR
         CMP   #32
         BCS   :1         ;Can't move up any more
         LDA   PTR+1
         CMP   #>BLKBUF+$100 ;new page.
         BCC   RTS7
:1       LDA   PTR        ;OK, point back 32 bytes
         SEC
         SBC   #$20
         STA   PTR
         BCS   EUP1
         DEC   PTR+1      ;Fix hi byte
EUP1     DEC   CV         ;Up a line
         DEC   OURCV      ;Why both?
         LDA   CV
         CMP   #1         ;At top?
         BEQ   EUP2
         JSR   BASCALC    ;No, move cursor
RTS7     PLA
         TAX              ;Restore X
         RTS
EUP2     LDA   #13        ;Yes, scroll screen up
         STA   WNDTOP
         LDA   #21
         STA   WNDBTM
         JSR   SCROLLDN   ;Scroll ASCII window down
         LDA   #2
         STA   WNDTOP
         LDA   #10
         STA   WNDBTM
         JSR   SCROLLDN   ;and HEX window down
         LDA   OURCH
         PHA              ;Save CH
         GOTO  0;1
         JSR   PRINT32    ;and print 32 bytes at top of screen
         PLA
         STA   OURCH      ;Restore CH
         JMP   RTS7

EDOWN    LDA   BUFEND
         CLC
         SBC   PTR+1
         BMI   DNRTN
         BNE   :2
         LDA   PTR
         CMP   #$E0
         BCS   DNRTN
:2       CLC
         LDA   PTR        ;Advance 32 bytes
         ADC   #$20
         STA   PTR
         BCC   DOWN1
         INC   PTR+1      ;Fix hi byte
DOWN1    LDA   CV         ;Move down a line
         CMP   #$9
         BNE   :2
         LDA   OURCH      ;Yes
         PHA              ;save CH
         JSR   PRINT32    ;print 32 bytes
         PLA              ;and get CH back
         STA   OURCH
         RTS
:2       INC   CV
         INC   OURCV
         JSR   VTAB
DNRTN    RTS

PRNTSCRN JSR   SAVCURLOC
         CTX   HLPaaP
         LDA   PRTRSLOT
         JSR   OUTPORT
         LDX   #0
:P       LDA   PRINIT+1,X
         JSR   COUT
         INX
         CPX   PRINIT
         BNE   :P
         POINT TEMPPTR;BLKBUF
         JSR   CROUT
         JSR   CROUT
         LDX   #35
         JSR   PRBL2
         PRINT TITLE
         JSR   CROUT
         JSR   CROUT
         LDX   #5
         JSR   PRBL2
         LDA   OSTYPE
         CMP   #2
         BNE   :0
         PRINT MPAGE      ;Memory page
         LDA   MEMPAGE+1
         JSR   PRBYT
         PRINT RAMWKSBK
         LDA   RAMWORKSBANK
         JSR   PRBYT
         JMP   :B2
:0       LDA   FILFLG
         BMI   :B         ;No file
         LDX   #4
         JSR   PRBL2
         PRINT PRFB
         LDA   BLOCK+1
         JSR   PRBYT
         LDA   BLOCK
         JSR   PRBYT
         PRINT SOFS       ;space 'of' space
         LDY   INBUF
         LDX   #0
:A       LDA   INBUF,X
         ORA   #$80
         JSR   COUT
         INX
         DEY
         BPL   :A
         JMP   :B2
:B       PRINT UNITTXT
         LDA   UNITNUM
         AND   #$70
         LSR
         LSR
         LSR
         LSR
         ORA   #$B0
         JSR   COUT
         PRINT UNITTXT2
         LDX   #"1"
         LDA   UNITNUM
         BPL   :B1
         INX
:B1      TXA
         JSR   COUT
         LDX   #5
         JSR   PRBL2
         LDA   OSTYPE
         BEQ   :T0
         CMP   #1
         BEQ   :T1
         CMP   #3
         BEQ   :T3
         PRINT OPCpm
         PRINT T4
         JSR   COLNSP3
         LDA   BIGBLOCK
         JSR   PRBYT
         JMP   :B2
:T0      PRINT T0
:T0A     JSR   COLNSP3
         LDA   #"$"
         JSR   COUT
         LDA   BLOCK+1
         JSR   PRBYT
         LDA   BLOCK
         JSR   PRBYT
         JMP   :B2
:T1      PRINT OPDos
         JSR   COLNSP3
         POINT TEMPPTR;TRACK
         JSR   TSLOC
         POINT TEMPPTR;BLKBUF
         JMP   :B2
:T3      PRINT OPPas
         JMP   :T0A
:B2      JSR   CROUT
         JSR   CROUT
:C       LDX   #9
         JSR   PRBL2
         PRINT HIBITS
         PRINT HIBITS
         JSR   CROUT
:1       JSR   KBDEDIT
         CMP   #$9B
         BEQ   :3
         LDX   #5
         JSR   PRBL2
         JSR   PR32HEX
         JSR   CROUT
         LDA   TEMPPTR
         CLC
         ADC   #$20
         STA   TEMPPTR
         BCC   :1
         INC   TEMPPTR+1
         LDA   TEMPPTR+1
         CMP   BUFEND
         BNE   :1
         JSR   CROUT
         JSR   CROUT
         LDX   #9
         JSR   PRBL2
         PRINT HIBITS
         PRINT HIBITS
         POINT TEMPPTR;BLKBUF
:2       JSR   KBDEDIT
         CMP   #$9B
         BEQ   :3
         JSR   CROUT
         LDX   #5
         JSR   PRBL2
         JSR   PR32ASC
         LDA   TEMPPTR
         CLC
         ADC   #$20
         STA   TEMPPTR
         BCC   :2
         INC   TEMPPTR+1
         LDA   TEMPPTR+1
         CMP   BUFEND
         BNE   :2
:3       STA   STRB
         JSR   RESTCLOC
         POINT CSW;$C307  ;80 col warm entry
         JMP   REDRAW

COLNSP3  LDA   #":"
         JSR   COUT
         LDX   #3
         JSR   PRBL2
         RTS

PRFB     ASZ   "Block $"
SOFS     ASZ   " of file "

PRINT32  LDA   PTR        ;move ptr to tempptr for work
         AND   #%11100000
         STA   TEMPPTR
         LDA   PTR+1
         STA   TEMPPTR+1
         LDA   #13
         STA   WNDTOP
         LDA   #21
         STA   WNDBTM
         LDA   OURCV      ;Save HEX CV
         PHA
         CLC
         ADC   #11        ;Move to ASCII
         JSR   SETCV      ;New line
         JSR   CROUT      ;an extra line?
         JSR   PR32ASC
         PLA
         JSR   SETCV      ;Restore CV
         LDA   #2
         STA   WNDTOP     ;Reset window
         LDA   #10
         STA   WNDBTM
         JSR   CROUT
         LDA   OPFLAG
         BNE   :1         ;Yes, do opcodes
         JSR   PR32HEX    ;No, do normal hex display
:1       RTS

PR32ASC  JSR   PRHINIB
         STX   XSAV
:0       LDY   #0
:1       BIT   VIEWFLG
         BMI   :MTEXT
         BVC   :NORM
:INV     LDA   (TEMPPTR),Y
         BMI   :1A
:1B      CMP   #$20
         BCS   :2A
         ORA   #$40
         BNE   :2A        ;Always
:1A      CMP   #$A0
         BCS   :2A
         ORA   #$40
         BNE   :2A        ;Always
:NORM    LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #$20
         BCS   :2
         LDA   #'.'
:2       ORA   #$80
         BNE   :2A        ;Always
:MTEXT   LDA   (TEMPPTR),Y
         CMP   #$40       ;Mousetext
         BCC   :INV
         CMP   #$60
         BCS   :INV
         PHA
         JSR   MOUSEON
         PLA
         JSR   COUT
         JSR   MOUSEOFF
         JMP   :2B
:2A      JSR   BADCHAR
         JSR   COUT
:2B      LDA   #$A0
         JSR   COUT
         INY
         CPY   #$10
         BEQ   :3
         CPY   #$20
         BNE   :1
         LDX   XSAV
         RTS
:3       LDA   #$A0
         JSR   COUT
         JSR   COUT
         JMP   :1

PR32HEX  JSR   PRHINIB
         LDY   #0
:1       LDA   (TEMPPTR),Y
         JSR   PRBYT
         INY
         CPY   #$10
         BEQ   :2
         CPY   #$20
         BNE   :1
         RTS
:2       LDA   #$A0
         JSR   COUT
         JSR   COUT
         JMP   :1

PRHINIB  LDA   TEMPPTR+1  ;Print the hi two nibbles
         SEC
         SBC   #>BLKBUF
         ASL              ;of the location.
         ASL
         ASL
         ASL
         STA   TEMP1
         LDA   TEMPPTR
         LSR
         LSR
         LSR
         LSR
         AND   #%00001110
         ORA   TEMP1
         JSR   PRBYT
         LDA   #$A0
         JSR   COUT
         JSR   COUT
         RTS

BADCHAR  STX   TEMP
         LDX   CSW+1
         CPX   #$C1
         BNE   :1
         LDX   TEMP
         CMP   #$FF
         BNE   :1
         LDA   #"_"
:1       LDX   TEMP
         RTS

GETBYTE  JSR   MYKEYIN
         STA   TEMP3
         JSR   EXITCHK
         BCC   :0
         RTS
:0       JSR   ECHEK
         BCS   GETBYTE
         ASL
         ASL
         ASL
         ASL
         STA   TEMP4
:1       JSR   MYKEYIN
         STA   TEMP3
         JSR   EXITCHK
         BCC   :3
:2       DEC   OURCH
         RTS
:3       JSR   ECHEK
         BCS   :2
         ORA   TEMP4
         STA   TEMP4
         DEC   OURCH
         DEC   OURCH
         RTS

ECHEK    CMP   #$E0
         BCC   :0
         AND   #%11011111 ;convert to upper case
:0       EOR   #"0"
         CMP   #$A
         BCC   :1
         ADC   #$88
         CMP   #$FA
         BCC   :2
         AND   #$F
:1       PHA
         LDA   TEMP3
         JSR   COUT
         PLA
         CLC
         RTS
:2       JSR   BUZZ
         CTX   HLPEntHx
         SEC
         RTS

EXITCHK  LDX   OAPPLE
         BMI   :1
         LDX   CAPPLE
         BMI   :1
         CLC
         RTS
:1       LDX   EXTNUM
:2       CMP   EXTCHRS,X
         BEQ   :3
         DEX
         BPL   :2
:3       SEC
         RTS

EXTCHRS  DFB   LFTARO,RTARO,UPARO,DNARO
         ASC   "QqMmHh"
EXTNUM   DFB   *-EXTCHRS-1

INVBYTE  JSR   SETINV     ;Make this byte inverse
         LDY   #0
         LDA   (PTR),Y
         JSR   PRBYT
         DEC   OURCH      ;and move cursor back where it was
         DEC   OURCH
         JSR   SETNORM    ;Normal mode
         RTS

NORMBYTE JSR   SETNORM    ;Does the reverse of INVBYTE
         LDY   #0
         LDA   (PTR),Y
         JSR   PRBYT
         DEC   OURCH      ;Leave cursor alone
         DEC   OURCH
         RTS

OPTS     GOTO  0;1
         LDX   #80
         LDA   #"-"
:1       JSR   COUT
         DEX
         BNE   :1
         GOTO  0;21
         LDX   #80
         LDA   #"-"
:2       JSR   COUT
         DEX
         BNE   :2
         PRAT  4;11;HIBITS
         PRINT HIBITS
         GOTO  68;0
         JSR   MOUSEON
         LDA   #"A"
         JSR   COUT
         JSR   MOUSEOFF
         PRINT AHLPTXT
         GOTO  74;2
         LDA   #72
         STA   WNDLFT
         BIT   IDBYTE
         BNE   :4
         PRINT OLDPARMS   ;Machine is non-enhanced //e
         JMP   :5
:4       JSR   MOUSEON
         LDA   #"A"
         JSR   COUT
         JSR   MOUSEOFF
         PRINT PARMSO
         JSR   MOUSEON
         LDA   #"@"
         JSR   COUT
         JSR   MOUSEOFF
:5       PRINT PARMS
         LDA   #0
         STA   WNDLFT
         JSR   PRNTLOC    ;Byte location
         JSR   SETMODE2
         JSR   PRBLKNUM   ;Block number
         LDA   #80
         STA   WNDWDTH
         JSR   SWAPHLP
         RTS

T0       ASC   "ProDOS b"0700
                          ;T3 ASC "Pascal b"0700
T4       ASC   " Big B"0700
T4A      ASZ   "(s)"

PRXFOLLOW JSR  SAVCURLOC
         GOTO  75;20
         LDX   XFOLLOW
         BNE   :10
         LDA   #$A0
         BNE   :11        ;Always
:10      LDA   #"F"
:11      JSR   COUT
         JSR   RESTCLOC
         RTS

XCHANGE  CTX   HLPaaX
         LDA   DirtyBit
         LDX   XDIRT
         STX   DirtyBit
         STA   XDIRT
         LDA   UNITNUM
         LDX   XUNITNUM
         STX   UNITNUM
         STA   XUNITNUM

         LDA   #$A0       ;Assume swapped was not
         STA   FILFLG     ;a file
         LDA   FOLLOWREF
         LDX   XFOLLOW
         STX   FOLLOWREF
         STA   XFOLLOW
         BEQ   :10        ;From last LDX
         STX   FILFLG     ;Swapped was a file
:10      JSR   PRXFOLLOW
         PUSH  PTR        ;Save pointer on stack
         STDB  XPTR;WORKAREA
         PULL  XPTR       ;Retreive current pointer
         LDA   OSTYPE     ;Get OS
         PHA
         LDA   XMODE      ;Swap exchanged OS
         STA   OSTYPE     ;Make it the new one
         PLA
         STA   XMODE      ;Original mode into exchange mode
         CMP   #1         ;Original mode was DOS
         BEQ   :TS1
         CMP   #2         ;Original mode was Memory
         BEQ   :MEM1
         CMP   #4         ;Original mode was CP/M
         BEQ   :CPM1
         PUSH  BLOCK      ;Else original was ProDOS, Pascal
         JMP   :1
:TS1     LDA   TRACK      ;Push track & sector onto stack
         PHA
         LDA   SECTOR
         PHA
         JMP   :1         ;Always
:CPM1    PUSH  BIGBLOCK
         JMP   :1
:MEM1    LDA   RAMWORKSBANK
         PHA
         LDA   MEMPAGE+1
         PHA
:1       LDA   OSTYPE     ;What is new OS?
         CMP   #1         ;DOS
         BEQ   :TS2
         CMP   #2         ;Memory
         BEQ   :MEM2
         CMP   #4         ;CP/M
         BEQ   :CPM2
         STDB  XBLK;BLOCK
:2       PULL  XBLK
         JSR   MOV2
         LDA   UNITNUM
         JSR   PRUNIT
         JSR   SETMODE2
         JSR   PRBLKNUM
         JMP   EGETKY
:TS2     LDA   XBLK
         STA   SECTOR
         LDA   XBLK+1
         STA   TRACK
         JMP   :2         ;Always
:MEM2    LDA   XBLK+1
         STA   RAMWORKSBANK
         LDA   XBLK
         STA   MEMPAGE+1
         JMP   :2
:CPM2    STDB  XBLK;BIGBLOCK
         JMP   :2

XMODE    DS    1          ;AA-X save area
XPTR     DS    2
XBLK     DS    2
XUNITNUM DS    1
XFOLLOW  DS    1
XDIRT    DS    1

FILFLG   DS    1          ;Doing a file or blocks
HLPFLG   DS    1          ;Which help screen is active (BB)
MAKFLAG  DS    1          ;non-zero = making a file
FOLLOWREF DS   1          ;Follow ref #
MAKEREF  DS    1          ;Makefile ref #
JMPAMT   DS    1

CONVNUM  JSR   SAVCURLOC  ;Convert to/from ASCII/bin/hex
:0       JSR   CvtNum
         BCS   :2
:4       JSR   CONV
         LDA   #$A0
         JSR   COUT
         JSR   MYKEYIN
         CMP   #$9B
         BEQ   :2
         CMP   #$8D
         BEQ   :2
         LDA   CvtChSav
         STA   OURCH
         JMP   :0
:2       JSR   CLEAR23
         JSR   RESTCLOC
         JMP   EGETKY

CvtNum   PRAT  0;23;NCONV
         LDA   #0
         STA   GSTRMODE   ;Indicate number input only
         LDA   OURCH
         STA   CvtChSav
:0       CTX   HLPaaN
         JSR   CLREOL
         POINT STRPTR;INBUF
         LDX   #30
         JSR   GETSTR
         CMP   #0
         BNE   :02
         SEC
         RTS
:02      JSR   ZERONUM
         LDA   CvtChSav
         STA   OURCH
         LDA   INBUF+1
         CMP   #"%"
         BNE   :01
         JSR   IN2
         BCS   :3
         BCC   :4
:01      CMP   #"$"
         BNE   :1
         JSR   IN16
         BCS   :3
         BCC   :4
:1       JSR   IN10
         BCC   :4
:3       STX   INBUF
         TXA
         SEC
         ADC   CvtChSav
         STA   OURCH
         PRINT BadDigit
         LDA   #$A0
         JSR   COUT
         JSR   MYKEYIN
         LDA   CvtChSav
         STA   OURCH
         JMP   :0
:4       RTS

CvtChSav DS    1

CONV     JSR   COPYNUM
         LDA   #$A0
         LDX   #48
:1       STA   LNBUF,X
         DEX
         BPL   :1
         LDY   #9
         JSR   HEX2DEC
         LDA   #"$"
         STA   LNBUF+12
         LDY   #18
         JSR   HEX2HEX
         LDY   #46
         JSR   HEX2BIN
         LDX   #0
:2       LDA   LNBUF,X
         JSR   COUT
         INX
         CPX   #47
         BNE   :2
         RTS

IN2      LDX   #1
:1       INX
         LDA   INBUF,X
         CMP   #$8D
         BEQ   :1A
         CMP   #"0"
         BEQ   :2
         CMP   #"1"
         BEQ   :2
         CMP   #$A0
         BEQ   :1
         SEC
         RTS
:2       EOR   #$B0
         ASL   NUM
         ROL   NUM+1
         ROL   NUM+2
         ROL   NUM+3
         ORA   NUM
         STA   NUM
         JMP   :1
:1A      CLC
         RTS

IN10     LDX   #0
:1       INX
         LDA   INBUF,X
         CMP   #$8D
         BEQ   :1A
         JSR   IsDecDigit
         BCC   :2
         RTS
:2       AND   #$F
         STA   TEMP
         JSR   TIMES10
         CLC
         LDA   NUM
         ADC   TEMP
         STA   NUM
         LDA   NUM+1
         ADC   #0
         STA   NUM+1
         LDA   NUM+2
         ADC   #0
         STA   NUM+2
         LDA   NUM+3
         ADC   #0
         STA   NUM+3
         JMP   :1
:1A      CLC
         RTS

IsHexDigit                ;BCC=Yes  BCS=No
         CMP   #$A0
         BEQ   :1
         JSR   ToUpper
         CMP   #"A"
         BCC   IsDecDigit
         CMP   #"F"+1
         BCS   IsDecDigit
         SBC   #"6"
         CLC
:1       RTS

IsDecDigit
         CMP   #"0"
         BCS   :1
         SEC
         RTS
:1       CMP   #"9"+1
         BCS   :2
         EOR   #"0"
:2       RTS

         NOP
         NOP

ToUpper  CMP   #"a"
         BCC   :1
         CMP   #"z"+1
         BCS   :1
         AND   #$DF
:1       RTS

IN16     LDX   #1
:0       INX
         LDA   INBUF,X
         CMP   #$8D
         BNE   :0A
         CLC
:8       RTS
:0A      JSR   IsHexDigit
         BCS   :8
         LDY   #3
:1A      ASL   NUM
         ROL   NUM+1
         ROL   NUM+2
         DEY
         BPL   :1A
         ORA   NUM
         STA   NUM
         JMP   :0

TIMES10
         LDA   NUM
         ASL
         STA   WORKAREA
         LDA   NUM+1
         ROL
         STA   WORKAREA+1
         LDA   NUM+2
         ROL
         STA   WORKAREA+2
         LDA   NUM+3
         ROL
         STA   WORKAREA+3
         LDY   #3
:2A      ASL   NUM        ;NUM * 8 -> NUM
         ROL   NUM+1
         ROL   NUM+2
         ROL   NUM+3
         DEY
         BNE   :2A
         CLC
         LDY   #0
         PHP
:2       PLP
         LDA   NUM,Y      ;NUM + WORKAREA -> NUM
         ADC   WORKAREA,Y
         STA   NUM,Y
         PHP
         INY
         CPY   #4
         BNE   :2
         PLP
         RTS

PRNTLOC  JSR   SAVCURLOC
         LDA   #80
         STA   WNDWDTH
         GOTO  77;3
         LDA   PTR+1      ;Byte offset into block
         SEC
         SBC   #>BLKBUF
         JSR   PRHEX
         LDA   PTR
         JSR   PRBYT
         GOTO  38;23
         LDA   ENTFLG
         BEQ   LOCCLN
         LDA   OSTYPE
         BEQ   PROLOC     ;ProDOS
         CMP   #1
         BNE   :1
         JMP   DOSLOC     ;DOS 3.3 locations
:1       CMP   #2
         BNE   :2
         JMP   MEMLOC     ;Memory stuff
:2       CMP   #3
         BNE   :3
         JMP   PASLOC     ;Pascal directory
:3       JMP   CPMLOC     ;CP/M locations

LOCCLN   JSR   CLREOL
         JSR   RESTCLOC
         RTS

PROLOC
         LDA   BLOCK+1
         BNE   :10
         LDA   BLOCK
         CMP   #6         ;Bitmap?
         BCC   :10        ;No
         CMP   #6+16
         BCS   :10        ;No
         JMP   PROMAP     ;Do ProDOS bitmap
:10      LDA   PTR+1
         CMP   #>BLKBUF
         BNE   :C
         LDA   PTR
         CMP   #$2B
         BCS   :C
         PHA
         LDA   #0
         STA   PTR
         TAY
         LDA   (PTR),Y
         INY
         ORA   (PTR),Y
         STA   TEMP
         LDY   #4
         LDA   (PTR),Y
         LDX   #3
         AND   #$F0
         PHA
         CMP   #$E0
         BEQ   :S
:V1      LDA   VHDR,X
         STA   DHDR,X
         DEX
         BPL   :V1
         BMI   :V2
:S       LDA   SHDR,X
         STA   DHDR,X
         DEX
         BPL   :S
:V2      PLA
         TAX
         PLA
         STA   PTR
         LDA   TEMP
         BNE   :C
:V3      LDX   PTR
         LDA   VENTOFST,X
         CLC
         ADC   #<VENTDES
         STA   PPARMS
         LDA   #>VENTDES
         ADC   #0
         STA   PPARMS+1
         JSR   TXTCOLN
:F       JSR   HDRVAL
:G       JMP   LOCCLN
:C       LDX   PTR+1
:A       LDA   PTR
         CMP   #4
         BCS   :B
         CPX   #>BLKBUF
         BEQ   :V3
:B       SEC
         SBC   #4
         BCS   :0
         DEX
:0       CPX   #>BLKBUF
         BEQ   :1         ;Always
         CMP   #$FB
         BEQ   :5
:1       CMP   #$27
         BCS   :2
         CPX   #>BLKBUF
         BEQ   :3
         SEC
:2       SBC   #$27
         BCS   :1
         DEX
         BNE   :1         ;Always
:3       TAX
         LDA   ENTOFST,X
         CLC
         ADC   #<ENTDES
         STA   PPARMS
         LDA   #>ENTDES
         ADC   #0
         STA   PPARMS+1
         JSR   TXTCOLN
         JSR   PRNTVAL
:5       JMP   LOCCLN

HDRVAL   POINT TEMPPTR;BLKBUF
         LDY   PTR
         LDX   #1
         CPY   #2
         BCS   :0
         LDY   #0
         BEQ   :6A
:0       CPY   #4
         BEQ   :0A
         BCS   :1
         LDY   #2
         BNE   :6A
:0A      LDA   (TEMPPTR),Y
         LSR
         LSR
         LSR
         LSR
         JSR   PRNTSTOR
         RTS
:1       CPY   #$14
         BCS   :4
         LDY   #$4
         LDA   (TEMPPTR),Y
         AND   #$F
         TAX
:2       INY
         LDA   (TEMPPTR),Y
         JSR   PRABLE     ;Make char printable
         BEQ   :3A
         JSR   COUT
         DEX
         BNE   :2
         RTS
:3A      PRINT EMPTY
         RTS
:4       CPY   #$1C
         BCS   :5
         PRINT RSVD8
         RTS
:5       CPY   #$20
         BCS   :6
         LDY   #$1C
:DODATE  JMP   PRNTDTTM
:6       LDX   #0
         CPY   #$20
         BNE   :7
:6A      JMP   GODO
:7       CPY   #$21
         BEQ   :6A
         CPY   #$22
         BNE   :8
         LDA   (TEMPPTR),Y
         JMP   PRINTACS
:8       CPY   #$23
         BEQ   :6A
         CPY   #$24
         BEQ   :6A
         LDX   #1
         CPY   #$27
         BCS   :9
         LDY   #$25
         BNE   :13        ;Always
:9       CPY   #$29
         BCS   :10
         LDY   #$27
         BNE   :13        ;Always
:10      TYA
         PHA
         LDY   #$4
         LDA   (TEMPPTR),Y
         TAX
         PLA
         TAY
         TXA
         AND   #$F0
         CMP   #$F0
         BEQ   :11        ;Volume header
         LDX   #0         ;Subdirectory header
         BEQ   :13        ;Always
:11      LDX   #1
         LDY   #$29
:13      JMP   GODO

PRNTVAL  LDA   PTR
         SEC
         SBC   #4
         STA   TEMP
         LDA   PTR+1
         SBC   #>BLKBUF
         LDX   #8
:1       ASL   TEMP
         ROL
         CMP   #$27
         BCC   :2
         SBC   #$27
         INC   TEMP
:2       DEX
         BNE   :1
         STA   TEMP3
         LDA   TEMP
         STA   MPYR
         LDA   #0
         STA   TEMPPTR+1
         LDX   #8
:3       ASL
         ROL   TEMPPTR+1
         ASL   MPYR
         BCC   :4
         CLC
         ADC   #$27
         BCC   :4
         INC   TEMPPTR+1
:4       DEX
         BNE   :3
         CLC
         ADC   #4
         STA   TEMPPTR
         LDA   TEMPPTR+1
         ADC   RWBUF+1
         STA   TEMPPTR+1
         LDA   TEMP3
         LDX   #1
         CMP   #$25
         BCC   :6
         LDY   #$25
         BNE   :DO
:6       CMP   #$21
         BCC   :7
         LDY   #$21
         BNE   :DODATE
:7       CMP   #$1F
         BCC   :8
         LDY   #$1F
         BNE   :DO
:8       CMP   #$1E
         BNE   :9
         TAY
         LDA   (TEMPPTR),Y
         JMP   :DOACS
:9       DEX
         TAY
         CMP   #$1D
         BEQ   :DO
         CMP   #$1C
         BEQ   :DO
         CMP   #$18
         BCC   :10
         LDY   #$18
:DODATE  JMP   PRNTDTTM
:DO      JMP   GODO
:DOACS   JMP   PRINTACS
:DOTYP   LDA   (TEMPPTR),Y
         JMP   PRINTTYP
:10      INX
         CMP   #$15
         BCC   :11
         LDY   #$15
         INX
         BNE   :DO
:11      CMP   #$13
         BCC   :12
         LDY   #$13
         BNE   :DO
:12      CMP   #$11
         BCC   :13
         LDY   #$11
         BNE   :DO
:13      CMP   #$10
         BNE   :14
         TAY
         BNE   :DOTYP
:14      CMP   #0
         BEQ   :16
         LDY   #0
         LDA   (TEMPPTR),Y
         AND   #$F
         BEQ   :20
         TAX
:15      INY
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #' '
         BCS   :15A
         ORA   #$40
:15A     ORA   #$80
         JSR   COUT
         DEX
         BNE   :15
         BEQ   :21
:16      TAY
         LDA   (TEMPPTR),Y
         BEQ   :20
         LSR
         LSR
         LSR
         LSR
         JSR   PRNTSTOR
         RTS
:20      PRINT EMPTY      ;Empty or deleted file entry
:21      RTS

*
* ProDOS bitmap
*

PROMAP
         POINT PPARMS;BF
         JSR   PRTXT2
         LDA   PTR
         STA   TEMPPTR
         LDA   PTR+1
         SEC
         SBC   #>BLKBUF
         STA   TEMPPTR+1
         LDX   #3
:1       ASL   TEMPPTR
         ROL   TEMPPTR+1
         DEX
         BNE   :1
         LDA   BLOCK
         SEC
         SBC   #6
         ASL
         ASL
         ASL
         ASL
         CLC
         ADC   TEMPPTR+1
         TAX
:2       LDA   #"$"
         JSR   COUT
         TXA
                          ; LDA TEMPPTR+1
         JSR   PRBYT
         LDA   TEMPPTR
         JSR   PRBYT
         PRINT PLSP       ;" + "
         LDY   #0
         LDA   (PTR),Y
         BEQ   :5
         STA   TEMPPTR
         LDX   #0
:3       ASL   TEMPPTR
         BCC   :4
         TXA
         ORA   #"0"
         HEX   2C
:4       LDA   #$A0
         JSR   COUT
         INX
         CPX   #8
         BNE   :3
         JMP   LOCCLN
:5       PRINT NONE
         JMP   LOCCLN

PLSP     ASZ   " + "


GODO     STX   TEMP3
         JSR   ZWRKAREA
:2       INX
         LDA   (TEMPPTR),Y
         STA   WORKAREA,X
         CPX   TEMP3
         BEQ   PRHEXDEC
         INY
         BNE   :2
PRHEXDEC LDA   #"$"
         JSR   COUT
:4       LDA   WORKAREA,X
         JSR   PRBYT
         DEX
         BPL   :4
         LDA   #"("
         JSR   COUT
         LDY   #8
         JSR   Conv2Dec
         JSR   DECPRNT
         LDA   #")"
         JSR   COUT
         RTS

ENTDES                    ;Entry descriptions
STTYP    ASZ   "Storage Type"
FNM      ASC   "F"03
         ASZ   "Name"
FT       ASC   "F"03
         ASZ   "Type"
KB       ASC   "Key B"0700 ;Key Block
         DO    ASMEDIT
BIU      ASC   "B"07
         ASZ   "s Used"
         FIN
ENDOFF   ASC   "End of f"0300
CREDT    ASZ   "Created on"
VER      ASC   "V"0900
VER1     ASC   "/"
MVER     ASC   "Min. V"0900
AC       ASZ   "Access"
ATP      ASZ   "Auxiliary Type"
MODDT    ASZ   "Last Modified on"
DHDPTR   ASZ   "Dir header ptr"

PROOFLO  DFB   $04,$2B,$52,$79,$A0,$C7,$EE
         DFB   $15,$3C,$63,$8A,$B1,$D8
PROOFHI  LUP   7
         DFB   >BLKBUF
         --^
         LUP   6
         DFB   >BLKBUF+$100
         --^

ENTOFST  DFB   STTYP-ENTDES ;Entry offsets
         LUP   15
         DFB   FNM-ENTDES
         --^
         DFB   FT-ENTDES,KB-ENTDES,KB-ENTDES,BIU-ENTDES,BIU-ENTDES
         LUP   3
         DFB   ENDOFF-ENTDES
         --^
         LUP   4
         DFB   CREDT-ENTDES
         --^
         DFB   VER-ENTDES,MVER-ENTDES,AC-ENTDES
         DFB   ATP-ENTDES,ATP-ENTDES
         LUP   4
         DFB   MODDT-ENTDES
         --^
         DFB   DHDPTR-ENTDES,DHDPTR-ENTDES

VENTDES                   ;Volume dir entry descriptions
VPREVLNK ASC   "Previous d"01 ;Previous directory block
         ASC   "b"0700
VNEXTLNK ASC   "Next d"01 ;Next directory block
         ASC   "b"0700
VSTTYP   ASZ   "Storage Type"
VFNM     ASC   "F"03
         ASZ   "Name"
VRESRVD  ASZ   "Reserved"
VCREDT   ASZ   "Created on"
VMVER    ASC   "Minimum "
VVER     ASC   "V"0900
VAC      ASZ   "Access"
VENTLEN  ASC   "E"05
         ASZ   "Length"
VENTBLK  ASC   "Entries per b"0700
VFILCNT  ASC   "F"03
         ASZ   "count"
VBMPPTR  ASZ   "Bitmap pointer"
VTOTBLK  ASC   "Total b"07
         ASZ   "s"
VPPTR    HEX   04         ;Parent pointer
         ASZ   "pointer"
VPNUM    HEX   04         ;Parent
         ASC   "e"05
         ASZ   "number"
VPENTLN  HEX   04         ;Parent
         ASC   "e"05
         ASZ   "length"

VENTOFST DFB   VPREVLNK-VENTDES,VPREVLNK-VENTDES
         DFB   VNEXTLNK-VENTDES,VNEXTLNK-VENTDES
         DFB   VSTTYP-VENTDES ;Entry offsets
         LUP   15
         DFB   VFNM-VENTDES
         --^
         LUP   8
         DFB   VRESRVD-VENTDES
         --^
         LUP   4
         DFB   VCREDT-VENTDES
         --^
         DFB   VVER-VENTDES,VMVER-VENTDES,VAC-VENTDES
         DFB   VENTLEN-VENTDES,VENTBLK-VENTDES
         DFB   VFILCNT-VENTDES,VFILCNT-VENTDES
DHDR     DS    4

VHDR     DFB   VBMPPTR-VENTDES,VBMPPTR-VENTDES
         DFB   VTOTBLK-VENTDES,VTOTBLK-VENTDES

SHDR     DFB   VPPTR-VENTDES,VPPTR-VENTDES
         DFB   VPNUM-VENTDES,VPENTLN-VENTDES
