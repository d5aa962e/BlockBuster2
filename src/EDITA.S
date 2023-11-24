***************************************************
*                                                 *
*                Block Buster 2.x                 *
*        The Next Generation Block Editor         *
*                                                 *
*            Originally written in the            *
*               1985-1992 timeframe.              *
*                                                 *
*                 Code Repository                 *
*     https://github.com/d5aa962e/BlockBuster2    *
*                                                 *
*       BlockBuster2 by github.com/d5aa962e       *
*    is licensed under CC BY-SA 4.0. To view a    *
*           copy of this license, visit           *
*  http://creativecommons.org/licenses/by-sa/4.0/ *
*                                                 *
***************************************************

********************************
*                              *
*        File: EDITA.S         *
*                              *
*           Contents           *
*           --------           *
*                              *
* - Editor Main Entry          *
* - Screen Redraw              *
* - Keyboard Input             *
* - Command Dispatcher         *
* - Cursor Movement            *
*   UDLR, ?, Tab, Esc          *
* - Entry Descriptions         *
* - Block Read Mode            *
*                              *
********************************

*
* Help Context ID's
*

* IDs are sequential starting at 1
* Putting these in a Dummy section
* effectively numbers the labels sequentially.

	DUM	1

HLPTitle	DS	1
HLPAbout	DS	1
HLPAbout2	DS	1
HLPFcnKeys	DS	1
HLPCursor	DS	1
HLPFcnKy2	DS	1
HLPConfig	DS	1
HLPGeneral	DS	1
HLPEditKeys	DS	1
HLPaaA	DS	1
HLPaaB	DS	1
HLPEntBlkN	DS	1
HLPIncDec	DS	1
HLPaaC	DS	1
HLPCpy2Clip	DS	1
HLPHilite	DS	1
HLPCpyFrmClip	DS	1
HLPClipHlp	DS	1
HLPaaD	DS	1
HLPaaE	DS	1
HLPaaF	DS	1
HLPWhileF	DS	1
HLPaaG	DS	1
HLPaaH	DS	1
HLPaaI	DS	1
HLPaaJ	DS	1
HLPJmpOpt	DS	1
HLPaaK	DS	1
HLPaaL	DS	1
HLPaaM	DS	1
HLPaaN	DS	1
HLPaaO	DS	1
HLPaaP	DS	1
HLPaaQ	DS	1
HLPaaR	DS	1
HLPaaS	DS	1
HLPaaT	DS	1
HLPaaU	DS	1
HLPaaV	DS	1
HLPaaW	DS	1
HLPaaX	DS	1
HLPaaY	DS	1
HLPaaZ	DS	1
HLPEntFN	DS	1
HLPQuit	DS	1
HLPFMAct	DS	1
HLPEntHx	DS	1
HLPEntPth	DS	1
HLPEndoSch	DS	1
HLPPDNotes	DS	1
HLPInvdKey	DS	1
HLPProErr1	DS	1
HLPProErr2	DS	1
HLPProErr3	DS	1
HLPProErr4	DS	1
HLPProErr5	DS	1
HLPMLIErr	DS	1
HLPTutor	DS	1

	DEND

****************************************************
*                                                  *
*          Block Buster Main Entry Point           *
*                                                  *
*       Initialize pointers and other defaults     *
*                                                  *
****************************************************

EDITOR	JMP	EDITOR2
TITLE	ASZ	"Block Buster "

EDITOR2	LDA	#<INBUF
	STA	PFXPN
	STA	OPENPN
	LDA	#>INBUF
	STA	PFXPN+1
	STA	OPENPN+1
	LDA	DEVNUM
	STA	UNITNUM
	STA	XUNITNUM
	LDA	#0
	STA	MEMPAGE
	STA	RAMWORKSBANK	;RAMWorks Bank=0
	STA	XBLK	;Exchanged block=0
	STA	XBLK+1
	STA	XMODE	;Exchanged system=ProDOS
	POINT	XPTR;BLKBUF
	LDA	#>BLKBUF+$200
	STA	BUFEND

	LDA	#72
	STA	RESTCLOC+2
	LDA	#80
	STA	SAVCURLOC+2

	LDA	#>EDITOR1	;Set BRK vector to editor
	LDY	#<EDITOR1

	LDX	#$FF
	STX	HLPFLG
	LDA	AALftRt
	STA	JMPAMT

	STA	BRKRTN+1
	STY	BRKRTN
	STX	STACKTOP
	JSR	ClrDirty

*
* Close all open files including Follow and maKefiles
* The RESET vector points here
*

EditInit
EDITOR1	LDA	#0
	STA	CLOSEREF
	STA	XFOLLOW
	STA	MAKFLAG
	STA	FOLLOWREF
	MLI	CLOSE;PCLOSE
	LDA	#$A0
	STA	FILFLG	;hi bit set = reading blocks
	STA	BRKFLAG

*
* Main screen drawing routines.  AA-\ points here
*

REDRAW
	LDA	#$A0
	JSR	$C300

	LDX	#$FF
	TXS
:1	LDA	#0
	STA	Hilitng	;Turn hilighting off

*
* Draw menu outlines, buttons, other screen stuff
*

	PRAT	29;0;TITLE
	LDA	BBVERNUM
	JSR	PVER
	POINT	RWBUF;BLKBUF	;Init buffer
	JSR	OPTS	;Print screen options
	JSR	PRIMSIZE
	JSR	PRASCMOD
	JSR	PrEButtn
	JSR	PRXFOLLOW
	LDA	UNITNUM
	JSR	PRUNIT
	JSR	SETTXT
	LDA	#72
	STA	WNDLFT
	GOTO	4;2
	POINT	PTR;BLKBUF

*
* Draw the buffer on the screen
*

DOSCRN	CTX	HLPFcnKeys	;Basic function list
	PUSH	PTR	;Save original location
	JSR	SetTOS
	STA	PTR+1
	STY	PTR
:1	LDA	#0
	STA	WNDLFT
	JSR	SAVCURLOC
	JSR	PrDirty
	GOTO	0;1
	LDX	#8	;Print 8 lines of 32 bytes
:2	JSR	PRINT32
	LDA	PTR
	CLC
	ADC	#$20
	STA	PTR
	LDA	PTR+1
	ADC	#0
	STA	PTR+1
	DEX
	BNE	:2
	PULL	PTR
	JSR	RESTCLOC
	CTX	HLPFcnKeys

*
* Main loop for processing the editor keystrokes
*

EGETKY	JSR	SAVCURLOC
:ND	JSR	RESTCLOC
	LDA	OPFLAG	;Doing opcodes?
	BEQ	:1	;No
	JSR	PR8OPS
	JMP	:4
:1	JSR	INVBYTE	;Make this byte inverse
:4	LDA	FIRSTFLG
	BNE	:2	;Not first time
	CTX	HLPTitle	;1st time, show title screen
	JSR	CTXHELP	;Show opening screen
	LDA	#$FF
	STA	FIRSTFLG
:2	CTX	HLPFcnKeys
	JSR	EDITKEY
	PHA
	LDA	OPFLAG
	BNE	:3
	JSR	NORMBYTE	;Make the byte normal
:3	LDA	OAPPLE	;Is open apple
	ORA	CAPPLE	;or solid apple
	BPL	:5	;pressed?
	JMP	AplKeys	;Yes, check Apple functions
:5	PLA	;no

*
* Check for Non-Apple keypresses, such as arrows,
* and read prev/next block.
*

CHKKEY	STA	TEMP
	LDX	#$FF
:0	INX
	LDA	NoAplKey,X
	BEQ	:1	;End of list
	CMP	TEMP
	BNE	:0
	TXA
	ASL	;* 2
	TAX
	LDA	NoAplAdr+1,X
	PHA
	LDA	NoAplAdr,X
	PHA
	RTS	;Indirectly jump to function handler
:1	LDX	MAKFLAG	;Are we making a file?
	BEQ	:2	;Nope
	JMP	MAKEKEY	;Yes, check make keys
:2	JSR	BUZZ	;Invalid keypress
	CTX	HLPInvdKey
	JMP	EGETKY

*
* Single key functions and their addresses.
*

NoAplKey	DFB	LFTARO,RTARO,UPARO,DNARO
	ASC	"., "
	DFB	ESC,TAB
	ASC	"?",90,00

NoAplAdr	DA	L-1
	DA	ER-1
	DA	U-1
	DA	EDN-1
	DA	RDNXTBLK-1
	DA	RDPREVBLK-1
	DA	EDIT-1
	DA	QUITIT-1
	DA	TABKey-1
	DA	APLHLP-1
	DA	WRPROT-1		; Control-P
*
* Check for Any Apple functions
*

AplKeys	PLA
	STA	TEMP
	LDX	#$FF
:0	INX
	LDA	APPKEYS,X
	BEQ	:1	;End of list
	CMP	TEMP
	BNE	:0
	TXA
	ASL
	TAX
	LDA	APPCMDS+1,X
	PHA
	LDA	APPCMDS,X
	PHA
	RTS
:1	JMP	CHKKEY

*
* Any Apple function keys and addresses
*

APPKEYS	DFB	UPARO,DNARO,RTARO,LFTARO,TAB
	ASC	"\,.<>ABCDEFGIJKLMNOPQRSTUVWXZ8"00

APPCMDS	DA	BEG-1	;Up - Up x lines
	DA	GOEND-1	;Down - down x lines
	DA	RIGHT16-1	;Right - move right x bytes
	DA	LEFT16-1	;Left - move left x bytes
	DA	BK2HEAD-1	;Back to dir entry start
	DA	REDRAW1-1	;Redraw screen (for messy error)
	DA	BAKBLK-1	;< - Decrement block #
	DA	ADVBLK-1	;> - Increment block #
	DA	BAKBLK2-1	;Shift-< Decr Block hi byte
	DA	ADVBLK2-1	;Shift-> Incr Block hi byte
	DA	DOASCII-1	;A - Change ASCII mode
	DA	SETBLOCK-1	;B - Enter new block #
	DA	KOPY-1	;C - Copy chunk
	DA	OTHERDRV-1	;D - Change to other drive
	DA	ENTRYDSCR-1	;E - Enable entry descriptions
	DA	FOLLOW-1	;F - Follow a file
	DA	GO2BYTE-1	;G - Goto a byte
	DA	INDEXBLK-1	;I - Find Index Block/TS List
	DA	JUMP2-1	;J - Jump to block/data block
	DA	MAKEFILE-1	;K - maKefile from buffer
	DA	LOOK-1	;L - Look for a string
	DA	SETRMODE-1	;M - Set block mode
	DA	CONVNUM-1	;N - Numerical conversions
	DA	OPCODE-1	;O - Opcode list
	DA	P-1	;P - Print the block
	DA	Q-1	;Q - Quit edit mode
	DA	BLKRD-1	;R - Read block
	DA	NEWSLOT-1	;S - New slot
	DA	SETTS-1	;T - Enter new Track/Sector
	DA	UNDO-1	;U - Undo
	DA	PRNTVER-1	;V - Print version
	DA	BLKWR-1	;W - Write a block
	DA	XCHANGE-1	;X - eXchange mode/block
	DA	ZEROBUF-1	;Z - Zero buffer
	DA	Monitor-1	;8 (*) - Enter the Monitor

ClrDirty	LDA	#" "
	BNE	Dirt


SetDirty
	LDA	#"*"
Dirt	STA	DirtyBit

PrDirty
	LDA	CVSAV
	STA	SavCV2
	LDA	CHSAV
	STA	SavCH2
	JSR	SAVCURLOC
	GOTO	2;11
	LDA	DirtyBit
	JSR	COUT
	JSR	RESTCLOC
	LDA	SavCH2
	STA	CHSAV
	LDA	SavCV2
	STA	CVSAV
	RTS

DirtyBit	DS	1
SavCH2	DS	1
SavCV2	DS	1

*
* Function handlers for the non-apple keys
*

********************************
*                              *
*          Left Arrow          *
*                              *
*      Move the cursor Left    *
*           one byte           *
*                              *
********************************

L	JSR	LEFT
	JMP	EGETKY

********************************
*                              *
*          Right Arrow         *
*                              *
*      Move the cursor one     *
*       byte to the right,     *
*      or the length of one    *
*     instruction if opcodes   *
*          are active.         *
*                              *
********************************

ER	LDA	OPFLAG
	BEQ	:1
	LDY	#0
	LDA	(PTR),Y
	TAY
	JSR	INSDS2
	LDX	LENGTH
	INX
	JMP	RIGHTN
:1	JSR	RIGHT
	JMP	EGETKY

********************************
*                              *
*           Up Arrow           *
*                              *
*      Move the cursor one     *
*            line up           *
*                              *
********************************

U	JSR	EUP
	JMP	EGETKY

********************************
*                              *
*         Down Arrow           *
*                              *
*      Move the cursor one     *
*          line down           *
*                              *
********************************

EDN	JSR	EDOWN
	JMP	EGETKY

********************************
*                              *
*       Question Mark (?)      *
*                              *
*      Toggle the function     *
*      name help along the     *
*       right side of the      *
*            screen.           *
*                              *
********************************

APLHLP	JSR	SWAPHLP
	JMP	EGETKY

********************************
*                              *
*            Tab Key           *
*                              *
*    Toggle the processor's    *
*         M and X flags.       *
*                              *
********************************

TABKey	LDA	OPFLAG
	BEQ	:3
	LDA	IMMSIZE	;If OPS active, then swap IMM size
	CMP	#3
	BNE	:2A
	LDA	#0
	STA	IMMSIZE
	BEQ	:2B
:2A	INC	IMMSIZE
:2B	JSR	PRIMSIZE
	JMP	EGETKY
:3	JMP	GO2HEAD	;else TAB ==> goto dir ent head

********************************
*                              *
*          Escape Key          *
*                              *
*     Check for open files     *
*        and then quit         *
*         Block Buster         *
*                              *
********************************

QUITIT	JSR	SAVCURLOC
	CTX	HLPQuit
	GOTO	0;23
	LDA	XFOLLOW
	BNE	:1	;Don't escape, other was a file
	LDA	FILFLG	;If file active then
	BPL	:1	;Don't escape
	LDA	MAKFLAG	;Check make flag
	BNE	:2	;Making a file, be sure to close first

	GOTO	0;23
	JSR	CLREOL
	JSR	QUITBB
	GOTO	0;23
	JSR	CLREOL
	JSR	RESTCLOC
	CTX	HLPFcnKeys
	JMP	EGETKY

:1	LDA	MAKFLAG
	BNE	:Both	;Both Follow & Make active
:FolOnly	JSR	BUZZ
	PRINT	FolAct
	JMP	:3
:2	LDA	FILFLG
	BPL	:Both	;Again, both active
:MakOnly	JSR	BUZZ
	PRINT	MakAct
	JMP	:3
:Both	JSR	BUZZ
	PRINT	BothAct
:3	JSR	CLREOL
	CTX	HLPFMAct
	JSR	ERROR1
	GOTO	0;23
	JSR	CLREOL
	JSR	RESTCLOC
	LDA	MAKFLAG	;If makefile active
	BEQ	:4
	JSR	MAKSTATS	;then update statistics
:4	JMP	EGETKY

P	JMP	PRNTSCRN

Q	LDX	FILFLG	;Hi bit clear if doing file
	BMI	:1
	TXA
	EOR	#$80
	STA	FILFLG
	JSR	PRNONE
:1	JMP	EGETKY

REDRAW1	LDA	#$FF
	STA	HLPFLG
	JMP	REDRAW

Monitor	LDA	#$8D
	JSR	$C300
	PRINT	MonTxt
	JMP	MONITOR

MonTxt	ACR	"Entering the Apple Monitor."
	ACR	"Type <Control-Y> <Return> to"
	ASZ	"return to Block Buster."8D

SetTOS	LDA	OURCV
	SEC
	SBC	#2
	ASL
	ASL
	ASL
	ASL
	ASL
	STA	TEMP
	LDA	PTR
	AND	#$E0
	SEC
	SBC	TEMP
	TAY
	LDA	PTR+1
	SBC	#0
	RTS

EDITKEY	JSR	PRNTLOC	;Print where we are
	LDA	OURCH	;Save cursor location
	PHA
	LDA	OURCV
	PHA
	LDA	CV	;Move cursor to ASCII block
	CLC
	ADC	#11
	JSR	SETCV
	JSR	MYKEYIN	;and get a key
	CMP	#$E0
	BCC	:1
	AND	#%11011111	;convert to upper case
:1	STA	XSAV	;Strange huh? But we know
	PLA
	JSR	SETCV
	PLA
	JSR	SETCH
	LDA	XSAV	;that XSAV is trashed from MYKEYIN
	RTS

SWAPHLP	JSR	SAVCURLOC
	JSR	SAVEWIN
	GOTO	72;5
	LDA	#72
	STA	WNDLFT
	LDA	HLPFLG
	BEQ	:1	;A-N, switch to O-Z
	BPL	:0	;Pos, make must be active. Do 1st set
	LDA	MAKFLAG
	BEQ	:0
	PRINT	MAKPARMS
	LDA	#$7F
	BNE	:2
:0	PRINT	APS1
	LDA	#0
	BEQ	:2	;Always
:1	PRINT	APS2
	LDA	#$FF
	BNE	:2
:2	STA	HLPFLG
	JSR	RESTWIN
	JSR	RESTCLOC
	RTS

RDPREVBLK
	LDA	OSTYPE
	BEQ	:1	;Reading blocks
	CMP	#2
	BEQ	:MEM
	CMP	#3
	BEQ	:1	;Pascal
	CMP	#4
	BEQ	:CPM
	LDA	TRACK
	ORA	SECTOR
	BEQ	:4
	DEC	SECTOR
	LDA	SECTOR
	CMP	#$FF
	BNE	:0
	LDA	#$F
	STA	SECTOR
	DEC	TRACK
:0	JMP	BLKRD
:CPM	LDA	BIGBLOCK
	ORA	BIGBLOCK+1
	BEQ	:4
	LDA	BIGBLOCK
	SEC
	SBC	#1
	STA	BIGBLOCK
	BCS	:0
	DEC	BIGBLOCK+1
	JMP	BLKRD
:MEM	LDA	MEMPAGE+1
	BNE	:5
	DEC	RAMWORKSBANK
:5	DEC	MEMPAGE+1
	JMP	BLKRD
:1	LDA	BLOCK
	ORA	BLOCK+1
	BEQ	:4
	LDA	BLOCK
	BNE	:2
	DEC	BLOCK+1
:2	DEC	BLOCK
:3	JMP	BLKRD
:4	JMP	EGETKY

SETFILPOSN
	LDA	#0
	STA	FIMARK
	LDA	BLOCK
	ASL
	STA	FIMARK+1
	LDA	BLOCK+1
	ROL
	STA	FIMARK+2
	MLI	SETMARK;PGSMARK
	RTS

BEG	LDA	CAPPLE
	BMI	:3
	LDX	AAUpDn
:1	JSR	EUP
	DEX
	BNE	:1
	JMP	EGETKY
:3	JSR	SetTOS
	CMP	#>BLKBUF
	BNE	:3a
	CPY	#0
	BNE	:3a
	LDX	#1
	BNE	:1
:3a	LDX	OURCV
	DEX
	STX	:6
:4	JSR	EUP
	DEX
	BNE	:4
	LDX	:6
	DEX
	BEQ	:7
:5	JSR	EDOWN
	DEX
	BNE	:5
:7	JMP	EGETKY
:6	DS	1

GOEND	LDA	CAPPLE
	BMI	:3
	LDX	AAUpDn	;Move cursor down x lines
:1	JSR	EDOWN
	DEX
	BNE	:1
	JMP	EGETKY
:2a	LDX	#1
	BNE	:1	;Always
:3	JSR	SetTOS
	CLC
	ADC	#1
	CMP	BUFEND
	BEQ	:2a
:3a	LDA	#10
	SEC
	SBC	OURCV
	TAX
	STX	:6
:4	JSR	EDOWN
	DEX
	BNE	:4
	LDX	:6
	DEX
:5	JSR	EUP
	DEX
	BNE	:5
	JMP	EGETKY
:6	DS	1

*
* Print entry descriptions if ENTFLG is non-zero
*

ENTRYDSCR	LDA	ENTFLG
	BEQ	:1
	LDA	#0
	BEQ	:2
:1	LDA	#$FF
:2	STA	ENTFLG
	JSR	PrEButtn
	JMP	EGETKY

PrEButtn	LDA	ENTFLG
	BNE	:1
	LDA	AALftRt
	STA	JMPAMT
	LDA	#" "
	JMP	:2
:1	JSR	SETJMPAMT	;Set AA-arrow length
	LDA	#"E"
:2	PHA
	JSR	SAVCURLOC
	GOTO	72;20
	PLA
	JSR	COUT
	JSR	RESTCLOC
	RTS

BLKWR
	CTX	HLPaaW
	LDA	WPFlag
	BEQ	:W
	JSR	BUZZ
	JSR	SAVCURLOC
	GOTO	0;23
	PRINT	WPText
	JSR	MYKEYIN
	GOTO	0;23
	JSR	CLREOL
	JSR	RESTCLOC
	JMP	EGETKY

:W	JSR	WRITEBLK
	BCC	:1
	JSR	EDITERR
:1	CMP	#1
	BEQ	:2
	JSR	ClrDirty
:2	JMP	EGETKY

WPText	ASZ	"Write Protected!!!!"

WRITEBLK
	CTX	HLPaaW
	JSR	SAVCURLOC
	GOTO	38;23
	JSR	CLREOL
	PRINT	AYS	;Are you sure? (y/n)
	JSR	YESNO
	PHA
	GOTO	38;23
	JSR	CLREOL
	JSR	RESTCLOC
	PLA
	BEQ	:0A
	CMP	#2
	BEQ	:0	;Yes
:0A	CLC
	RTS
:0
:0F	LDA	OSTYPE
	STA	WRMODE
	LDA	FILFLG
	BPL	WRFIL	;Following a file
	LDA	OSTYPE
	BEQ	WRBLK2	;ProDOS
	CMP	#3
	BEQ	WRBLK2	;Pascal
	CMP	#2
	BEQ	WRMEM	;Memory
	CMP	#1
	BEQ	:DOS	;DOS 3.3
	JMP	WRCPMB	;CP/M
:DOS	LDA	TRACK	;DOS
	STA	WRLOC
	LDA	SECTOR
	STA	WRLOC+1
	JSR	WRSECT
	RTS
WRBLK2	STDB	BLOCK;WRLOC
	WRBLK
:ERR	RTS
WRFIL	LDA	FOLLOWREF
	STA	MARKREF
	STA	READREF
	STA	WRITEREF
	JSR	SETFILPOSN
	BCS	:3
	STDB	LASTRDLEN;WRITELEN
	STDB	READBUF;WRITEBUF
	MLI	WRITE;PWRITE
:3	RTS
WRMEM	LDA	MyMachId
	CMP	#12
	BCC	EMEM	;Not at least a GS
	JMP	GSWRITE	;Read 16 bit memory
EMEM	LDY	#0
	STY	MEMPAGE
	LDA	RWBUF+1
	STA	:M1+2
	STA	:ZP+2
	LDA	MEMPAGE+1
	STA	WRLOC
	LDA	RAMWORKSBANK
	STA	WRLOC+1
	BNE	:WriteAux
	LDA	MEMPAGE+1	;Write main memory
	CMP	#2
	BCC	:1	;AltZP
	CMP	#$C0
	BCC	:1	;Main 48
	LDY	$C083	;Assume D0 bank 0
	LDY	$C083
	CMP	#$D0
	BCS	:1	;AltZP
	ADC	#$10
	LDY	$C08B	;D0 bank 1
	LDY	$C08B
:1	LDY	#0
	STA	:WZP+2
:M1	LDA	$FF00,Y
:WZP	STA	$FF00,Y
	INY
	BNE	:M1
	STA	$C081
	CLC
	RTS

:WriteAux	LDA	MEMPAGE+1
	CMP	#2
	BCC	:Z
	CMP	#$C0
	BCC	:MAIN48
	LDY	$C083
	LDY	$C083	;Assume D0 bank 0
	CMP	#$D0
	BCS	:Z
	ADC	#$10
	LDY	$C08B
	LDY	$C08B	;D0 bank 1
:Z	LDY	#0
	STA	:WZPA+2
	LDX	RAMWORKSBANK
	BEQ	:ZP
	DEX
	STX	$C073
	STA	ALTZPON
:ZP	LDA	$FF00,Y
:WZPA	STA	$FF00,Y
	INY
	BNE	:ZP
	STA	$C081
	STA	ALTZPOFF
	BEQ	:EXIT	;Always
:MAIN48	LDA	#>BLKBUF
	STA	A1H
	STA	A2H
	STY	A1L
	STY	A4L
	DEY
	STY	A2L
	LDA	MEMPAGE+1
	STA	A4H
	SEC
	STA	STORE80OFF
	LDX	RAMWORKSBANK
	DEX
	STX	$C073
	JSR	AUXMOVE
	STA	STORE80ON
:EXIT	LDA	#0
	STA	$C073
	CLC
	RTS
WRCPMB	STDB	BIGBLOCK;WRLOC
	JSR	WRBBLK	;Write the CP/M Big Block
	RTS

GSWRITE	LDA	RAMWORKSBANK
	STA	:Dest+3
	LDA	RWBUF+1
	STA	:Src+2
	LDA	MEMPAGE+1
	STA	:Dest+2
	SEI
	LDX	#0
:Src	LDA	$FF00,X
:Dest	HEX	9F000000	;STA $000000,X
	INX
	BNE	:Src
	CLI
	CLC
	RTS

ADVBLK	JSR	INCRBLK
	BCS	:1
	JSR	PRBLKNUM
	JMP	EGETKY
:1	JSR	EDITERR
	JMP	EGETKY

ADVBLK2	LDA	OSTYPE
	BEQ	:PD
	CMP	#3
	BEQ	:PD	;Pascal
	CMP	#2
	BEQ	:MEM
	CMP	#4
	BEQ	:CPM
	INC	TRACK
:1	JSR	PRBLKNUM
	JMP	EGETKY
:PD	INC	BLOCK+1
	JMP	:1
:MEM	INC	RAMWORKSBANK
	JMP	:1
:CPM	INC	BIGBLOCK+1
	JMP	:1

INCRBLK	LDA	OSTYPE
	BEQ	:PD
	CMP	#3
	BEQ	:PD	;Pascal
	CMP	#2
	BEQ	:MEM
	CMP	#4
	BEQ	:CPM
	INC	SECTOR
	LDA	SECTOR
	CMP	#$10
	BNE	:2
	LDA	#0
	STA	SECTOR
	INC	TRACK
	CLC
	RTS
:PD	INCW	BLOCK
:2	LDA	FILFLG
	BMI	:4
	JSR	SETFILPOSN
	BCC	:3
	STA	EOFLAG
	JSR	DECRBLK
:3	RTS
:MEM	INC	MEMPAGE+1
	BNE	:2
	INC	RAMWORKSBANK
	JMP	:2
:CPM	INCW	BIGBLOCK
:4	CLC
	RTS

OTHERDRV	LDA	FILFLG
	BMI	:1
	JSR	BUZZ	;Can't change drive if file active
	CTX	HLPWhileF
	JMP	EGETKY
:1	LDX	#"2"	;Just switch to other drive
	LDA	UNITNUM
	EOR	#$80	;Flip hi bit
	STA	UNITNUM	;Save new number
	BMI	:2	;If neg (i.e. drive 2 then skip)
	DEX	;Say drive 1
:2	STX	$408	;Screen location for drive number
	JMP	EGETKY


PRUNIT	PHA
	JSR	SAVCURLOC
	GOTO	0;0
	LDX	#29
	JSR	PRBL2
	LDA	FILFLG
	BMI	:UNIT
	PLA	;File active
	PRAT	0;0;FILMOD
	LDX	#0
	LDA	PNAME
	CMP	#22
	BCC	:A
	BEQ	:A
	SBC	#19
	TAX
	LDA	#"."
	JSR	COUT
	JSR	COUT
	JSR	COUT
:A	LDA	PNAME+1,X
	ORA	#$80
	JSR	COUT
	INX
	CPX	PNAME
	BNE	:A	;Always
	BEQ	:R

:UNIT	PRAT	0;0;UNITTXT
	PLA
	PHA
	LSR
	LSR
	LSR
	LSR
	AND	#$7
	ORA	#$B0
	JSR	COUT
	PRINT	UNITTXT2
	LDX	#"1"
	PLA
	BMI	:1
	HEX	2C
:1	LDX	#"2"
	TXA
	JSR	COUT	;Print drive
:R	JSR	RESTCLOC
	RTS

*
* Set block read/write mode
* 0=ProDOS, 1=DOS 3.3, 2=Memory
* 3=Pascal, 4=CP/M
*

SETRMODE	CTX	HLPaaM
	LDA	FILFLG
	BMI	:0
	JSR	BUZZ	;Can't change file mode if
	CTX	HLPWhileF
	JMP	EGETKY	; file active
:0	JSR	SAVCURLOC
	JSR	CLEAR23
	PRINT	OSM
	POINT	CHPTR;OPSYS
	LDX	OSTYPE
	INX
	JSR	CHOOSE
	BEQ	:3
:1	TAX
	DEX
	STX	OSTYPE
:3	JSR	CLEAR23
	JSR	RESTCLOC
	JSR	SETMODE2
	JSR	PRBLKNUM
	JMP	EGETKY

SETMODE2	LDA	OSTYPE
	BEQ	:PD	;ProDOS blocks
:1	CMP	#1
	BEQ	:DOS	;DOS 3.3 Track/Sectors
	CMP	#2
	BEQ	:MEM	;Do memory block
	CMP	#3
	BEQ	:1A
	JMP	:CPM
:1A	JMP	:PAS
:PD	JSR	SAVCURLOC
	GOTO	72;4
	LDX	#0
:2	LDA	BLKNAM,X
	JSR	COUT
	INX
	CPX	#4
	BNE	:2
	LDA	#>BLKBUF+$200
	STA	BUFEND
	JMP	:EXIT
:DOS	JSR	SAVCURLOC	;DOS 3.3
	PRAT	72;4;TSBLK
	GOTO	74;4
	LDA	TRACK
	JSR	PRBYT
	GOTO	79;4
	LDA	SECTOR
	AND	#$F
	JSR	PRHEX
	JSR	RDVTOC
	LDA	VTOCBUF+$34
	STA	FIAUX	;Tracks per disk
	LDA	VTOCBUF+$35
	STA	FIAUX+1	;Sectors per track
	LDA	#>BLKBUF+$100
	STA	BUFEND
	JMP	:EXIT
:MEM	JSR	SAVCURLOC	;Memory
	PRAT	72;4;MEMBLK
	LDA	RAMWORKSBANK
	JSR	PRBYT
	LDA	MEMPAGE+1
	JSR	PRBYT
	LDA	#>BLKBUF+$100
	STA	BUFEND
	JMP	:EXIT
:PAS	JSR	SAVCURLOC	;Pascal
	PRAT	72;4;PASBLK
	LDA	#>BLKBUF+$200
	STA	BUFEND
	JMP	:EXIT
:CPM	JSR	SAVCURLOC	;CP/M
	PRAT	72;4;CPMBLK
	LDA	#>BLKBUF+$400
	STA	BUFEND
:EXIT	GOTO	73;20
	LDA	#$A0
	JSR	COUT
	JSR	RESTCLOC
	JSR	SETJMPAMT
	RTS

SETJMPAMT
	LDX	OSTYPE
	LDA	:JMPAMT,X
	STA	JMPAMT
	RTS

* 0=ProDOS  1=DOS  2=Memory  3=Pascal  4=CP/M
* Directory entry lengths

:JMPAMT	DFB	39,35,16,26,32

PVER	STA	:SAVE
	LSR
	LSR
	LSR
	LSR
	ORA	#"0"
	JSR	COUT
	LDA	#"."
	JSR	COUT
	LDA	:SAVE
	AND	#$F
	ORA	#"0"
	JSR	COUT
	RTS
:SAVE	DFB	1

PRNTVER	CTX	HLPaaV
	JSR	SAVCURLOC	;Save cursor location
	GOTO	0;23
	JSR	CLREOL
	PRINT	BBVER
	LDA	BBVERNUM
	JSR	PVER
	LDA	#" "
	JSR	COUT
	JSR	COUT
	PRINT	BBVER2
	PRINT	BBTAG
	LDX	#4
	JSR	PRBL2
	PRINT	VER	;Set cursor and print version txt
	PRINT	VER1	;Print Version/Minimum Version
	JSR	ZERONUM	;Zero work area
	LDA	#":"	;Print ": "
	JSR	COUT
	LDA	#$A0
	JSR	COUT
	LDY	#8
	LDA	KVERSION	;Get this version of the kernel
	STA	NUM
	JSR	COPYNUM
	JSR	HEX2DEC	;Convert it to decimal
	JSR	DECPRNT	;and print it
	LDA	#"/"
	JSR	COUT
	JSR	ZERONUM	;Zero work area
	LDY	#8
	LDA	KMINVER	;Get minimum kernel version
	STA	NUM
	JSR	COPYNUM
	JSR	HEX2DEC	;Convert it to decimal
	JSR	DECPRNT	;and print it
	JSR	CLREOL
	LDA	#$A0
	JSR	COUT
	JSR	MYKEYIN
	GOTO	0;23	;Move cursor to start of line
	JSR	CLREOL	;and clear it
	JSR	RESTCLOC	;Restore cursor location
	JMP	EGETKY	;and return

WRPROT	JSR	SAVCURLOC
	GOTO	0;11
	LDA	WPFlag
	BNE	:WrEn	;Write enable
	LDA	#$FF
	STA	WPFlag
	LDA	#"W"
	JSR	COUT
	LDA	#"P"
	BNE	:1	;Always
:WrEn	LDA	#0
	STA	WPFlag
	LDA	#" "
	JSR	COUT
:1	JSR	COUT
:WPExit	JSR	RESTCLOC
	JMP	EGETKY
