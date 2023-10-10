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
*       File: COMMON.1.S       *
*                              *
*           Contents           *
*           --------           *
*                              *
* - Image ID Logic; VTOC,      *
*   Index Block, T/SL, etc.    *
* - R/W specific OS's disks    *
* - String input ("My GETLN")  *
* - Choice Logic               *
* - Filename parsing           *
*                              *
********************************

PRINTTIME INY
         LDA   (TEMPPTR),Y
         JSR   PRDEC
         LDA   #":"
         JSR   COUT
         DEY
         LDA   (TEMPPTR),Y
         JSR   PRDEC
         DEY
         RTS

PRDATE   PRINT DAT
         LDY   #0
PRINTDATE LDA  (TEMPPTR),Y
         INY
         ORA   (TEMPPTR),Y
         BNE   :1
         PRINT NODATE
         RTS
:1       DEY
         LDA   (TEMPPTR),Y
         AND   #%00011111
         JSR   PRDEC
         LDA   #"-"
         JSR   COUT
         INY
         LDA   (TEMPPTR),Y
         ROR
         DEY
         LDA   (TEMPPTR),Y
         ROR
         LSR
         LSR
         LSR
         LSR
         AND   #$F
         STA   TEMP
         ASL
         CLC
         ADC   TEMP
         TAX
         LDA   MONTHS,X
         JSR   COUT
         LDA   MONTHS+1,X
         JSR   COUT
         LDA   MONTHS+2,X
         JSR   COUT
         LDA   #"-"
         JSR   COUT
         INY
         LDA   (TEMPPTR),Y
         LSR

PRDEC    LDX   #0
:1       CMP   #10
         BCC   :2
         INX
         SBC   #10
         BPL   :1
:2       STA   TEMP
         TXA
         ASL
         ASL
         ASL
         ASL
         ORA   TEMP
         JMP   PRBYT

PRNTDTTM JSR   PRINTDATE
         INY
         LDX   #3
         JSR   PRBL2
         JSR   PRINTTIME
         RTS

PRINTACS PHP
         LDX   #"0"
         STA   TEMP1
         PLP
         BMI   D
         TXA
         HEX   2C
D        LDA   #'D'
         JSR   COUT
         BIT   TEMP1
         BVS   NO1
         TXA
         HEX   2C
NO1      LDA   #'N'
         JSR   COUT
         LDA   TEMP1
         AND   #%00100000
         BNE   B
         TXA
         HEX   2C
B        LDA   #'B'
         JSR   COUT
         TXA
         JSR   COUT
         JSR   COUT
         JSR   COUT
         ROR   TEMP1
         ROR   TEMP1
         PHP
         BCS   W
         TXA
         HEX   2C
W        LDA   #'W'
         JSR   COUT
         PLP
         BMI   R
         TXA
         HEX   2C
R        LDA   #'R'
         JSR   COUT
         RTS

PRINTTYP LDY   #TYPES-FTYPES-1
:2       CMP   FTYPES,Y
         BEQ   :3
         DEY
         BPL   :2
         BMI   :9         ;HEX
:3       TYA
         STA   :T
         ASL
         CLC
         ADC   :T                               ;*3
         TAY
         LDX   #3
:4       LDA   TYPES,Y
         JSR   COUT
         INY
         DEX
         BNE   :4
         RTS
:T       DS    1
:9       PHA
         LDA   #"$"
         JSR   COUT
         PLA
         JSR   PRBYT
         RTS

PRTRSLT  JSR   PRCOMMON
         BNE   :1
         PRINT NONE
:1       RTS

GETSLOT  PHA
         PRINT SLOT       ;Prompt
         PLA
         LSR
         LSR
         LSR
         LSR
         AND   #$7
         ORA   #$B0
         LDY   OURCH
         JSR   STORCHAR
GETSLOT2 JSR   MYKEYIN
         CMP   #$9B       ;If ESC
         BNE   :1         ;then exit
         LDA   #0
         SEC
         RTS
:1       CMP   #$8D
         BNE   :2
         LDY   OURCH
         JSR   PICK
:2       CMP   #$B8       ;Must be < $B8 [ASC("7")+1]
         BCS   GETSLOT2
         STA   TEMP       ;else save for later
         SEC
         SBC   #$B0       ;make it 0-7
         BMI   GETSLOT2   ;<=0
         CMP   #8         ;must be < 8
         BCS   GETSLOT2   ;else get it again
         ASL              ;* 16
         ASL
         ASL
         ASL              ;Put slot in hi nibble
         PHA              ;Slot in X-reg
         LDA   TEMP       ;Get back ASCII value
         JSR   COUT       ;and print it
         PLA
         CLC
         RTS              ;All done

SETPRSLT JSR   SAVCURLOC
         GOTO  40;22
         JSR   PRCOMMON
         JSR   GETSLOT2
         BEQ   :1
         LSR
         LSR
         LSR
         LSR
         STA   PRTRSLOT
:1       GOTO  40;22
         JSR   PRCOMMON
         JSR   RESTCLOC
         RTS

PRCOMMON PRINT PRTRTXT
         LDA   PRTRSLOT
         BEQ   :1
         ORA   #$B0
         JSR   COUT
         LDA   #$88
         JSR   COUT
         LDA   #$FF       ;Make BNE branch
         RTS
:1       PRINT NONE
         RTS

SETCV    STA   CV
         STA   OURCV
         JSR   BASCALC
         RTS

SETCH    STA   CH
         STA   OURCH
         RTS


SCROLLDN
         LDA   WNDTOP
         STA   TopLeftY
         LDX   WNDBTM
         DEX
         STX   BotRtY
         LDA   WNDLFT
         STA   TopLeftX
         CLC
         LDA   WNDWDTH
         STA   BotRtX
         JSR   MYSCDN
         RTS


MYSCDN   LDX   BotRtY
:1       CPX   TopLeftY
         BEQ   :9
         TXA
         ASL
         TAY
         LDA   BASLS,Y
         STA   DESTBASL
         LDA   BASLS+1,Y
         STA   DESTBASL+1
         LDA   BASLS-2,Y
         STA   SRCBASL
         LDA   BASLS-1,Y
         STA   SRCBASL+1
         LDY   TopLeftX
:4       TYA
         PHA
         LSR
         TAY
         LDA   TXTPAGE2
         BCC   :5
         LDA   TXTPAGE1
:5       LDA   (SRCBASL),Y
         STA   (DESTBASL),Y
         LDA   TXTPAGE1
         PLA
         TAY
         INY
         CPY   BotRtX
         BNE   :4
         DEX
         BNE   :1
:9       RTS


OPENMEM  STY   YTEMP
:1       LDY   #0
         LDA   ($3E),Y
         LDY   YTEMP
         STA   ($3E),Y
:2       LDA   $3E
         CMP   $3C
         BNE   :3
         LDA   $3E+1
         CMP   $3C+1
         BEQ   :5
:3       LDA   $3E
         BNE   :4
         DEC   $3E+1
:4       DEC   $3E
         JMP   :1
:5       RTS

*
* ($3C),0 <-- ($3C),Y.($3E)
*

CLOSEMEM STY   YTEMP
:1       LDA   $3C
         CMP   $3E
         BNE   :2
         LDA   $3C+1
         CMP   $3E+1
         BEQ   :3
:2       LDY   YTEMP
         LDA   ($3C),Y
         LDY   #0
         STA   ($3C),Y
         INCW  $3C
         BNE   :1
:3       RTS


*
* Reads Volume Table Of Contents (VTOC)
* into OLBUF
*

RDVTOC   LDA   TRACK      ;Save current track
         PHA
         LDA   SECTOR     ; sector
         PHA
         PUSH  RWBUF      ; and read buffer
         POINT RWBUF;VTOCBUF
         LDA   #$11       ;Set TS to VTOC sector
         STA   TRACK
         LDA   #0
         STA   SECTOR
         JSR   RDSECT     ;Read
         TAX              ;Save possible error code
         PULL  RWBUF      ;Restore buffer
         PLA
         STA   SECTOR     ; track
         PLA
         STA   TRACK      ; sector
         TXA              ; and error code
         RTS

*
* Checks if block could be an index block
* BEQ=index block, BNE=no index block
* Buffer is at TEMPPTR
*

ISIB     STDB  TEMPPTR;TEMP
         INC   TEMP+1     ;Set up hi byte pointer
         LDY   #0
         STY   IBPREV
         STY   IBPREV+1
         STY   IBRELCNT
         STY   NZBLKS
         STY   NZBLKS+1

* First be sure all entries aren't zero.

:1       LDA   (TEMP),Y
         ORA   (TEMPPTR),Y
         BNE   :2
         INY
         BNE   :1
         JMP   :NOPE      ;All zeros is empty block

* Look through each byte pair for a valid block #

:2       LDY   #0
:3       LDA   (TEMPPTR),Y
         ORA   (TEMP),Y
         BNE   :3b        ; Stop checking at 1st non-zero entry
:3a      LDA   (TEMPPTR),Y ;Verify all remaining entries are zero
         ORA   (TEMP),Y
         BNE   :NOPE      ;Not an IB if non-zero entries past last zero
         INY
         BNE   :3a
         LDA   (TEMPPTR),Y ;Save this entry for later
         STA   IBPREV
         JMP   :5
:3b      INC   NZBLKS      ; Increment # of non-zero block found
         BNE   :3c
         INC   NZBLKS+1
:3c      LDA   (TEMPPTR),Y
         CMP   FIAUX
         LDA   (TEMP),Y
         SBC   FIAUX+1
         BCS   :NOPE      ;Entry is > than max blocks
         SEC

* Entries should be mostly ascending.  IBRELCNT keeps
* track of how frequently block numbers increase.  Obviously
* this logic breaks down on fragmented disks, but it does
* result in quite a strong confidence in most cases.

         LDA   (TEMPPTR),Y
         SBC   IBPREV
         BCC   :4
         INC   IBRELCNT
:4       LDA   (TEMPPTR),Y
         STA   IBPREV
         INY
         BNE   :3
:5       LDA   NZBLKS+1
         BNE   :NOPE

* The confidence level is simply the difference between
* the number of index blocks found and the number of times
* the block number increased from entry to entry.  The
* closer to zero IBCONF is, the more confident we are
* that this block is an Index Block.
*
* A final check is made against IBTHRESH, and we
* ignore any found blocks which do not meet this threshold

         SEC
         LDA   NZBLKS
         SBC   IBRELCNT
         STA   IBCONF
         CMP   IBTHRESH
         BCS   :NOPE
         JSR   SAVCURLOC
         PRAT  0;23;IBSTATS
         LDA   IBRELCNT
         JSR   PRBYT
         LDA   #$A0
         JSR   COUT
         LDA   #"/"
         JSR   COUT
         LDA   #$A0
         JSR   COUT
         LDA   IBCONF
         JSR   PRBYT
         JSR   CLREOL
         JSR   RESTCLOC
         LDA   #0
         RTS              ;Yes! We have an index block
:NOPE    LDA   #$FF       ;Sorry, not this one
         RTS

IBPREV   DS    2          ;Previous block #
NZBLKS   DS    2          ;Non-zero block count
IBRELCNT DS    1          ;Block-to-block relationship count
IBCONF   DS    1          ;Confidence this is an Index Block
                          ; closer to zero = more confident
IBSTATS  ASZ   "Count/Conf (0=more confident): "

*
* Checks if this sector is a T/S list
* On exit, BEQ if is TSL
* Buffer is at TEMPPTR
*

ISTSL    LDY   #0
:1       LDA   (TEMPPTR),Y
         BNE   :2         ;Not all zeros
         INY
         BNE   :1
         BEQ   :NO
:2       LDY   #3
:3       LDA   (TEMPPTR),Y
         BNE   :NO
         INY              ;Bytes 5-12 must be zero
         CPY   #12
         BNE   :3
:4       LDA   (TEMPPTR),Y
         CMP   FIAUX      ;Holds max tracks
         BCS   :NO
         INY
         LDA   (TEMPPTR),Y
         CMP   FIAUX+1    ;Sectors per track
         BCS   :NO
         INY
         BNE   :4         ;Keep going
         RTS              ;Yes, we have a valid TSL
:NO      LDA   #$FF       ;Nope, not here
         RTS

*
* Read DOS 3.3 sector
*

RDSECT   TXA              ;Save X-Reg
         PHA
         PUSH  RWBUF
         JSR   SETSECT
         RDBLK
         PHA              ;Save error code
         PHP              ; and status bytes
         PLA
         STA   :Err       ;Pull status
         PLA
         STA   :Err+1     ; and error
         PLA
         STA   RWBUF
         STA   :L1+1
         STA   :L2+1
         PLA
         STA   RWBUF+1
         STA   :L1+2
         STA   :L2+2
         BCS   :4
         LDX   #0
         LDA   TEMP       ;neg=2nd half of TSBUF
         BPL   :3A        ;pos=1st half of TSBUF
:3       LDA   TSBUF+$100,X ;2nd half of block
:L1      STA   BLKBUF,X
         INX
         BNE   :3
         BEQ   :4
:3A      LDA   TSBUF,X    ;1st half of block
:L2      STA   BLKBUF,X
         INX
         BNE   :3A
:4       PLA              ;Restore X-reg
         TAX
         LDA   :Err       ;P-reg
         PHA
         LDA   :Err+1     ;A-reg
         PLP              ;and put P where it should be
         RTS

:Err     DS    2          ;Save area for A & P


*
* Read CP/M Big Block
*

RDBBLK   JSR   SETBBLK
:1       JSR   NEXTBBLK
         BCS   :EXIT
         LDY   #0
         LDA   TEMP       ;neg=2nd half of TSBUF
         BPL   :3         ;pos=1st half of TSBUF
:2       LDA   TSBUF+$100,Y
         STA   (TXTPTR),Y
         INY
         BNE   :2
         BEQ   :4
:3       LDA   TSBUF,Y
         STA   (TXTPTR),Y
         INY
         BNE   :3
:4       INC   TXTPTR+1
         INX
         DEC   CPMCNT
         BNE   :1
:EXIT    RTS

WRBBLK   JSR   SETBBLK
:1       JSR   NEXTBBLK
         BCS   :EXIT
         LDA   TEMP       ;neg=2nd half of TSBUF
         BPL   :3         ;pos=1st half of TSBUF
:2       LDA   (TXTPTR),Y
         STA   TSBUF+$100,Y
         INY
         BNE   :2
         BEQ   :4
:3       LDA   (TXTPTR),Y
         STA   TSBUF,Y
         INY
         BNE   :3
:4       PUSH  RWBUF
         POINT RWBUF;TSBUF
         WRBLK
         TAY
         PULL  RWBUF
         TYA
         BCS   :EXIT
         INC   TXTPTR+1
         INX
         DEC   CPMCNT
         BNE   :1
         CLC
:EXIT    RTS

NEXTBBLK LDA   CPMBMAP,X
         STA   TEMP
         AND   #$7
         CLC
         ADC   TEMP2
         STA   BLOCK
         PUSH  RWBUF
         POINT RWBUF;TSBUF
         RDBLK
         TAY              ;Save error code (if any)
         PULL  RWBUF
         TYA              ;Restore error
         LDY   #0
         RTS

SETBBLK  STDB  RWBUF;TXTPTR
         LDA   BIGBLOCK+1
         STA   BLOCK+1
         LDA   BIGBLOCK
         ASL
         ROL   BLOCK+1
         CLC
         ADC   #$18
         AND   #$F8
         STA   TEMP2
         BCC   :1
         INC   BLOCK+1
:1       LDA   BIGBLOCK
         AND   #$3
         ASL
         ASL
         TAX
         LDA   #4
         STA   CPMCNT
         RTS

*
* CP/M --> ProDOS block mapping
*

CPMBMAP  DFB   $00,$84,$81,$06,$03,$87,$80,$05
         DFB   $02,$86,$83,$04,$01,$85,$82,$07

*
* Write DOS 3.3 sector
*

WRSECT   STX   TEMP2
         LDA   RWBUF
         PHA
         STA   :1+1
         STA   :2+1
         LDA   RWBUF+1
         PHA
         STA   :1+2
         STA   :2+2
         JSR   SETSECT
         RDBLK
         TAX              ;Save error
         BCS   :4
         LDX   #0
         LDA   TEMP
         BPL   :2
:1       LDA   BLKBUF,X
         STA   TSBUF+$100,X
         INX
         BNE   :1
         BEQ   :3
:2       LDA   BLKBUF,X
         STA   TSBUF,X
         INX
         BNE   :2
:3       WRBLK
         TAX              ;Save error
:4       PULL  RWBUF
         TXA              ;Restore error
         LDX   TEMP2
         RTS

*
* Set DOS 3.3 sector
*

SETSECT  POINT RWBUF;TSBUF
         LDA   #0
         STA   BLOCK+1
         LDA   TRACK
         ASL
         ROL   BLOCK+1
         ASL
         ROL   BLOCK+1
         ASL
         ROL   BLOCK+1
         STA   BLOCK
         LDX   SECTOR
         LDA   SECTINDX,X
         STA   TEMP
         AND   #$7F
         ORA   BLOCK
         STA   BLOCK
         RTS

SECTINDX HEX   00,07,86,06,85,05,84,04
         HEX   83,03,82,02,81,01,80,87

BLKSECT  DFB   0,$E,$D,$C,$B,$A,9,8,7,6,5,4,3,2,1,$F


HEX2DEC  JSR   COPYNUM
Conv2Dec LDX   #24        ;Divide Accumulator by 10
         LDA   #0
         STA   WORKAREA+3 ;Clear sum
:1       ASL   WORKAREA   ;Rotate all three bytes of
         ROL   WORKAREA+1 ;the accumulator 1 bit
         ROL   WORKAREA+2
         ROL   WORKAREA+3
         SEC
         LDA   WORKAREA+3 ;If MSB > 10 then
         SBC   #10
         BCC   :2
         STA   WORKAREA+3
         INC   WORKAREA   ;Add one to accumulative sum
:2       DEX
         BNE   :1
         LDA   WORKAREA+3
         ORA   #$B0       ;Convert accumulative sum to ASCII
         STA   LNBUF,Y    ;and save it
         DEY              ;bump index
         LDA   WORKAREA   ;If accumulator is zero
         ORA   WORKAREA+1 ;then we're done
         ORA   WORKAREA+2
         BNE   Conv2Dec   ;else go back for more
:3       RTS

DECPRNT  INY
         LDA   LNBUF,Y
         JSR   COUT
         CPY   #8
         BNE   DECPRNT
         RTS

COPYNUM  LDX   #2
:1       LDA   NUM,X
         STA   WORKAREA,X
         DEX
         BPL   :1
         RTS

MOUSEON  LDA   #$1B
         JSR   COUT
         LDA   #$0F
         JSR   COUT
         RTS

MOUSEOFF LDA   #$18
         JSR   COUT
         LDA   #$E
         JSR   COUT
         RTS

COUT2B   JSR   COUT
         DEX
         BNE   COUT2B
         RTS

GOTOXY   LDY   #2
         JSR   GETPARMS
         LDX   PPARMS
         LDY   PPARMS+1
GOTOXY2  STY   CV
         STY   OURCV
         JSR   VTAB
         STX   CH
         STX   OURCH
         RTS

PRNTAT   STX   XSAV
         STY   YSAV
         LDY   #4
         JSR   GETPARMS
         LDX   PPARMS+2
         LDY   PPARMS+3
         JSR   GOTOXY2
         JMP   PRTXT3

PRTXT    STX   XSAV
         STY   YSAV
         LDY   #2
         JSR   GETPARMS
         JMP   PRTXT3
PRTXT2   STX   XSAV
         STY   YSAV
PRTXT3   LDY   #0
:1       LDA   (PPARMS),Y
         BEQ   :3
         CMP   #$20
         BCC   :4         ;Packed text
         JSR   COUT
:2       INY
         BNE   :1
:3       LDY   YSAV
         LDX   XSAV
         RTS
:4       TAX
         LDA   PAKLOC-1,X
         TAX
:5       LDA   PAKTXT,X
         BEQ   :2
         JSR   COUT
         INX
         BNE   :5         ;Always

GETPARMS PHA
         STY   PARMCNT
         TSX
         LDA   STACK+4,X
         STA   PARMPTR
         CLC
         ADC   PARMCNT
         STA   STACK+4,X
         LDA   STACK+5,X
         STA   PARMPTR+1
         ADC   #0
         STA   STACK+5,X
:1       LDA   (PARMPTR),Y
         STA   PPARMS-1,Y
         DEY
         BNE   :1
         PLA
         RTS


SAVCURLOC
         PHA              ;Save A
         LDA   #80        ;Save cursor location and
         STA   WNDWDTH    ;set window to full width
         LDA   OURCH
         STA   CHSAV
         LDA   OURCV
         STA   CVSAV
         PLA
         RTS

RESTCLOC
         PHA              ;Save A
         LDA   #72        ;Restore cursor location and
         STA   WNDWDTH    ;set window to a width of 72 chars.
         LDA   CVSAV
         JSR   SETCV
         LDA   CHSAV
         JSR   SETCH
         PLA
         RTS

SAVEWIN  LDX   #3
         PHA
:1       LDA   $20,X
         STA   WSAV,X
         DEX
         BPL   :1
         JSR   SETTXT
         PLA
         RTS

RESTWIN  LDX   #3
         PHA
:1       LDA   WSAV,X
         STA   $20,X
         DEX
         BPL   :1
         PLA
         RTS

WSAV     DS    4

DUMP     POINT FOUTLOC+1;COPYBUF
         POINT CSW;FOUT   ;Print to buffer
         LDX   #0
:P       LDA   PRINIT+1,X
         JSR   COUT
         INX
         CPX   PRINIT
         BNE   :P
         JSR   CROUT
         JSR   CROUT
         STA   PAGE2OFF
         LDX   #0         ;Start at 1st line
:1       JSR   CROUT      ;Beginning of line
         STX   TEMP       ;Save line #
         LDX   #5         ;Indent 5 chars
         JSR   PRBL2
         LDX   TEMP       ;Get line # back
         TXA
         JSR   TABV       ;Tab to that line
         LDY   #0         ;Start at left edge
:2       BIT   RD80VID    ;If >128 then we're in 40 col mode
         BPL   :3         ;40 column
         STA   PAGE2ON    ;even chars in aux memory
:2B      LDA   (BASL),Y   ;Pick up char from screen
         STA   PAGE2OFF   ;Turn off aux mem before printing
         CMP   #$FF
         BNE   :2A
         LDA   #'_'
:2A      JSR   COUT       ;print the char
:3       LDA   (BASL),Y   ;Get char from main mem
         CMP   #$FF
         BNE   :3A
         LDA   #'_'
:3A      JSR   COUT       ;and print it
         INY              ;Next char in line
         CPY   #40        ;Done yet?
         BCC   :2         ;No
         INX              ;Yes, next line
         CPX   #24        ;Done yet?
         BCC   :1         ;No
         LDA   #0
         JSR   COUT
         LDA   PRTRSLOT   ;Slot for printer
         JSR   OUTPORT
         POINT :PR+1;COPYBUF
:PR      LDA   $FFFF
         BEQ   :10
         CMP   #$20
         BCS   :11
         ORA   #$40
:11      ORA   #$80
         JSR   COUT
         INCW  :PR+1
         JMP   :PR
:10      POINT CSW;$C307  ;80 col warm entry
         RTS

FOUT
FOUTLOC  STA   $FFFF      ;Place holder
         INCW  FOUTLOC+1
:1       RTS

BUZZ     STX   :BX
         LDX   #5
:1       LDA   Buzz1,X
         STA   ZZ1,X
         DEX
         BPL   :1
         INX              ;X=0
         JSR   :BUZZ
         LDX   #2

:BUZZ    LDA   ZZ1,X
         STA   :P1+1
         LDA   ZZ1+1,X
         STA   :P2+1
         LDA   ZZ1+2,X
         STA   :P3+1

:P1      LDA   #$20
         STA   TEMP2
:P2      LDA   #$2
         JSR   WAIT
         STA   SPKR
:P3      LDA   #$24
         JSR   WAIT
         STA   SPKR
         DEC   TEMP2
         BNE   :P2
         LDX   :BX
         RTS

:BX      DS    1

ZZ1      DFB   $36,$4,$18
         DFB   $30,$2,$23

*
* For future macro capability
*

KBDEDIT
KBDLOOK
         LDA   KBD
         PHP
:H       CMP   #"/"       ;Context sensitive help
         BEQ   :2
         CMP   #"?"
         BEQ   :2
         PLP
         RTS
:2       TAX
         LDA   OAPPLE
         ORA   CAPPLE
         BMI   :3
         TXA
         PLP
         RTS
:3       JSR   CTXHELP    ;Call CTX help routine
         STA   STRB
                          ; CTX HLPFcnKeys
         PLP
         JMP   KBDLOOK

MYKEYIN  STY   :YSav      ;Save Y
         STX   :XSav
         LDY   OURCH
         JSR   PICK
         STA   KEYSAV
         JSR   INVERTIT
:1       LDY   OURCH
         JSR   MYWAIT
         BMI   :3
         LDY   OURCH
         JSR   INVERTIT
         JSR   MYWAIT
         PHA
         LDY   OURCH
         JSR   INVERTIT
         PLA
         BPL   :1
:3       STA   STRB
         PHA
         LDY   OURCH
         JSR   INVERTIT
         PLA
         TAX
         AND   #$DF       ;Convert to upper case
         TXA
         CPX   #"H"       ;Character in X-reg
         BEQ   :3a
         CPX   #"h"
         BNE   :4
:3a      LDA   OAPPLE
         ORA   CAPPLE
         BPL   :4
         LDA   OURCV
         STA   TEMP2
         JSR   DUMP
         LDA   TEMP2
         JSR   SETCV
         JMP   :1
:4       TXA
         LDY   :YSav
         LDX   :XSav
         RTS              ;Done

:YSav    DS    1
:XSav    DS    1

MYWAIT   LDX   KeyDly
:0       LDY   KeyDly+1
:1       DEY
         BEQ   :2
         JSR   KBDLOOK
         BMI   :3
         BPL   :1
:2       DEX
         BNE   :0
:3       RTS

INVERTIT LDA   VIEWFLG
         CMP   #$80
         BEQ   :6
:3       LDA   KEYSAV
         BPL   :6
:3A      CMP   #$C0
         BCC   :1
         CMP   #$E0
         BCS   :1
         JSR   PICK
         AND   #%10111111
         BMI   :1A
:1       JSR   PICK
:1A      EOR   #$80
:5       JSR   STORCHAR
         RTS
:6       LDA   KEYSAV
         BMI   :3A
         CMP   #$40
         BCC   :1
         CMP   #$60
         BCS   :1
         JSR   PICK
         EOR   #$40
         BPL   :5
         BRK

PICK     STA   $C001
         STY   :YSAV2
         TYA
         EOR   $20
         ROR
         BCS   :1
         BIT   $C055
         INY
:1       TYA
         LSR
         TAY
         LDA   ($28),Y
         BIT   $C054
                          ; LDY $C01E
         BIT   PickFlag
         BPL   :2
         CMP   #$20
         BCS   :2
         ORA   #$40
:2       LDY   :YSAV2
         RTS
:YSAV2   DS    1

STORCHAR STA   $C001
         PHA
         STY   :YSAV2
         TYA
         EOR   $20
         LSR
         BCS   :2
         BIT   $C055
         INY
:2       TYA
         LSR
         TAY
:3       PLA
         PHA
         STA   ($28),Y
         BIT   $C054
         LDY   :YSAV2
         PLA
         RTS
:YSAV2   DS    1

GETSTR   LDY   #0
GETSTR0  STY   YSAV
         STX   LimitLen
GETSTR1  LDA   #$FF
         STA   PickFlag
GETSTR1a INY
GETSTR2  JSR   MYKEYIN
         CMP   #ESC       ;Escape?
         BEQ   :2
         CMP   #$8D       ;Return key?
         BEQ   :1B
         CMP   #LFTARO    ;Left arrow?
         BEQ   :3
         CMP   #$FF       ;Delete same as left arrow
         BNE   :0
         LDA   OAPPLE     ;Check if an apple key pressed
         ORA   CAPPLE
         BMI   :0B
         LDA   #LFTARO
         BNE   :3
:0B      LDA   #$FF       ;Falls through
:0       CPY   LimitLen
         BNE   :01
:02      JSR   BUZZ
         JMP   GETSTR2
:01      CMP   #RTARO     ;Right arrow?
         BEQ   :4         ;Yes
:1A      CMP   #$20
         BCC   :02
         JSR   CHKCHAR    ;Check if char is valid
         BCC   :Valid
         JMP   GETSTR2
:Valid   STA   (STRPTR),Y
         ORA   #$80
         JSR   COUT       ;Echo the character
         JMP   GETSTR1a   ;Always
:1B      STA   (STRPTR),Y
         STY   YSAV
         JSR   CLREOL     ;Clear any extraneous characters
         LDY   YSAV
         DEY
         TYA
         LDY   #0
         STA   PickFlag
         STA   (STRPTR),Y
         LDA   (STRPTR),Y ;Set status flags
         RTS              ;Yes, return to caller
:2       CPY   #1         ;Was buffer empty?
         BEQ   :1B        ;Yes, exit
:2A      CPY   #1         ;No, erase entry
         BEQ   GETSTR2
         STY   YSAV       ;Yes, erase entry
         LDA   #$88
         JSR   COUT
         JSR   CLREOL
         LDY   YSAV
         DEY
         STY   YSAV
         JSR   CLREOL     ;and clear the line
         LDY   YSAV
         BPL   :2A        ;Always
:3       CPY   #1         ;Left arrow
         BEQ   GETSTR2    ;Can't go back any further
         DEY              ;Decrement counter
         LDA   #$88       ;Print a backspace
         JSR   COUT
         JMP   GETSTR2
:4       LDY   OURCH
         JSR   PICK       ;Pick char from the screen
         JMP   :1A        ;Always


* On Entry:
*   A = Entered key
*   Y = Character position
* Exits with Carry Clear for valid character

CHKCHAR  STA   GSTRSAVA
         STY   GSTRSAVY
         STX   GSTRSAVX
         LDA   GSTRMODE
         BNE   :B1        ;Anything
         LDA   GSTRSAVA
         CPY   #1
         BNE   :1
         CMP   #"%"
         BEQ   :0
         CMP   #"$"
         BEQ   :0
         CMP   #"9"+1
         BCS   :BRTS
         CMP   #"0"
         BCC   :INV
:0       STA   GSTRTYPE
         JMP   :B1
:1       LDX   GSTRTYPE
         CPX   #"%"
         BEQ   :BIN
         CPX   #"$"
         BEQ   :HEX
:DEC     CMP   #"0"
         BCC   :INV
         CMP   #"9"+1
         JMP   :BRTS
:BIN     CMP   #"0"
         BEQ   :B1
         CMP   #"1"
         BEQ   :B1
:INV     SEC
         BCS   :BRTS       ;Always
:HEX     CMP   #"0"
         BCC   :INV
         CMP   #"9"+1
         BCC   :BRTS
         CMP   #"A"
         BCC   :INV
         CMP   #"F"+1
         BCC   :BRTS
         CMP   #"a"
         BCC   :INV
         CMP   #"f"+1
         BCS   :BRTS
:B1      CLC
:BRTS    LDX   GSTRSAVX
         LDA   GSTRSAVA
         LDY   GSTRSAVY
         RTS


MYGETLN  LDX   #0         ;Set index to zero
MYGETLN1 LDA   #$80
         STA   PickFlag
:0A      INX
:1       JSR   MYKEYIN    ;Get a key
:1A      CMP   #LFTARO    ;Back arrow?
         BEQ   :3         ;Yes
         CMP   #RTARO     ;Right Arrow?
         BEQ   :6         ;Yes, forward a char
         CMP   #$8D       ;Return?
         BEQ   :4         ;Yes, end.
         CMP   #DNARO     ;Down and up arrows
         BEQ   :4a
         CMP   #UPARO     ;Act as a RETURN
         BEQ   :4a
         CMP   #$9B       ;Escape?
         BEQ   :5         ;Yes, erase entry
         CMP   #$FF       ;Delete?
         BNE   :2         ;No
         LDA   OAPPLE
         ORA   CAPPLE
         BMI   :0         ;Enter the bloch
         LDA   #LFTARO
         BNE   :3         ;Always
:0       LDA   #$FF
:2       CPX   #65
         BNE   :2A
:2B      JSR   BUZZ
         JMP   :1
:2A      JSR   IsVPNCh
         BCS   :2B
         JSR   COUT       ;Else echo the char
         AND   #$7F       ;clear hi bit
         STA   INBUF,X    ;save it
         BNE   :0A        ;Always
:3       CPX   #1         ;Don't back up past the beginning
         BEQ   :1         ;go back
         JSR   COUT       ;else print the backspace
         DEX              ;and decrement the input length
         BPL   :1         ;Always
:4       JSR   CLREOL
         BIT   SETV
         DEX              ;Don't count this char
         STX   INBUF      ;Count byte into 1st char of buffer
         STX   PickFlag
         RTS
:4a      CPX   #1
         BNE   :1
         STX   PickFlag
         CLV
         RTS              ;and exit
:5       CPX   #1         ;If buffer already empty,
         BEQ   :4         ; then exit to caller
:5B      CPX   #1         ;Else, erase entry
         BEQ   :1
         LDA   #$88       ;erase the buffer
         JSR   COUT       ;and screen name
         JSR   CLREOL
         DEX
         BPL   :5B
:6       CPX   #65
         BEQ   :2B
         LDY   OURCH      ;Get this location
         JSR   PICK       ;Pick character off of screen
         JMP   :2
:61      CMP   #$A0
         BNE   :7
         CTX   HLPEntFN
         JSR   BUZZ
         JMP   :1
:7       CMP   #$A0
         BCS   :8
         CMP   #$80
         BCS   :9
         CMP   #$20
         BCS   :8
:9       ORA   #$40
:8       JMP   :2

PickFlag DS    1

IsVPNCh  PHA
         JSR   ToUpper
         CMP   #"A"
         BCC   :2
         CMP   #"Z"+1
         BCS   :3
:1       CLC              ;Used in '.' and '/' check
         PLA
         RTS              ;Yes, carry clear
:2       CMP   #"0"
         BCC   :3
         CMP   #"9"+1
         BCC   :1
:3       CMP   #"."
         BEQ   :1
         CMP   #"/"
         BEQ   :1
         SEC
         PLA
         RTS              ;Not a valid pathname character

YESNOSET LDA   #2
         STA   YN
         JMP   YNN
YESNO    LDA   #2
         STA   YN
YNN      LDX   #1         ;Default = No
         HEX   2C         ;Same old trick
YESNO2   LDX   #2         ;Default = Yes
         POINT CHPTR;YN
         JSR   CHOOSE
         RTS

CHOOSE   LDA   OURCH
         STA   :CH
         LDA   OURCV
         STA   :CV
         STA   STRB
         DEX
         STX   CURRENT
:A       LDA   :CV
         JSR   VTAB
         LDA   :CH
         STA   OURCH
         STA   CH
         LDY   #0
         LDA   (CHPTR),Y
         STA   MAXCH
:0A      LDX   #0
:0       CPX   MAXCH
         BEQ   :6
:1       STY   :YSav
         CPX   CURRENT
         BEQ   :2
         JSR   SETNORM
         JMP   :3
:2       JSR   SETINV
:3       LDY   :YSav
:4       INY
         LDA   (CHPTR),Y
         BEQ   :5
         JSR   COUT
         JMP   :4
:5       STY   :YSav
         JSR   SETNORM
         LDA   #$A0
         JSR   COUT
         JSR   COUT
         LDY   :YSav
         INX
         BPL   :0         ;Always
:6       JSR   KBDLOOK
         BPL   :6
         STA   STRB
         CMP   #RTARO
         BNE   :7
         INC   CURRENT
         LDA   CURRENT
         CMP   MAXCH
         BNE   :A
         DEC   CURRENT
         BPL   :A
:7       CMP   #LFTARO
         BNE   :8
         LDA   CURRENT
:7A      BEQ   :A
         DEC   CURRENT
:7B      BPL   :A
:8       CMP   #$8D
         BNE   :9
         LDX   CURRENT
         BPL   :E
:9       CMP   #ESC
         BNE   :L
         LDA   #0
         BEQ   :E2
:L       LDY   #1
         STX   :XSav
         LDX   #0
         CMP   #$FB       ;Convert to uppercase
         BCS   :L1
         CMP   #$E0
         BCC   :L1
         AND   #$DF
:L1      STA   :ASav
:9A      CMP   (CHPTR),Y
         BEQ   :E
:10      INY
         LDA   (CHPTR),Y
         BNE   :10
         INY
         INX
         CPX   MAXCH
         BEQ   :12
         LDA   :ASav
         BNE   :9A        ;ALWAYS
:12      LDX   :XSav
         BPL   :7B        ;ALWAYS
:E       INX
         TXA
:E2      PHA
         LDA   :CV
         JSR   VTAB
         LDA   :CH
         STA   OURCH
         STA   CH
         LDA   WNDWDTH
         PHA
         LDA   #45
         STA   WNDWDTH
         JSR   CLREOL
         PLA
         STA   WNDWDTH
         LDA   :CV
         JSR   VTAB
         LDA   :CH
         STA   OURCH
         STA   CH
         PLA
         RTS
:YSav    DS    1
:XSav    DS    1
:ASav    DS    1
:CH      DS    1
:CV      DS    1

BUILD    LDY   #0
         LDX   #0
         LDA   #1
         STA   SCOUNT
:1       JSR   GETPACK
         BEQ   :DONE
         PHA
         AND   #%11100000
         BEQ   :ERROR
         ASL
         BCS   :ZERO
         ASL
         BCS   :FILL
         BCC   :ERROR
:FILL    BPL   :2         ;No repeat count
         JSR   GETPACK
         STA   SCOUNT     ;Repeat count
:2       PLA
         AND   #$1F       ;Length of pattern
         STA   NUM
:3       LDY   #0
:4       LDA   (PATPTR),Y
         JSR   PUTTEXT    ;Put byte
         INY
         CPY   NUM
         BNE   :4
         DEC   SCOUNT
         BNE   :3
         LDA   NUM
         JSR   ADDPACK
         JMP   BUILD
:DONE    LDA   #0         ;Z set = OK
         RTS

:ZERO    PLA
         PHA
         AND   #$1F       ;Repeat count built in
         STA   SCOUNT
         PLA
         AND   #$20
         BEQ   :10        ;No repeat count
         JSR   GETPACK
         STA   SCOUNT
:10      LDA   #0
:11      JSR   PUTTEXT
         DEC   SCOUNT
         BNE   :11
         BEQ   BUILD

:ERROR   PLA              ;Discard
         LDA   #$FF       ;Bad pack record error
         RTS

ADDPACK  CLC
         ADC   PATPTR
         STA   PATPTR
         BCC   :1
         INC   PATPTR+1
:1       RTS

GETPACK  LDA   (PATPTR),Y
GETPACK2 PHA
         INCW  PATPTR
:1       PLA
         RTS

PUTTEXT  STA   (TXTPTR,X)
         INCW  TXTPTR
:1       RTS

VDIRIMG  HEX   44,00,00,03,00,62,FE,00,00
         HEX   44,02,00,04,00,62,FE,00,00
         HEX   44,03,00,05,00,62,FE,00,00
         HEX   42,04,00,62,FF,00,00
         HEX   00
