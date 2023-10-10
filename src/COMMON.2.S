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
*       File: COMMON.2.S       *
*                              *
*           Contents           *
*           --------           *
*                              *
* - More Program text          *
* - Windowing Logic            *
* - Context Sensitive          *
*   Help Logic                 *
* - Word Wrapping logic        *
* - AWP Helper Logic           *
*                              *
********************************

*
* File name parsing routine.  On entry, TEMPPTR points
* to the file name.  On exit, c=1 if invalid pathname syntax
* c=0 if valid.  Also, the A-register is as follows
* Hi nibble - unit number of the parsed filename and
* Lo nibble (bits 0-1):
*      1 = DOS filename
*      2 = PASCAL filename
*      3 = CP/M filename
* FNOfset = relative offset into the filename where
*           the actual file name starts (i.e. after
*           any volume specifiers
*

FNParse  JSR   IsDOS      ;Is it a DOS Name?
         BCC   :7
:5       JSR   IsPASCAL
         BCC   :7
:6       JSR   IsCPM
:7       STY   FNOfset
         RTS

IsDOS    LDY   #1
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #'.'       ;1st char . = DOS filename
         BNE   :NotDOS    ;Not DOS 3.3 name
         INY              ;Y=1, get slot
         LDA   (TEMPPTR),Y
         AND   #$7F
         EOR   #$30
         BEQ   :NoSD      ;No Slot/Drive given (or not valid)
         CMP   #$8        ;Slot # 1-7 valid only
         BCS   :NoSD
         ASL
         ASL
         ASL
         ASL
         STA   WorkUnit
         LDX   #0
         INY              ;Y=2, get drive
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #'1'
         BEQ   :2
         LDX   #$80
         CMP   #'2'
         BNE   :NoSD
:2       TXA
         ORA   WorkUnit
         STA   WorkUnit
         INY              ;Y=3, get trailing period
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #'.'       ;Slot/Drive must be terminated
         BNE   :NoSD      ;with a period
         INY
:4       CLC
         LDA   WorkUnit
         ORA   #1
         RTS
:NoSD    LDA   DOSLast
         LDY   #2
         BNE   :4         ;Always
:NotDOS  SEC
         RTS

IsPASCAL LDY   #0
         LDA   (TEMPPTR),Y
         STA   :PAStemp
:1       INY
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #':'
         BEQ   :2
         CPY   :PAStemp
         BNE   :1
         BEQ   :NotPAS
:2       INY
         STA   PASLast
         ORA   #2         ;Indicate PASCAL device
         CLC
         RTS
:NotPAS  SEC
         RTS
:PAStemp DS    1

IsCPM    LDY   #1
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #'>'       ;Use last accessed drive
         BEQ   :3
         SEC
         SBC   #'A'       ;Max valid drives, A-J
         CMP   DEVCNT
         BCC   :4
         BEQ   :4
:NotCPM  SEC
         RTS
:4       TAX
         INY
         LDA   (TEMPPTR),Y
         AND   #$7F
         CMP   #'>'
         BNE   :NotCPM
         LDA   DEVCNT+1,X
:2       INY
         STA   CPMLast
         ORA   #3         ;Indicate CP/M device
         CLC
         RTS
:3       LDA   CPMLast
         BNE   :2         ;Always

DOSLast  DS    1
PASLast  DS    1
CPMLast  DS    1
WorkUnit DS    1
FNOfset  DS    1          ;Offset from pathname of filename


QUITBB   PRINT BBQuit
         JMP   DOQUIT2

DOQUIT   PRINT AYS
DOQUIT2  JSR   YESNOSET
         BEQ   :1
         CMP   #2
         BEQ   :2         ;Yes, Quit
:1       RTS
:2       PLA
         PLA
         GOTO  0;23
         JSR   CLREOL
         STA   $C081
         MLI   QUIT;PQUIT
         BRK              ;BRK if error

ERROR    PHA
         JSR   BUZZ
         PLA
         JSR   BUZLESS
         LDA   #$A0
         JSR   COUT
         LDA   #"("
         JSR   COUT
         LDA   #"$"
         JSR   COUT
         LDA   $BF9C      ;Last MLI call return address
         SEC
         SBC   #6         ;Make it the address of the call
         PHA
         LDA   $BF9D
         SBC   #0
         JSR   PRBYT
         PLA
         JSR   PRBYT
         LDA   #")"
         JSR   COUT
         RTS

BUZLESS  LDX   NUMOFERS
:1       CMP   ERCODES,X
         BEQ   :3
         DEX
         BPL   :1
         PHA
         PRINT MLIER
         PLA
         JSR   PRBYT
         CTX   HLPMLIErr
:2       RTS
:3       LDA   ERRHLP,X
         STA   MYCTX
         LDA   EROFST,X
         CLC
         ADC   #<ERRTXT
         STA   PPARMS
         LDA   #>ERRTXT
         ADC   #0
         STA   PPARMS+1
         JSR   PRTXT2
         RTS

WAIT4
ERROR1   PRINT ERRHIT
         JSR   MYKEYIN
         RTS

*
* Flags and other data
*

STACKTOP DS    1          ;Save area for stack pointer
EOFLAG   DS    1          ;End of File/Format Flag
KEYSAV   DS    1
LASTRDLEN DS   1
SRCEUNIT DS    1          ;Source slot/dirve for volume copy
DESTUNIT DS    1          ;Destination slot/dirve for volume copy
TRACK    DS    1          ;Holds DOS 3.3 track #
SECTOR   DS    1          ;Holds DOS 3.3 sector #
IDBYTE   DS    1
BIGBLOCK DS    2          ;2 bytes
CPMCNT   DS    1          ;# of sectors in CP/M big block
IBCOUNT  DS    2          ;Number of index blocks found
DIRCOUNT DS    2          ;Number of directories found
WLEFT    DS    1          ;Window data
WIDTH    DS    1
WTOP     DS    1
WLINES   DS    1
ActiveTut DS   1          ;0=Tutor active
RBufSave DS    2          ;Save area for Read Buffer pointer

MLIER    ASC   "MLI E"16
         ASZ   " $"
ERRHIT   ASZ   ", hit a key "

ERCODES  HEX   27,28,2B,40
         HEX   4E,52,44,46
         HEX   45,47,48,49
         HEX   4A,4C,4D,51
         HEX   5A,50
NUMOFERS DFB   *-ERCODES-1

EROFST   DFB   IOERR-ERRTXT,NDC-ERRTXT,WP-ERRTXT,INVPN-ERRTXT
         DFB   ACSER-ERRTXT,NPV-ERRTXT,DIRNF-ERRTXT,FNF-ERRTXT
         DFB   VNM-ERRTXT,FAE-ERRTXT,DFL-ERRTXT,VDFL-ERRTXT
         DFB   IFV-ERRTXT,EOD-ERRTXT,PSTEOF-ERRTXT,BFC-ERRTXT
         DFB   BBM-ERRTXT,FAO-ERRTXT

ERRHLP   DFB   HLPProErr1,HLPProErr1,HLPProErr1,HLPProErr3
         DFB   HLPProErr1,HLPProErr2,HLPMLIErr,HLPProErr3
         DFB   HLPProErr3,HLPProErr4,HLPProErr5,HLPProErr5
         DFB   HLPProErr4,HLPProErr5,HLPProErr5,HLPProErr2
         DFB   HLPProErr2,HLPProErr4

ERRTXT
IOERR    ASC   "I/O E"1600
NDC      ASZ   "No device connected"
WP       ASZ   "Write protected"
INVPN    ASZ   "Invalid pathname syntax"
ACSER    ASC   "Access e"1600
NPV      ASZ   "Not a ProDOS disk"
DIRNF    ASC   "D",01020600 ;Directory not found
FNF      ASC   "F"03020600 ;File not found
VNM      HEX   0802       ;Volume not mounted
         ASZ   "mounted"
FAE      ASC   "F"03 ;File already exists
         ASZ   "already exists  "
DFL      ASZ   "Disk Full"
VDFL     HEX   08
         ASC   "D"01 ;Volume Directory Full
         ASZ   "Full"
IFV      ASC   "Incompatable f"03
         ASC   "v"0900
EOD      ASZ   "End of Data"
PSTEOF   ASC   "P"0a
         ASZ   " past EOF"
BFC      ASC   "Bad f"03
         ASZ   " count"
BBM      ASZ   "Bad Bitmap"
FAO      ASC   "Can't copy f"03
         ASZ   "to itself"

PRWBLK   HEX   03
UNITNUM  HEX   60
RWBUF    DW    DIRBUF
BLOCK    DS    2

PPFX     HEX   01
PFXPN    DA    PFXADR

PDESTROY HEX   01
DESPN    DA    PNAME

PRENAME  HEX   02
RENPN    DA    PNAME
RENPN2   DA    PNAME2

PONLINE  HEX   02
OLUNIT   HEX   00
OLBUF    DA    OLLIST

PCREATE  HEX   07
CREPN    DA    PNAME
CRACS    DS    1
CRETYP   DS    1
CREAUX   DS    2
CRESTOR  DS    1
CREDAT   DS    2
CRETIM   DS    2

POPEN    HEX   03
OPENPN   DA    PNAME
OPENBUF  DA    PRIBUF
OPENREF  DS    1

PCLOSE   HEX   01
CLOSEREF DS    1

PREAD    HEX   04
READREF  DS    1
READBUF  DA    DIRBUF
READLEN  DW    $0000
READACT  DW    $0000

PWRITE   HEX   04
WRITEREF DS    1
WRITEBUF DA    DIRBUF
WRITELEN DW    $0000
WRITEACT DS    2

PFILINFO HEX   07
FIPN     DA    PNAME
FIACC    DS    1
FITYP    DS    1
FIAUX    DS    2
FISTOR   DS    1
FIBLKS   DS    2
FIDATM   DS    2
FITIMM   DS    2
FICRDAT  DS    2
FICRTIM  DS    2

PGSEOF   HEX   02
EOFREF   DS    1
FIEOF    DS    3

PGSMARK  HEX   02
MARKREF  DS    1
FIMARK   DS    3

PQUIT    HEX   04
         DS    1
         DS    2
         DS    1
         DS    2

MONTHS   ASC   "???JANFEBMARAPRMAY"
         ASZ   "JUNJULAUGSEPOCTNOVDEC"
NONPDDSK ASZ   "NON-ProDOS DISK"
DIST     ASZ   "Distroy "
DAT      DFB   18
         ASZ   ": "
BF       ASC   "B"07 ;Blocks Free
         ASZ   "s Free: "
TOTBLKS  ASC   "     Total B"07 ;Total Blocks: "
         ASZ   "s: "
NODATE   ASZ   "{No Date}"
NONE     ASZ   "none"
PRTRTXT  ASZ   "Printer: "
         DO    ASMEDIT
         ELSE
BIU      ASC   "B"07 ;Blocks Used
         ASZ   "s Used"
         FIN
BBQuit   ASZ   "Quit Block Buster? "
AYS      ASZ   "Are you sure? "
SLOT     ASC   "Slot: ( )"888800

ANDMASK  HEX   7F,BF,DF,EF,F7,FB,FD,FE
ORMASK   HEX   80,40,20,10,08,04,02,01

DSKFIL   HEX   02
         ASZ   "Disks"
         ASZ   "Files"

YN       HEX   02
         ASZ   "No"
         ASZ   "Yes"
         ASZ   "Run Setup"

PAKLOC   DFB   P1-PAKTXT,P2-PAKTXT,P3-PAKTXT,P4-PAKTXT
         DFB   P5-PAKTXT,P6-PAKTXT,P7-PAKTXT,P8-PAKTXT
         DFB   P9-PAKTXT,P10-PAKTXT,P11-PAKTXT,P12-PAKTXT
         DFB   P13-PAKTXT,P14-PAKTXT,P15-PAKTXT,P16-PAKTXT
         DFB   P17-PAKTXT,P18-PAKTXT,P19-PAKTXT,P20-PAKTXT
         DFB   P21-PAKTXT,P22-PAKTXT,P23-PAKTXT

PAKTXT
P1       ASZ   "irectory "
P2       ASZ   "not "
P3       ASZ   "ile "
P4       ASZ   "Parent "
P5       ASZ   "ntry "
P6       ASZ   "found"
P7       ASZ   "lock"
P8       ASZ   "Volume "
P9       ASZ   "ersion"
P10      ASZ   "osition"
P11      ASZ   "Empty"
P12      ASZ   "deleted"
P13      ASZ   "Type"
P14      ASZ   "Name"
P15      ASZ   "ector"
P16      ASZ   "rack"
P17      ASZ   "Unused"
P18      ASZ   "Date"
P19      ASZ   "Minimum "
P20      ASZ   "Address"
P21      ASZ   "System "
P22      ASZ   "rror"
P23      ASZ   "Device "

FTYPES   HEX   00,01,02,03,04,05,06,0F,19,1A,1B,21,E0,EF
         HEX   F0,F1,F2,F3,F4,F5,F6,F7,F8,FA,FB,FC,FD,FE
         HEX   FF

TYPES    ASC   "NOTBADPCDPTXTXTPDABINDIRADBAWPASPIP LBRPAS"
         ASC   "CMDUR1UR2UR3UR4UR5UR6UR7UR8INTIVRBASVARREL"
         ASC   "SYS"


********************************
*                              *
*          Windowing           *
*  and Context Sensitive Help  *
*           Routines           *
*                              *
********************************


CTXHELP  STA   :CtxASav
         STX   :CtxXSav
         STY   :CtxYSav
         LDA   #$FF
         STA   WINNUM
         STDB  READBUF;RBufSave
         STA   ActiveTut  ;Say tutorial not active
         POINT WinBuf;WSAVBUF
         LDA   OURCH
         STA   :CTXCH
         LDA   OURCV
         STA   :CTXCV
         STDB  BASL;:CTXBASL
         JSR   SAVEWIN
         JSR   SETTXT
         LDA   MYCTX
         JSR   CTXHLP
         BCC   :0
         WIN   0;25;9;32;5 ;Can't find help files
         JSR   SETNORM    ;So tell user
         POINT WPTR;HelpLess
         JSR   TXTOUT
         JSR   KWAIT
         JMP   :1

:0       JSR   KWAIT
         TAY
         LDA   OAPPLE
         ORA   CAPPLE
         BMI   :3A
:0A      LDX   MYCTX
         STX   FIRSTFLG
         CPX   #HLPFcnKeys
         BNE   :0B
         JMP   :4
:0B      CPX   #HLPTitle
         BEQ   :12
:1       JSR   KillAll
:ERR     JSR   RESTWIN
         LDA   #$FF
         STA   ActiveTut
         LDA   :CTXCH
         JSR   SETCH
         LDA   :CTXCV
         JSR   SETCV
         STDB  :CTXBASL;BASL
         STDB  RBufSave;READBUF
         LDA   :CtxASav
         LDX   :CtxXSav
         LDY   :CtxYSav
         RTS

:12      CPY   #"?"
         BEQ   :13
         CPY   #"/"
         BEQ   :13
         JMP   :1
:13      LDA   #HLPAbout
         STA   REALCTX
         JSR   CTXHLP2
         JMP   :0

:3A      CPY   #DNARO     ;Check for AA-Up/Down
         BNE   :3B        ;If so, next/prev topic
         JSR   KillAll
:3A2     LDA   HLPStats
         CMP   REALCTX
         BEQ   :3a1
         INC   REALCTX
         BNE   :31A       ;Always
:3a1     LDA   #1
         STA   REALCTX
:31A     JSR   CTXHLP2
         JMP   :0

:3B      CPY   #UPARO
         BNE   :3C
         JSR   KillAll
:3B2     DEC   REALCTX
         BNE   :31A
         LDA   HLPStats
:3B3     STA   REALCTX
         BNE   :31A       ;Always
:3C      CPY   #"/"
         BEQ   :3D
         CPY   #"?"
         BNE   :3C2
         LDA   #HLPTitle
         BNE   :3B3
:3C2     JSR   KillAll
         LDA   #HLPFcnKeys
         BNE   :3B3       ;Always
:3C1     JMP   :1
:3D      JSR   KillAll
         LDA   ActiveTut
         BNE   :3D1
         JMP   :0
:3D1     LDA   #0
         STA   ActiveTut  ;Say tutorial is active
         LDA   #HLPTutor
         BNE   :3B3

:4       TYA
         CMP   #$E0
         BCC   :4A
         AND   #$DF       ;Convert to Uppercase
:4A      STA   :TMP
         LDX   #0
:5       LDA   :FCTNS,X
         BEQ   :6         ;All done
         CMP   :TMP
         BEQ   :10
         INX
         BNE   :5         ;Always
:6       JMP   :1         ;Unknown keys do nothing for now
:10      LDA   :FCTX,X
         PHA
         JSR   KillAll
         PLA
         JSR   CTXHLP
         JMP   :0

:CTXBASL DS    2
:CTXCV   DS    1
:CTXCH   DS    1
:TMP     DS    1
:CtxASav DS    1
:CtxXSav DS    1
:CtxYSav DS    1

:FCTNS   ASC   "ABCDE"
         ASC   "FGHIJ"
         ASC   "KLMNO"
         ASC   "PQRST"
         ASC   "UVWXY"
         ASC   "Z,. "
         ASC   "?/,"
         DFB   UPARO,DNARO,LFTARO
         DFB   RTARO,TAB,0

:FCTX    DFB   HLPaaA,HLPaaB,HLPaaC,HLPaaD,HLPaaE
         DFB   HLPaaF,HLPaaG,HLPaaH,HLPaaI,HLPaaJ
         DFB   HLPaaK,HLPaaL,HLPaaM,HLPaaN,HLPaaO
         DFB   HLPaaP,HLPaaQ,HLPaaR,HLPaaS,HLPaaT
         DFB   HLPaaU,HLPaaV,HLPaaW,HLPaaX,HLPaaY
         DFB   HLPaaZ,HLPIncDec,HLPIncDec,HLPEditKeys
         DFB   HLPAbout,HLPAbout,HLPCursor,HLPCursor
         DFB   HLPCursor,HLPCursor,HLPCursor
         DFB   HLPCursor,HLPCursor

KWAIT    STA   STRB
:1       LDA   KBD
         BPL   :1
         STA   STRB
         CMP   #$81
         BNE   :2
         JMP   $FF69
:2       CMP   #"H"
         BNE   :3
         CMP   #"h"
         BNE   :3
         JSR   DUMP
         JMP   KWAIT
:3       RTS

KillAll  JSR   KILLWIN
         BPL   KillAll
         RTS

KILLWIN
         LDA   WINNUM
         BPL   :0
         RTS
:0       ASL
         ASL
         ASL              ;*8
         PHA
         TAX
         LDA   WinList,X
         STA   WinBuf
         LDA   WinList+1,X
         STA   WinBuf+1
         LDY   #0
:1       LDA   WinList+2,X
         STA   PPARMS+1,Y
         INX
         INY
         CPY   #4
         BNE   :1
         JSR   SetTxt
         LDA   #2
         STA   PPARMS
         JSR   WSTUFF2    ;Restore screen
         PLA
         TAX
         LDA   WinList,X
         STA   WinBuf
         LDA   WinList+1,X
         STA   WinBuf+1
         DEC   WINNUM
         RTS

NEWWIN
         LDY   #5
         JSR   GETPARMS
         LDA   PPARMS
         STA   :FMT
         INC   WINNUM
         LDA   WINNUM
         ASL
         ASL
         ASL              ;*8
         TAX
         LDA   WinBuf
         STA   WinList,X
         LDA   WinBuf+1
         STA   WinList+1,X
         LDY   #0
:4       LDA   PPARMS+1,Y
         STA   WinList+2,X
         INX
         INY
         CPY   #4
         BNE   :4
         JSR   SetTxt
                          ; LDA #1
                          ; STA PPARMS
                          ; JSR WSTUFF2 ;Save background
                          ; LDA #3
                          ; STA PPARMS
                          ; JSR WSTUFF2 ;Clear backround
         LDA   #4         ;Save and clear background
         STA   PPARMS
         JSR   WSTUFF2
         LDY   TopLeftY   ;Top of Box
         JSR   WINSETCV
         LDA   #$20
         LDY   TopLeftX
:1       INY
         JSR   STORCHAR
         INY
         CPY   BotRtX
         DEY
         BCC   :1         ;Always

         LDY   BotRtY     ;Bottom of Box
         JSR   WINSETCV
         LDA   #$20
         LDY   TopLeftX
:2       INY
         JSR   STORCHAR
         INY
         CPY   BotRtX
         DEY
         BCC   :2

         LDY   TopLeftY   ;Sides of Window
         STY   :TMP
         INC   :TMP
:3       LDY   :TMP
         JSR   WINSETCV
         LDY   TopLeftX
         LDA   #'Z'
         JSR   STORCHAR
         LDY   BotRtX
         LDA   #'_'
         JSR   STORCHAR
         INC   :TMP
         LDA   :TMP
         CMP   BotRtY
         BCC   :3
         RTS
:TMP     DS    1
:FMT     DS    1

SetTxt
         LDA   TopLeftX
         STA   WLEFT
         INC   WLEFT
         INC   WLEFT
         LDA   BotRtX
         SEC
         SBC   TopLeftX
         STA   WIDTH
         DEC   WIDTH
         DEC   WIDTH
         LDA   TopLeftY
         STA   WTOP
         INC   WTOP
         LDA   BotRtY
         SEC
         SBC   TopLeftY
         STA   WLINES
         DEC   WLINES
         RTS

WINNUM   DS    1          ;Highest window #
WinList  DS    10*5       ;5 bytes per window


BOXIT2   LDX   PPARMS
         LDY   PPARMS+1
         DEY
         JSR   WINXY
         JSR   MOUSEON
         LDX   PPARMS+2
         LDA   #"L"       ;Top
         JSR   COUT2B
         LDA   PPARMS+3
         CLC
         ADC   PPARMS+1
         TAY
         LDX   PPARMS
         JSR   WINXY
         LDX   PPARMS+2
         LDA   #"L"       ;Bottom
         JSR   COUT2B
         LDY   PPARMS+1
         DEY
         STY   OURCV
         STY   CV
:2       JSR   VTAB
         LDX   PPARMS
         DEX
         STX   CH
         STX   OURCH
         LDA   #"Z"       ;Left side of box
         JSR   COUT
         LDA   PPARMS+2
         CLC
         ADC   PPARMS
         TAX
         STX   CH
         STX   OURCH
         LDA   #"_"       ;Right side of box
         JSR   COUT
         LDA   PPARMS+3
         CMP   #22
         BNE   :2A
         LDY   CV
         DEY
         CPY   PPARMS+3
         BNE   :2
         BEQ   :0
:2A      INC   CV
         INC   OURCV
         CLC
         ADC   PPARMS+1
         CMP   CV
         BNE   :2
:0       JSR   MOUSEOFF
         RTS

WINXY    JSR   WINSETCV
         STX   CH
         STX   OURCH
         RTS

WINSETCV STY   CV
         STY   OURCV
         JSR   VTAB
         RTS

WSTUFF
         LDY   #5
         JSR   GETPARMS
WSTUFF2  LDA   PPARMS
         ASL
         TAX
         LDA   BOXLOCS-2,X
         STA   :BOXSUB+1
         LDA   BOXLOCS-1,X
         STA   :BOXSUB+2
         LDX   BotRtY
:1       CPX   TopLeftY
         BCC   :9
         TXA
         ASL
         TAY
         LDA   BASLS,Y
         STA   DESTBASL
         LDA   BASLS+1,Y
         STA   DESTBASL+1
         LDY   TopLeftX
:4       TYA
         PHA
         LSR
         STA   WinYSav
         TAY
         LDA   TXTPAGE2
         BCC   :BOXSUB
         LDA   TXTPAGE1
:BOXSUB  JSR   $0000
:6       LDA   TXTPAGE1
         PLA
         TAY
         INY
         CPY   BotRtX
         BCC   :4
         BEQ   :4
         DEX
         BPL   :1
:9       RTS

BOXLOCS  DA    SAVEBOX,RESTBOX,CLRBOX,SaveNClr

RESTBOX  LDY   #0
         LDA   (WinBuf),Y
         LDY   WinYSav
         STA   (DESTBASL),Y
         INCW  WinBuf
:1       RTS

SAVEBOX  LDA   (DESTBASL),Y
         LDY   #0
         STA   (WinBuf),Y
         INCW  WinBuf
:1       RTS

CLRBOX   LDA   #$A0
         STA   (DESTBASL),Y
         RTS

SaveNClr LDA   (DESTBASL),Y
         PHA
         LDA   #$A0
         STA   (DESTBASL),Y
         LDY   #0
         PLA
         STA   (WinBuf),Y
         INCW  WinBuf
         RTS

WinYSav  DS    1

BASLS    DA    $400,$480,$500,$580,$600,$680,$700,$780
         DA    $428,$4A8,$528,$5A8,$628,$6A8,$728,$7A8
         DA    $450,$4D0,$550,$5D0,$650,$6D0,$750,$7D0


********************************
*                              *
*         Word Wrapping        *
*      Printing Functions      *
*                              *
********************************

*
* Format for calling
*
*        POINT WPTR;MessageText
*        JSR   TXTOUT
*
* Call WRAPIT to print from cursor position
*

TXTOUT   LDY   WTOP
         JSR   WINSETCV
         JSR   WRAPIT
         RTS

WRAPIT   LDA   WLEFT
         STA   OURCH
         STA   CH
:0       LDY   #0
:1       LDA   (WPTR),Y
         BEQ   :DONE
         CMP   #" "
         BEQ   :SP
         CMP   #$8D
         BEQ   :SP
         INY
         TYA
         CLC
         ADC   OURCH
         SEC
         SBC   WLEFT
         CMP   WIDTH
         BCC   :1
         JSR   NL
:SP      JSR   PRWORD
         JMP   :1
:DONE    JSR   PRWORD
:4       RTS

NL       INC   OURCV
         LDA   OURCV
         TAY
         SBC   WTOP
         CMP   WLINES
         BCS   :5
         JSR   WINSETCV
         LDA   WLEFT
         STA   OURCH
         CLC
:5       RTS

PRWORD   LDY   #0
:1       LDA   (WPTR),Y
         BEQ   :3
         CMP   #" "
         BEQ   :2
         CMP   #$8D
         BNE   :1A
         JSR   NL
         JMP   :2A
:1A      JSR   COUT
:1B      INC   WPTR
         BNE   :1
         INC   WPTR+1
         BNE   :1         ;Always
:2       JSR   COUT
:2A      INC   WPTR
         BNE   :3
         INC   WPTR+1
:3       RTS

********************************
*                              *
*       Context Sensitive      *
*         AWP Help File        *
*      Printing Functions      *
*                              *
********************************

CTXHLP   STA   REALCTX
CTXHLP2  POINT OPENPN;IDXPN
         POINT OPENBUF;HLPBUF
         MLI   OPEN;POPEN
         BCC   :1
         RTS              ;Error
:1       LDA   #0
         STA   FIMARK+2
         STA   READLEN+1
         STDB  READBUF;RBufSave
         POINT READBUF;HLPStats
         LDA   #8
         STA   READLEN
         LDA   OPENREF
         STA   CLOSEREF
         STA   READREF
         STA   MARKREF
         MLI   READ;PREAD ;Read Help Index Stat (8 bytes)
         BCS   :E
         POINT READBUF;CTXPARMS
         LDA   #0
         STAT  FIMARK+1
         LDA   REALCTX
         STA   FIMARK
         ASL   FIMARK     ; Context * 8
         ROL   FIMARK+1
         ASL   FIMARK
         ROL   FIMARK+1
         ASL   FIMARK
         ROL   FIMARK+1
         MLI   SETMARK;PGSMARK
         BCS   :E
:2       MLI   READ;PREAD
         BCS   :E
         STDB  CTXADR;FIMARK
         STDB  CTXLEN;READLEN
         MLI   CLOSE;PCLOSE
         BCC   :3
         BCS   :ERR
:E       PHA
         MLI   CLOSE;PCLOSE
         PLA
:ERR     SEC
         RTS
:3       POINT OPENPN;HELPPN
         POINT READBUF;HLPBUF2
         MLI   OPEN;POPEN
         BCS   :ERR
         LDA   OPENREF
         STA   READREF
         STA   CLOSEREF
         STA   MARKREF
         MLI   SETMARK;PGSMARK
         BCS   :E
         MLI   READ;PREAD
         BCS   :E
         MLI   CLOSE;PCLOSE
         BCS   :ERR
         INC   CTXCOL
         INC   CTXCOL
         INC   CTXCOL
         LDA   CTXX
         AND   CTXY
         CMP   #$FF
         BEQ   :10        ;Calculate X & Y for centered window
         LDA   CTXX
         STA   :X
         LDA   CTXY
         STA   :Y
         JMP   :11
:10      LDA   #24
         SEC
         SBC   CTXROW
         LSR
         STA   :Y
         LDA   #80
         SEC
         SBC   CTXCOL
         LSR
         STA   :X

:11      CLC
         LDA   :X
         ADC   CTXCOL
         STA   :W
         CLC
         LDA   :Y
         ADC   CTXROW
         STA   :H
         JSR   NEWWIN
         DS    1          ;Format
:X       DS    1          ;Columns
:Y       DS    1          ;Rows
:W       DS    1          ;Width
:H       DS    1          ;Height

AWPMSG   STDB  READBUF;WPTR
         LDA   #0
         STA   :MSTAT
:00      LDY   WTOP
:0       JSR   WINSETCV
:0B      LDA   WLEFT
         STA   OURCH
         STA   CH
         LDY   #1
         LDA   (WPTR),Y
         BEQ   :0A
         JMP   :10        ;Do page formatting commands
:0A      LDY   #0
         LDA   (WPTR),Y
         STA   :LEN
         INC   :LEN
         LDY   #2
         LDA   (WPTR),Y
         AND   #$7F
         BEQ   :3
         TAX
         JSR   PRBL2
:3       LDY   #3
:1       INY
         LDA   (WPTR),Y
         CMP   #$20
         BCC   :12        ;Control char, do mousetext
         LDX   :MSTAT
         BEQ   :6         ;No MouseText
         CMP   #'@'
         BCC   :6
         CMP   #'_'+1
         BCS   :6
         PHA
         JSR   MOUSEON
         PLA
         JSR   COUT
         JSR   MOUSEOFF
         JMP   :7
:6       ORA   #$80
         JSR   COUT
:7       CPY   :LEN
         BCC   :1
         INY
         TYA
:8       CLC
         ADC   WPTR
         STA   WPTR
         BCC   :2
         INC   WPTR+1
:2       INC   OURCV
         LDA   OURCV
         TAY
         SEC
         SBC   WTOP
         CMP   WLINES
         BCC   :0
         CLC
         RTS
:10      TAX              ;Page formatting commands
         LDA   #2
         CPX   #$D0
         BEQ   :8
         CLC
         ADC   WPTR
         STA   WPTR
         BCC   :11
         INC   WPTR+1
:11      CPX   #$EC       ;Page header
         BEQ   :30
         JMP   :0B
:12      CMP   #1
         BEQ   :16        ;Bold on
         CMP   #2
         BEQ   :17        ;Bold off
         CMP   #7
         BEQ   :20        ;Underline on (MOUSE ON)
         CMP   #8
         BEQ   :25        ;Underline off (MOUSE OFF)
         CMP   #16
         BEQ   :26        ;Special Code 1
:12a     PHA
         JSR   MOUSEON
         PLA
         LDX   #MsAWKS-MsCh-1
:13      CMP   MsAWKS,X
         BEQ   :14
         DEX
         BPL   :13
         JMP   :14B
         BRK
:14      LDA   MsCh,X
         JSR   COUT
:14B     JSR   MOUSEOFF
:15      JMP   :7
:16      LDA   #0
         STA   :6+1
         BEQ   :15
:17      LDA   #$80
         STA   :6+1
         BNE   :15

:20      LDA   #1
         STA   :MSTAT     ;MouseText on
         JMP   :7
:25      LDA   #0         ;MouseText off
         STA   :MSTAT
         JMP   :7
:26      LDA   BBVERNUM
         JSR   PVER
         JMP   :7

:30      LDY   WTOP
         DEY
         JSR   WINSETCV
         LDY   #0
         LDA   (WPTR),Y
         STA   :LEN
         INC   :LEN
         LDY   #3
:31      INY
         LDA   (WPTR),Y
         JSR   COUT
         CPY   :LEN
         BCC   :31
         INY
         TYA
         CLC
         ADC   WPTR
         STA   WPTR
         BCC   :32
         INC   WPTR+1
:32      JMP   :00

:LINES   DS    1
:LEN     DS    1
:MSTAT   DS    1          ;MouseText status

MsCh     ASC   "A"
MsAWKS   HEX   0A

MYCTX    DS    1
REALCTX  DS    1

MYBRK
         PHA              ;Save A
         PHP              ;Save P
         LDA   BRKFLAG
         BNE   :2
         PLP
         PLA
         JMP   DIE        ;Broke while doing BRK, die
:2       TXA
         PHA              ;Save X
         TYA
         PHA              ;Save Y
         TSX
         TXA              ;Print SP
         LDX   #25
         CLC
         ADC   #4         ;SP + 4
         JSR   BRKBYTE
         PLA              ;Get Y from stack
         LDX   #19
         JSR   BRKBYTE
         PLA              ;Get X from stack
         LDX   #14
         JSR   BRKBYTE
         PLA              ;Get P from stack
         LDX   #30
         JSR   BRKBYTE
         PLA              ;Get A from stack
         LDX   #9
         JSR   BRKBYTE

         LDA   #0         ;Say we're doing a BRK
         STA   BRKFLAG
         LDA   OURCH
         STA   :BRKCH
         LDA   OURCV
         STA   :BRKCV
         STDB  BASL;:BRKBASL
         JSR   SAVEWIN
         JSR   SETTXT

         LDX   #0
         JSR   GETBRKPC

         WIN   0;15;4;50;10
         JSR   SETNORM
         POINT WPTR;BRKMSG
         JSR   TXTOUT
         JSR   KWAIT
         JSR   KILLWIN
         JSR   RESTWIN
         LDA   :BRKCH
         JSR   SETCH
         LDA   :BRKCV
         JSR   SETCV
         STDB  :BRKBASL;BASL
         LDA   #$FF
         STA   BRKFLAG
         JMP   (:RTN)

:BRKCV   DS    1
:BRKCH   DS    1
:BRKBASL DS    2

:RTN
BRKRTN   DS    2          ;Filled in later
ORIGBRK  DS    2          ;Original BRK vector
BRKFLAG  DS    1          ;Zero if handling a BRK


GETBRKPC LDA   PCL
         SEC
         SBC   #2         ;Set PCL/H to point to
         STA   PCL        ;to actual point
         LDA   PCH        ;of the BRK instruction
         SBC   #0
         STA   PCH
         JSR   BRKBYTE    ;Put address into
         LDA   PCL

BRKBYTE  PHA
         LSR
         LSR
         LSR
         LSR
         JSR   :CH
         PLA

:CH      AND   #$F
         ORA   #$B0
         CMP   #$BA
         BCC   :1
         ADC   #6
:1       STA   BRKLOC,X
         INX
         RTS

DIE      JSR   SETTXT
         JSR   HOME
         LDX   #DEATHLOC-BRKLOC
         JSR   GETBRKPC
         PRAT  20;10;DEATH
         PRAT  26;9;DEATH2
:1       JMP   :1

BRKMSG   HEX   8D
         ASC   "I am experiencing technical difficulties at $"
BRKLOC   ASC   "0000.  A=00 X=00 Y=00 SP=00 P=00 "
         ASC   "Please report the error, your machine "
         ASC   "and other hardware you were using.  "
         ASC   "Also, please explain the steps "
         ASC   "to recreate it."8d8d
         ASC   "      Thank You,  The Management"
         HEX   00

DEATH    ASC   "We seem to have a serious problem at $"
DEATHLOC ASZ   "0000."
DEATH2   ASZ   "Please open an Issue on the GitHub project page."

HelpLess HEX   8D
         ACR   "Getting errors trying to read"
         ASZ   "   index and/or help file."
