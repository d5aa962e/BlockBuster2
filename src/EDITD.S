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
*        File: EDITD.S         *
*                              *
*           Contents           *
*           --------           *
*                              *
* - OS Independent "block"     *
*   read/write routines        *
* - Undo Logic                 *
* - Enter Block #              *
* - Makefile logic             *
* - Edit-mode UDLR             *
* - Follow File                *
* - Next/Prev Block Read       *
*                              *
********************************

BAKBLK   JSR   DECRBLK
         JSR   PRBLKNUM
         JMP   EGETKY

BAKBLK2  LDA   OSTYPE
         CMP   #1
         BEQ   :DOS
         CMP   #2
         BEQ   :MEM
         CMP   #4
         BEQ   :CPM
         DEC   BLOCK+1    ;ProDOS & Pascal
:1       JSR   PRBLKNUM
         JMP   EGETKY
:DOS     DEC   TRACK
         JMP   :1
:MEM     DEC   RAMWORKSBANK
         JMP   :1
:CPM     DEC   BIGBLOCK+1
         JMP   :1

DECRBLK  LDA   OSTYPE
         CMP   #1
         BEQ   :DOS
         CMP   #2
         BEQ   :MEM
         CMP   #3
         BEQ   :PAS
         CMP   #4
         BEQ   :CPM
:PD      LDA   BLOCK      ;Go back a block w/o reading
         ORA   BLOCK+1    ;Only if not at block 0
         BNE   :1
         CLC
         RTS
:DOS     LDA   TRACK
         ORA   SECTOR
         BEQ   :E
         DEC   SECTOR
         LDA   SECTOR
         CMP   #$FF
         BNE   :E
         DEC   TRACK
         LDA   #$F

* LDA FIAUX+1 ;For later of > 15 sectors/track

         STA   SECTOR
         JMP   :E
:MEM     DEC   MEMPAGE+1
         LDA   MEMPAGE+1
         CMP   #$FF
         BNE   :E
         DEC   RAMWORKSBANK
:E       RTS
:CPM     LDA   BIGBLOCK
         ORA   BIGBLOCK+1
         BEQ   :E
         LDA   BIGBLOCK
         SEC
         SBC   #1
         STA   BIGBLOCK
         BCS   :E
         DEC   BIGBLOCK+1
         JMP   :E
:PAS
:1       LDA   BLOCK
         BNE   :2
         DEC   BLOCK+1
:2       DEC   BLOCK
         LDA FILFLG
         BPL   :4         ;Doing a file
         RTS
:4       JSR   SETFILPOSN
         BCC   :5
:5       RTS

RDNXTBLK
         LDA   #0
         STA   EOFLAG
         JSR   INCRBLK
         BCS   :5
         JSR   :READIT
         PHA
         PHP
         JSR   PRBLKNUM
         PLP
         PLA
         BCS   :E
         JMP   DOSCRN
:5       LDA   EOFLAG
         BEQ   :K
:E       JSR   EDITERR
:K       JMP   EGETKY

:READNEXT LDA OSTYPE
         BEQ   :1
         CMP   #2
         BEQ   :MEM
         CMP   #3
         BEQ   :1
         CMP   #4
         BEQ   :CPM
         INC   SECTOR
         LDA   SECTOR
         AND   #$F
         STA   SECTOR
         BNE   :READIT
         INC   TRACK
         BNE   :READIT
:MEM     INC   MEMPAGE+1
         BNE   :2
         INC   RAMWORKSBANK
:2       JMP   :READIT
:1       INC   BLOCK
         BNE   :READIT
         INC   BLOCK+1
         BNE   :READIT
:CPM     INCW  BIGBLOCK

:READIT  JSR   BLKREAD
         PHA
         PHP
         JSR   BAKUP
         JSR   ClrDirty
         PLP
         PLA
         BCC   :3
                          ; CMP #$4C ;End of file
                          ; BNE :3
         JSR   EDITERR
         JSR   DECRBLK
         CLC
:3       RTS

BLKRD    JSR   PRBLKNUM
         JSR   BLKREAD
         BCS   :1
         JSR   BAKUP
         JSR   ClrDirty
         JMP   DOSCRN
:1       JSR   EDITERR
         JMP   EGETKY

*
* OPSYS independent block read subroutine
* Reads block, sector, page, or big block to BLKBUF
*

BLKREAD  LDA   OSTYPE
         BEQ   :BLKRD     ;ProDOS
         CMP   #3         ;Pascal
         BEQ   :BLKRD
         CMP   #1         ;DOS 3.3
         BEQ   :SECTRD
         CMP   #2
         BNE   :BIGBLK
         JMP   MEMRD
:BIGBLK  JSR   RDBBLK
         RTS
:BLKRD   LDA   FILFLG
         BPL   :2         ;Following a file
         RDBLK
         BCS   :ERR
         LDA   OSTYPE
         CMP   #3
         BNE   :1
         LDA   BLOCK+1
         BNE   :1
         LDA   BLOCK
         CMP   #3
         BEQ   :0
         CMP   #4
         BNE   :4
:0       DEC   BLOCK
         DEC   RWBUF+1
         DEC   RWBUF+1
         RDBLK
         BCS   :ERR
         INC   BLOCK
         INC   RWBUF+1
         INC   RWBUF+1
         BCS   :ERR
:1       RTS
:2       LDA   FOLLOWREF
         STA   MARKREF
         STA   READREF
         JSR   SETFILPOSN
         BCS   :ERR
:3       MLI   READ;PREAD
         BCS   :ERR
         JSR   NEXTFIL1
:4       CLC
:ERR     RTS
:SECTRD  JSR   RDSECT
         RTS
MEMRD    LDA   MyMachId
         CMP   #12
         BCC   OLDMEM     ;Not at least a GS
         JMP   GSREAD     ;Read 16 bit memory
OLDMEM   LDX   #0
         LDA   RWBUF+1
         STA   :ZP3+2
         STA   :M3+2
         LDA   MEMPAGE+1
         CMP   #2
         BCC   :ZP
         CMP   #$C0
         BCC   :MAIN48

* Map $C000-$CFFF to $D000-$DFFF in Bank 0.
* We'll have to figure out a way to read
* $C100-$C7FF, as well as the slot-specific
* $C8 ROMs, without messing things up.
* Obvioiusly we can't read and write $C0xx
* willy-nilly, but maybe there's a way
* to read at least some of those values.
* TBD!

         STA   $C083      ;Assume D0 bank 0
         STA   $C083
         CMP   #$D0
         BCS   :ZP
         ADC   #$10
         STA   $C08B      ;D0 bank 1
         STA   $C08B
:ZP      STA   :ZP2+2
         LDY   RAMWORKSBANK
         BEQ   :ZP2
         DEY
         STY   $C073
:ZPRD    LDA   PAGE2
         PHA
         LDA   STORE80
         PHA
         STA   PAGE2OFF
         STA   STORE80OFF
         STA   ALTZPON
:ZP2     LDA   $FF00,X    ;Dummy location for now
:ZP3     STA   BLKBUF,X
         INX
         BNE   :ZP2
         STA   $C082      ;Enable motherboard ROM's
         STA   ALTZPOFF
         LDY   RAMWORKSBANK
         BEQ   :EXIT
         STA   STORE80ON
         STA   PAGE2ON
         STX   $C073
         PLA
         BMI   :E2
         STA   STORE80OFF
:E2      PLA
         BMI   :EXIT
         STA   PAGE2OFF
         BPL   :EXIT      ;Always
:MAIN48  STA   :M48+2
         LDY   RAMWORKSBANK
         BEQ   :M48
         DEY
         STY   $C073
         LDA   :M48+2
         STA   A1H
         STA   A2H
         STX   A1L
         DEX
         STX   A2L
         POINT A4L;BLKBUF
         CLC
         STA   STORE80OFF
         JSR   AUXMOVE
         STA   STORE80ON
         JMP   :EXIT
:M48     LDA   $FF00,X    ;Filled in later
:M3      STA   BLKBUF,X
         INX
         BNE   :M48
:EXIT    LDA   #0
         STA   $C073
         CLC
         RTS

GSREAD   LDA   RAMWORKSBANK
         BEQ   :0         ;Main RAM
         CMP   #1         ;and first bank of AUX ram
         BNE   :1
:0       JMP   OLDMEM     ;handled like a //e
:1       LDA   RWBUF+1
         STA   :Dest+2
         LDA   MEMPAGE+1
         STA   :Src+2
         LDA   RAMWORKSBANK
         STA   :Bank+2

*
* This code simulates some 16-bit opcodes
* so that Merlin doesn't have to look them up.
* e.g. faster compiles.
*

         CLC
         HEX   FB         ;XCE
         HEX   C230       ;REP #30
         HEX   A9FF00     ;LDA #$00FF
:Src     HEX   A20000     ;LDX #$0000
:Dest    HEX   A00000     ;LDY #$0000
:Bank    HEX   540000     ;MVN Src,Dest
         HEX   E230       ;SEP #30
         SEC
         HEX   FB         ;XCE
         CLC
         RTS

NEXTFIL1 JSR   PRBLKNUM
         LDA   READACT
         STA   LASTRDLEN
         LDA   READACT+1
         STA   LASTRDLEN+1
         CMP   #2
         BEQ   :5
         LDA   #0
         LDY   READACT
         LDX   READACT+1
         CPX   #1
         BEQ   :4
:3       STA   BLKBUF,Y
         INY
         BNE   :3
:4       STA   BLKBUF+$100,Y
         INY
         BNE   :4
:5       RTS

BAKUP    LDY   #0
:1       LDA   BLKBUF,Y
         STA   BLKBUF+$400,Y
         LDA   BLKBUF+$100,Y
         STA   BLKBUF+$500,Y
         LDA   BLKBUF+$200,Y
         STA   BLKBUF+$600,Y
         LDA   BLKBUF+$300,Y
         STA   BLKBUF+$700,Y
         INY
         BNE   :1
         RTS

UNDO     JSR   SAVCURLOC
         JSR   CLEAR23
         JMP   :Edits

* Take out the Undo Writes for initial release

         PRINT UNDOTXT
         POINT CHPTR;UNDW
         LDX   #1
         JSR   CHOOSE
         BNE   :2
         JSR   CLEAR23
         JSR   RESTCLOC
         JMP   EGETKY
:2       CMP   #2
         BEQ   :Writes
:Edits   JSR   MISTAK
         JSR   CLEAR23
         JSR   RESTCLOC
         JSR   ClrDirty
         JMP   DOSCRN
:Cant    JSR   CLEAR23
         PRINT NOUNDOS
         JSR   RESTCLOC
         JSR   KBDEDIT
         JMP   EGETKY

:Writes  LDA   WRDEV
         BEQ   :Cant      ;No undo to undo
         STA   UNITNUM
         LDY   #0
:3       LDA   UNDOWR,Y
         STA   BLKBUF,Y
         LDA   UNDOWR+$100,Y
         STA   BLKBUF+$100,Y
         LDA   UNDOWR+$200,Y
         STA   BLKBUF+$200,Y
         LDA   UNDOWR+$300,Y
         STA   BLKBUF+$300,Y
         INY
         BNE   :3
         LDA   WRMODE
         STA   OSTYPE
         BEQ   :PD
         CMP   #1
         BEQ   :DOS
         CMP   #2
         BEQ   :MEM
         CMP   #3
         BEQ   :PD        ;PASCAL
:CPM     STDB  WRLOC;BIGBLOCK
         JMP   :5
:MEM     LDA   WRLOC
         STA   MEMPAGE+1
         LDA   WRLOC+1
         STA   RAMWORKSBANK
         JMP   :5
:DOS     STDB  WRLOC;TRACK
         JMP   :5
:PD      STDB  WRLOC;BLOCK
:5       JSR   CLEAR23
         PRINT ULR
         LDA   UNITNUM
         JSR   PRUNIT
         JSR   RESTCLOC
         JSR   PRBLKNUM
         STA   STRB
         JSR   KBDEDIT
         PHA
         JSR   SAVCURLOC
         JSR   CLEAR23
         JSR   RESTCLOC
         PLA
         JMP   DOSCRN

WRMODE   DS    1
WRDEV    DS    1
WRLOC    DS    2

ULR      ASZ   "Settings restored from last write."
NOUNDOS  ASZ   "No UNDO to UNDO."

MISTAK   LDY   #0
:1       LDA   BLKBUF+$400,Y
         STA   BLKBUF,Y
         LDA   BLKBUF+$500,Y
         STA   BLKBUF+$100,Y
         LDA   BLKBUF+$600,Y
         STA   BLKBUF+$200,Y
         LDA   BLKBUF+$700,Y
         STA   BLKBUF+$300,Y
         INY
         BNE   :1
         RTS

RIGHT16  LDA   OPFLAG
         BEQ   :1
         LDX   #1
         BNE   RIGHTN
:1       LDX   JMPAMT
RIGHTN   JSR   RIGHT
         DEX
         BNE   RIGHTN
         JMP   EGETKY

LEFT16   LDX   JMPAMT
:1       JSR   LEFT
         DEX
         BNE   :1
         JMP   EGETKY

ZEROBUF  PUSH  PTR        ;Zero buffer
         CTX   HLPaaZ
         JSR   SAVCURLOC
:ZV      GOTO  0;23
         JSR   CLREOL
         PRINT FW         ;Fill with?
         POINT CHPTR;ZV
         LDX   #1
         JSR   CHOOSE     ;Zero / Value
         BNE   :01
         JMP   :E2        ;Escape from choice
:0A      TXA
         CLC
         ADC   :CHSave
         STA   OURCH
         PRINT BadDigit
         JSR   BUZZ
         JSR   WAIT4
         LDA   :CHSave
         STA   OURCH
         JSR   CLREOL
         JMP   :ZV

:01      CMP   #1
         BNE   :0         ;Value
         LDA   #0
         JSR   PRBYT      ;Zero
         LDA   #0
         BEQ   :R         ;Always
:0       PRINT FW2
         LDA   OURCH
         STA   :CHSave
         JSR   ONEBYTE    ;Get the value
         BCC   :R
         BNE   :0A
         BEQ   :ZV
:R       STA   ZVAL
         LDX   #3
         JSR   PRBL2
:RTE     PushCursor
         POINT CHPTR;RTE  ;To end / Range
         JSR   CLREOL
         LDX   #1
         JSR   CHOOSE
         BNE   :11
         PopCursor
         JMP   :ZV
:11      CMP   #1
         BEQ   :TE        ;To end
         PRINT NOB        ;Number of bytes
         JSR   ONEBYTE
         BCC   :R1
         PopCursor
         JSR   CLREOL
         JMP   :RTE
                          ; CLC
:R1      ADC   PTR
         STA   WORKAREA
         LDA   NUM+1
         ADC   PTR+1
         STA   WORKAREA+1
         BNE   :Z
:TE      LDA   #0
         STA   WORKAREA
         LDA   BUFEND
         STA   WORKAREA+1
:Z       LDY   #0
:1       LDA   PTR+1
         CMP   WORKAREA+1
         BNE   :2
         LDA   PTR
         CMP   WORKAREA
         BEQ   :E
:2       LDA   ZVAL
         STA   (PTR),Y
         INC   PTR
         BNE   :1         ;Always
         INC   PTR+1
         BNE   :1         ;Always
:E       PopCursor
:E2      JSR   CLEAR23
         JSR   SetDirty
         JSR   RESTCLOC
         PULL  PTR
         JMP   DOSCRN
:CHSave  DS    1

ONEBYTE  POINT STRPTR;INBUF
         LDA   #0
         STA   GSTRMODE   ;Indicate number input only
         LDX   #9
         JSR   GETSTR
         LDA   INBUF
         BEQ   :3         ;No data, exit
         JSR   ZERONUM
         LDA   INBUF+1
         CMP   #"$"
         BNE   :1
         JSR   IN16
         BCC   :2
:3       SEC
         RTS
:1       JSR   IN10
         BCS   :4
:2       LDA   NUM
:4       RTS

SETBLOCK CTX   HLPaaB
         LDA   OSTYPE
         BNE   :1
:0       JSR   ENTBLKNUM  ;ProDOS & Pascal blocks
         LDA   FILFLG
         BMI   :0A
         JSR   SETFILPOSN
         BCC   :0A
         PHA
         LDA   TEMP
         STA   BLOCK
         LDA   TEMP1
         STA   BLOCK+1
         JSR   PRBLKNUM
         PLA
         JSR   EDITERR
:0A      JMP   EGETKY
:1       CMP   #3
         BEQ   :0         ;Pascal
         CMP   #2
         BEQ   :2         ;Memory
         CMP   #4
         BEQ   :3         ;CP/M
         JSR   BUZZ
         CTX   HLPPDNotes
         JMP   EGETKY
:2       JSR   ENTBLKNUM
         LDA   BLOCK
         STA   MEMPAGE+1
         LDA   BLOCK+1
         STA   RAMWORKSBANK
         JSR   PRBLKNUM
         JMP   EGETKY
:3       JSR   SAVCURLOC
         GOTO  77;4
         STX   NIBSAVX
         STY   NIBSAVY
         LDA   #0
         STA   WORKAREA
         STA   WORKAREA+1
         JSR   GET3NIB2
         BCS   :4         ;Escape hit, restore old block
         LDA   WORKAREA
         STA   BIGBLOCK
         LDA   WORKAREA+1
         AND   #$F
         STA   BIGBLOCK+1
:4       JSR   CLEAR23
         JSR   RESTCLOC
         JSR   PRBLKNUM
         JMP   EGETKY

SETTS    LDA   OSTYPE
         CMP   #1
         BEQ   ENTTSNUM
         JSR   BUZZ
         CTX   HLPPDNotes
         JMP   EGETKY

ENTTSNUM JSR   SAVCURLOC
         CTX   HLPaaT
         LDA   TRACK
         STA   :OldTrk
         LDA   SECTOR
         STA   :OldSec
*
* Track
*

:0       GOTO  74;4
         LDA   TRACK
         JSR   PRBYT
         DEC   OURCH
:1       JSR   MYKEYIN
         CMP   #$8D       ;Return
         BEQ   :5
         CMP   #$9B       ;Escape
         BEQ   :7A        ;Restore old track
         CMP   #"a"
         BCC   :1A
         AND   #$DF
:1A      EOR   #"0"
         CMP   #$A
         BCC   :3
         ADC   #$88
         CMP   #$FA
         BCS   :2         ;Valid
         CTX   HLPEntHx
         JSR   BUZZ
         BEQ   :1
:2       AND   #$F
:3       LDX   #4
:4       ASL   TRACK
         DEX
         BNE   :4
         ORA   TRACK
         STA   TRACK
         JMP   :0
*
* Sector
*

:5       GOTO  79;4
         LDA   SECTOR
         LDY   OURCH
         ORA   #$B0
         CMP   #$BA
         BCC   :5A
         ADC   #6
:5A      JSR   STORCHAR
:6       JSR   MYKEYIN
         CMP   #$8D
         BEQ   :8
         CMP   #$9B
         BNE   :6A
         LDA   :OldSec
         STA   SECTOR
         JMP   :0
:6A      CMP   #"a"
         BCC   :6B
         AND   #$DF
:6B      EOR   #"0"
         CMP   #$A
         BCC   :7         ;Digit
         ADC   #$88
         CMP   #$FA
         BCS   :7         ;Valid
         CTX   HLPEntHx
         JSR   BUZZ
         BEQ   :5
:7       AND   #$F
         STA   SECTOR
         JMP   :5
:7A      LDA   :OldTrk
         STA   TRACK
:8       JSR   RESTCLOC
         JSR   PRBLKNUM
         JMP   EGETKY
:OldTrk  DS    1
:OldSec  DS    1

ENTBLKNUM LDA  #0
         STA   BLOCK
         STA   BLOCK+1
:0A      JSR   SAVCURLOC
         CTX   HLPEntBlkN
         LDA   BLOCK
         STA   TEMP
         LDA   BLOCK+1
         STA   TEMP1
:0       GOTO  76;4
         LDA   BLOCK+1
         JSR   PRBYT
         LDA   BLOCK
         JSR   PRBYT
         LDA   #$88
         JSR   COUT
:1       JSR   MYKEYIN
         CMP   #$8D
         BEQ   :5
         CMP   #"N"
         BEQ   :Num
         CMP   #"n"
         BEQ   :Num
         CMP   #$9B
         BEQ   :4A
         CMP   #"a"
         BCC   :1A
         AND   #$DF       ;Convert to uppercase
:1A      EOR   #"0"
         CMP   #$A
         BCC   :3
         ADC   #$88
         CMP   #$FA
         BCS   :2         ;Valid
:1B      CTX   HLPEntHx
         JSR   BUZZ
         BEQ   :1
:2       AND   #$F
:3       LDX   #4
:4       ASL   BLOCK
         ROL   BLOCK+1
         DEX
         BNE   :4
         ORA   BLOCK
         STA   BLOCK
         JMP   :0
:4A      LDA   TEMP
         STA   BLOCK
         LDA   TEMP1
         STA   BLOCK+1
:5       JSR   CLEAR23
         JSR   RESTCLOC
         JSR   PRBLKNUM
         RTS
:Num     LDA   OAPPLE
         ORA   CAPPLE
         BPL   :1B
         JSR   CvtNum
         BCS   :N2
:N1      STDB  NUM;BLOCK
:N2      JSR   RESTCLOC
         JSR   PRBLKNUM
         JMP   :0A

NEWSLOT  CTX   HLPaaS
         LDA   FILFLG     ;Pos if file active
         BMI   :0         ;No file active
         JSR   BUZZ       ;Can't change slot if file active
         CTX   HLPWhileF
         JMP   EGETKY
:0       JSR   SAVCURLOC  ;Save cursor location
         LDA   UNITNUM
         STA   :SLTSAV
         GOTO  6;0
:1       JSR   MYKEYIN    ;Get keypress
         CMP   #$8D
         BEQ   :2
         CMP   #$9B
         BEQ   :QUIT
         STA   TEMP       ;Save it
         SEC
         SBC   #"0"
         BEQ   :1         ;Slot 0 not valid
         CMP   #8
         BCS   :1         ;Not valid, go back
         ASL              ;OK so make it a
         ASL              ;valid unitnum
         ASL
         ASL
         STA   TEMP1
         LDA   UNITNUM
         AND   #$80       ;Isolate drive
         ORA   TEMP1      ;Merge slot
         STA   UNITNUM    ;New UNITNUM
         LDA   TEMP
         JSR   COUT
:2       JSR   RESTCLOC
         JMP   EGETKY
:QUIT    LDA   :SLTSAV
         STA   UNITNUM
         BNE   :2

:SLTSAV  DS    1

EDIT     LDA   JMPAMT
         STA   AMTSAV     ;Save old jump amount
         LDA   #1
         STA   JMPAMT     ;Jump 1 byte for OA-arrows
EDIT2    CTX   HLPEditKeys
         JSR   PREMODE
         LDA   EMODE      ;What mode?
         BMI   :1
         JMP   EASC
:1       JSR   SAVCURLOC  ;Hex
         LDA   CV
         CLC
         ADC   #11
         JSR   SETCV
         LDY   OURCH
         JSR   PICK
         STA   ESAVE
         JSR   INVERTIT
         JSR   STORCHAR
         JSR   RESTCLOC
         JSR   GETBYTE
         PHP
         PHA
         JSR   SAVCURLOC
         LDA   CV
         CLC
         ADC   #11
         JSR   SETCV
         LDY   OURCH
         LDA   ESAVE
         JSR   INVERTIT
         JSR   STORCHAR
         JSR   RESTCLOC
         PLA
         PLP
         BCS   EXIT
         PHA
         LDY   #0
         STA   (PTR),Y
         JSR   SetDirty
         JSR   SAVCURLOC
         LDA   CV
         CLC
         ADC   #11
         JSR   SETCV
         PLA
EPRNT    PHA

:1       BIT   VIEWFLG
         BMI   :MTEXT
         BVC   :NORM
:INV     PLA
         BMI   :1A
:1B      CMP   #$20
         BCS   :2A
         ORA   #$40
         BNE   :2A        ;Always
:1A      CMP   #$A0
         BCS   :2A
         ORA   #$40
         BNE   :2A        ;Always
:NORM    PLA
         AND   #$7F
         CMP   #$20
         BCS   :2
         LDA   #'.'
:2       ORA   #$80
         BNE   :2A        ;Always
:MTEXT   PLA
         CMP   #$40       ;Mousetext
         BCC   :INV
         CMP   #$60
         BCS   :INV
         PHA
         JSR   MOUSEON
         PLA
:2A      JSR   COUT
         JSR   MOUSEOFF

         JSR   RESTCLOC
         LDA   OPFLAG     ;Don't echo HEX byte if in Opcode mode
         BNE   :3
         JSR   NORMBYTE
:3       JSR   RIGHT
EPRNT1   JSR   PRNTLOC
         JMP   EDIT2
ESAVE    DS    1
EXIT     CMP   #LFTARO
         BEQ   EDLFT
         CMP   #RTARO
         BEQ   EDRT
         CMP   #UPARO
         BEQ   EDUP
         CMP   #DNARO
         BEQ   EDDN
         AND   #%11011111 ;Convert to uppercase
         CMP   #"M"
         BEQ   EMOD
         JSR   SAVCURLOC  ;Quit
         JSR   SAVEWIN
         GOTO  72;18
         LDX   #8
         JSR   PRBL2
         GOTO  72;19
         LDX   #8
         JSR   PRBL2
         JSR   RESTWIN
         JSR   RESTCLOC
         LDA   AMTSAV
         STA   JMPAMT
         JMP   EGETKY

EMOD     LDA   EMODE
         ASL              ;ASCII/Hex in carry
         BCS   :2
         BPL   :1         ;Set/clear in sign
         LDA   #%10000000 ;Switch to hex
         HEX   2C         ;Skip over the others
:1       LDA   #%01000000 ;Switch to ASCII - hi bit set
         HEX   2C         ;Skip
:2       LDA   #0         ;Switch to ASCII - hi bit clear
         STA   EMODE      ;Save new mode
         LDX   OPFLAG
         BEQ   :3
         CMP   #%10000000 ;Doing opcodes, in Hex mode?
         BEQ   EMOD       ;Yes, don't while opcodes active
:3       JSR   RESTCLOC   ;Restore cursor location
         JMP   EDIT2      ;and go get another key

GOEXIT   JMP   EXIT

EDLFT    JSR   LEFT
         JMP   EPRNT1
EDRT     LDA   OURCH
         CMP   #$22
         BNE   :1
         INC   OURCH
         INC   OURCH
:1       JSR   RIGHT
         JMP   EPRNT1
EDUP     JSR   EUP
         JMP   EPRNT1
EDDN     JSR   EDOWN
         JMP   EPRNT1

EASC     LDA   OPFLAG
         BNE   :A
         JSR   INVBYTE
:A       JSR   SAVCURLOC
         LDA   CV
         CLC
         ADC   #11
         JSR   SETCV
         JSR   MYKEYIN
         AND   #$7F
         STA   TEMP
         LDA   OAPPLE
         ORA   CAPPLE
         BPL   :1
         JSR   RESTCLOC
         LDA   OPFLAG
         BNE   :B
         JSR   NORMBYTE
:B       LDA   TEMP
         CMP   #RTARO-$80
         BEQ   EDRT
         CMP   #LFTARO-$80
         BEQ   EDLFT
         CMP   #UPARO-$80
         BEQ   EDUP
         CMP   #DNARO-$80
         BEQ   EDDN
         AND   #%11011111
         CMP   #'Q'       ;Quit Edit Mode
         BEQ   GOEXIT
         CMP   #'M'       ;Switch between ASCII & HEX modes
         BNE   :0
         JMP   EMOD
:0       JSR   BUZZ
         CTX   HLPEditKeys
         JMP   EDIT2

:1       JSR   SetDirty
         LDA   EMODE
         ASL
         ORA   TEMP
         LDY   #0
         STA   (PTR),Y
         JMP   EPRNT

MAKEFILE
         CTX   HLPaaK
         LDA   MAKFLAG
         BEQ   :0A
         CTX   HLPFMAct
         JSR   BUZZ       ;Makefile already active
         JSR   SAVCURLOC
         PRAT  0;23;MakActMsg
         JSR   CLREOL
         JSR   WAIT4
         JSR   CLEAR23
         JSR   RESTCLOC
         JMP   EGETKY
:0A      JSR   SAVCURLOC
         GOTO  0;22
         PRINT FILMOD
         JSR   GETFILNM
         BNE   :1
:0       GOTO  0;22
         JSR   CLREOL
         JSR   RESTCLOC
         JMP   EGETKY
:1       JSR   RESTCLOC
         LDX   INBUF
:L       LDA   INBUF,X    ;Copy name to file name buf
         STA   PNAME2,X
         DEX
         BPL   :L
         LDA   #>PNAME2
         STA   FIPN+1
         STA   CREPN+1
         STA   OPENPN+1
         LDA   #<PNAME2
         STA   FIPN
         STA   CREPN
         STA   OPENPN
         LDA   #6         ;File type=BIN
         STA   CRETYP
         LDA   #$C3       ;Full access
         STA   CRACS
         LDX   #1         ;Seedling (to start!)
         STX   CRESTOR
         INX              ;Fake into overwrite
         STX   TEMP
         MLI   CREATE;PCREATE
         BCC   :4         ;Created OK
         CMP   #$47       ;Duplicate filename
         BEQ   :2
:E       PHA
         LDA   #0
         STA   MAKFLAG
         JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         JSR   RESTCLOC
         PLA
         JSR   EDITERR
         JMP   EGETKY
:2       JSR   SAVCURLOC
         GOTO  0;22
         JSR   PRPNAME2   ;Print file name
         PRINT EXNW       ;... exists, now what?
         POINT CHPTR;AO   ;Append/Overwrite
         LDX   #1
         JSR   CHOOSE
         PHP
         JSR   RESTCLOC
         PLP
         BNE   :2A
         JMP   :0         ;Canceled
:2A      STA   TEMP       ;Save for later
:4       POINT OPENBUF;SECBUF
         MLI   OPEN;POPEN
:4C      BCS   :E         ;Error
         LDA   OPENREF
         STA   MAKEREF
         STA   EOFREF
         STA   MARKREF
         LDA   TEMP
         CMP   #1
         BEQ   :4B        ;Append
         LDX   #2
         LDA   #0
:4A      STA   FIMARK,X
         DEX
         BPL   :4A
         BMI   :3A
:4B      MLI   GETEOF;PGSEOF
         BCS   :4C
         LDX   #2
:3       LDA   FIEOF,X
         STA   FIMARK,X
         DEX
         BPL   :3
:3A      MLI   SETMARK;PGSMARK
         BCS   :4C
:5       LDA   #$FF
         STA   MAKFLAG
         JSR   MAKSTATS   ;Print stats on file
         BCC   :6
         GOTO  0;22
         JSR   CLREOL
         JSR   EDITERR
:6       LDA   #0
         STA   MakeHead
         STA   MakeTail
         LDA   #$FF
         STA   HLPFLG
         JSR   SWAPHLP
         JMP   EGETKY

MAKSTATS JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         PRINT MKG
         JSR   PRPNAME2
         PRINT EA         ;EOF at...
         LDA   MAKEREF
         STA   EOFREF
         STA   MARKREF
         MLI   GETEOF;PGSEOF
         BCS   :3
         LDX   #2
:1       LDA   FIEOF,X
         STA   WORKAREA,X
         DEX
         BPL   :1
         LDX   #2
         JSR   PRHEXDEC
         LDX   #2
         JSR   PRBL2
         PRINT CURP       ;Current position
         MLI   GETMARK;PGSMARK
         BCS   :3
         LDX   #2
:2       LDA   FIMARK,X
         STA   WORKAREA,X
         DEX
         BPL   :2
         LDX   #2
         JSR   PRHEXDEC
         JSR   CLREOL
         JSR   RESTCLOC
         CLC
         RTS
:3       PHA
         JSR   RESTCLOC
         PLA
         SEC
         RTS

PRPNAME2 LDX   #0
:1       LDA   PNAME2+1,X
         ORA   #$80
         JSR   COUT
         INX
         CPX   PNAME2
         BNE   :1
         RTS

MAKEKEY
         CTX   HLPaaK
         LDA   TEMP
         CMP   #$97       ;Ctrl-W
         BNE   :T1
         JMP   :W         ;Write
:T1      CMP   #$82       ;Ctrl-B
         BNE   :T2
         JMP   :B         ;Back
:T2      CMP   #$83       ;Ctrl-C
         BNE   :T4
         JMP   :C         ;Close
:T4      CMP   #$85       ;Ctrl-E
         BNE   :T5
         JMP   :SE        ;Set EOF here
:T5      CMP   #$91       ;Ctrl-Q
         BNE   :T6
         JMP   :QU
:T6      JSR   BUZZ       ;Not valid key
         CTX   HLPInvdKey
         JMP   EGETKY
:E       JSR   EDITERR    ;Oops!
         JMP   EGETKY
:W       JSR   SAVCURLOC
         CTX   HLPaaK
         GOTO  0;22
         JSR   CLREOL
         PRINT WTW        ;What to write
         POINT CHPTR;ALSM ;All/Some/To end
         LDX   #1
         JSR   CHOOSE
         PHP
         PHA
         JSR   RESTCLOC
         PLA
         PLP
         BEQ   :6         ;Canceled
         CMP   #1
         BEQ   :1         ;All
         CMP   #2
         BEQ   :P         ;Some
         JMP   :TEND      ;To end of block
:P       JSR   SAVCURLOC  ;Write only a portion of the block
         GOTO  0;22
         JSR   CLREOL
         CTX   HLPHilite
         JSR   LITECHNK
         PHP
         CTX   HLPaaK
         PLP
         BCC   :6
         JSR   CMPPW
         BCC   :8
         LDA   PTR        ;PTR > PTR2
         SEC              ; and another
         SBC   PTR2
         STA   WRITELEN
         LDA   PTR+1
         SBC   PTR2+1
         STA   WRITELEN+1
         LDA   PTR2
         LDX   PTR2+1
         JMP   :9
:8       LDA   PTR2       ;PTR2 >= PTR
         CLC
         SBC   PTR
         STA   WRITELEN
         LDA   PTR2+1
         SBC   PTR+1
         STA   WRITELEN+1
         LDA   PTR
         LDX   PTR+1
:9       INCW  WRITELEN
:10      JMP   :5
:1       LDA   BUFEND     ;Write entire block
         SEC
         SBC   #>BLKBUF
         STA   WRITELEN+1
         LDA   #0
         STA   WRITELEN
         LDA   #<BLKBUF
         LDX   #>BLKBUF
         JMP   :5
:6       JSR   RESTCLOC
         JSR   MAKSTATS
         JMP   DOSCRN
:TEND    LDA   #0
         SEC
         SBC   PTR
         STA   WRITELEN
         LDA   BUFEND
         SBC   PTR+1
         STA   WRITELEN+1
         LDA   PTR
         LDX   PTR+1
:5       STA   WRITEBUF
         STX   WRITEBUF+1
         LDA   MAKEREF    ;Common routine
         STA   WRITEREF
         MLI   WRITE;PWRITE
         BCC   :7
         JSR   EDITERR
         JMP   DOSCRN
:7       LDA   MakeHead
         CMP   #MkUnCnt
         BCC   :13
         LDX   #0
:14      LDA   MakeWLen+2,X
         STA   MakeWLen,X
         LDA   MakeWLen+3,X
         STA   MakeWLen+1,X
         INX
         INX
         CPX   #MkUnCnt*2
         BNE   :14
         LDA   #MkUnCnt-1
:13      ASL
         TAX
         LDA   WRITEACT
         STA   MakeWLen,X
         LDA   WRITEACT+1
         STA   MakeWLen+1,X
         INC   MakeHead
:11      JMP   :6

:B       LDA   MakeHead
         BNE   :22
         JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         JSR   BUZZ
         PRINT QEmpty
         JSR   ERROR1
         GOTO  0;22
         JSR   CLREOL
         JMP   :6
:22      LDA   MAKEREF
         STA   MARKREF
         MLI   GETMARK;PGSMARK
         BCS   :MError
         LDA   MakeHead
         ASL
         TAX
         LDA   FIMARK
         SEC
         SBC   MakeWLen-2,X
         STA   FIMARK
         LDA   FIMARK+1
         SBC   MakeWLen-1,X
         STA   FIMARK+1
         LDA   FIMARK+2
         SBC   #0
         STA   FIMARK+2
         MLI   SETMARK;PGSMARK
         BCS   :MError
         DEC   MakeHead
         JMP   :6

:MError  JSR   EDITERR
         JMP   EGETKY

:SE                       ;Set EOF here
         LDA   PTR
         SEC
         SBC   #<BLKBUF
         STA   WRITELEN
         LDA   PTR+1
         SBC   #>BLKBUF
         STA   WRITELEN+1
         LDA   #<BLKBUF
         LDX   #>BLKBUF
         JMP   :5

:QU      JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         JSR   BUZZ
         PRINT KillMake
         JSR   YESNO
         PHA
         GOTO  0;22
         JSR   CLREOL
         PLA
         BEQ   :Q1        ;Escape
         CMP   #2         ;Yes
         BEQ   :Q2
:Q1      JMP   :6
:Q2      LDA   MAKEREF
         STA   CLOSEREF
         GOTO  0;22
         JSR   CLREOL
         MLI   CLOSE;PCLOSE
:Q3      BCS   :MError
         POINT DESPN;PNAME2
         MLI   DESTROY;PDESTROY
         BCS   :MError
         JSR   PRPNAME2
         PRINT MakDeld
         JMP   :20A

:C       LDA   MAKEREF
         STA   CLOSEREF
         MLI   CLOSE;PCLOSE
         BCS   :Q3
:20      JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         JSR   PRPNAME2
         PRINT WRTN       ;... written
:20A     LDA   #0         ;Say Makefile not active
         STA   MAKFLAG
:21      JSR   ERROR1
         GOTO  0;22
         JSR   CLREOL
:23      JSR   RESTCLOC
         JSR   SWAPHLP
         JMP   EGETKY

MakeHead DS    1          ;Head ptr
MakeTail DS    1          ;Tail ptr
MakeWLen DS    MkUnCnt*2  ;Room for 10 undos
QEmpty   ASZ   "Undo queue empty"
KillMake ASZ   "This will DELETE the maKefile, is this OK?  "
MakDeld  ASZ   " is deleted"
MakActMsg ASZ  "A makefile is already active"

FOLLOW   CTX   HLPaaF
         LDA   XFOLLOW    ;eXchanged parm was a file
         BNE   :1         ;so can't do another one (for now)
         LDA   FILFLG     ;Check if a file is open
         BMI   FOLLOW2    ;There is an open file
:1       JSR   BUZZ       ;So complain and go
         CTX   HLPFMAct
         JMP   EGETKY     ;back to get another key
GONON    GOTO  0;22
         JSR   CLREOL
         JSR   RESTCLOC
         LDA   MAKFLAG
         BEQ   :1         ;Make not active
         JSR   MAKSTATS
:1       JSR   PRNONE     ;Say no file active
         JMP   EGETKY
FOLLOW2  JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         PRINT FILMOD
         JSR   GETFILNM
         BEQ   GONON      ;If length = 0 then no name
         JSR   RESTCLOC
         LDX   INBUF
:L       LDA   INBUF,X    ;Copy name to file name buf
         STA   PNAME,X
         DEX
         BPL   :L
         POINT OPENBUF;PRIBUF
         LDA   #<PNAME
         STA   FIPN
         STA   OPENPN
         LDA   #>PNAME
         STA   FIPN+1
         STA   OPENPN+1
         LDA   #$A
         STA   PFILINFO
         MLI   GFILINFO;PFILINFO
         BCC   :0
:0A      JMP   GOEDER
:0       POINT OPENBUF;PRIBUF
         MLI   OPEN;POPEN
         BCS   :0A
         POINT READBUF;BLKBUF
         LDA   MAKFLAG
         BNE   :D         ;Make active
         JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         JSR   RESTCLOC
         JMP   :C
:D       JSR   MAKSTATS
:C       LDA   #0
         STA   ENTFLG     ;Force entries off
         LDA   FITYP
         CMP   #$F        ;If we have a directory,
         BNE   :1
         STA   ENTFLG     ;then turn entires on
:1       LDA   OPENREF
         STA   READREF
         STA   WRITEREF
         STA   MARKREF
         STA   EOFREF
         STA   FOLLOWREF
         LDA   #2
         STA   READLEN+1
         LDA   #0
         STA   READLEN
         STA   BLOCK
         STA   BLOCK+1
         STA   FILFLG     ;Specify reading a file
         MLI   READ;PREAD ;Read first chunk of file
         BCS   GOEDER
         LDA   #0
         STA   OSTYPE     ;Select ProDOS mode (Always for now)
         JSR   SETMODE2   ;Update mode on screen
         JSR   PrEButtn
         JSR   PRUNIT
         JSR   NEXTFIL1
         JSR   BAKUP
         JMP   DOSCRN
GOEDER   JSR   EDITERR
         JMP   GONON

GETFILNM CTX   HLPEntFN
         POINT PFXPN;INBUF
         MLI   GETPFX;PPFX
         BCS   GOEDER
         LDX   #0
         LDY   INBUF
         BEQ   :2
:1       LDA   INBUF+1,X
         ORA   #$80
         JSR   COUT
         INX
         DEY
         BNE   :1
:2       LDY   #64
         JSR   MYGETLN1
         RTS

PRNONE   JSR   SAVCURLOC
         GOTO  0;0
         LDX   #29
         JSR   PRBL2
         JSR   RESTCLOC
         LDA   DEVNUM     ;Ok for now
         STA   UNITNUM
         JSR   PRUNIT
         JSR   PRBLKNUM
         LDA   FOLLOWREF
         STA   CLOSEREF
         MLI   CLOSE;PCLOSE
         LDA   #0
         STA   FITYP
         STA   FOLLOWREF
         STA   XFOLLOW
         LDA   ENTFLG
         BEQ   :1         ;Entries off
         JSR   SETJMPAMT  ;Entries on, set jump amount per OS
         RTS
:1       LDA   #$10
         STA   JMPAMT
         RTS
