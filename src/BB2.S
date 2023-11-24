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
	LST	OFF
********************************
*                              *
*          File: BB.S          *
*                              *
*           Contents           *
*           --------           *
* - Main Code                  *
* - Defines                    *
* - Initialization             *
* - Reloacation                *
* - Help File Setup            *
*                              *
********************************
	EXP	OFF

* Must be a double 'Y' label as Merlin32 accepts
* a single 'Y' as a valid label, preventing any
* Y-Register based instructions from compiling.

YY	=	1
yy	=	1

ASMEDIT	=	YY

LISTING	=	0

	DO	LISTING
	LST	ON
	FIN

*
* General pointers and temporary storage
*

IBPTR	=	$00	;Pointer to index block list
DIRPTR	=	$04	;Pointer to directory block list
COUNT	=	$0D	;# of files in current directory
CMDNUM	=	$11	;Holds number of current command
PTR2	=	$1D	;Another all purpose pointer
TEMP	=	$AF	;Some temporary space
TEMP1	=	$63
TEMP2	=	$64
TEMP3	=	$65
TEMP4	=	$66
RBUFPTR	=	$67
PTR	=	$69
TEMPPTR	=	$6B
CHSAV	=	$6D	;Save area for CH
CVSAV	=	$6E	;  "   "    "  CV
AMTSAV	=	$70
TXTPTR	=	$71
LimitLen	=	$72
GSTRSAVA	=	$73
GSTRSAVY	=	$74
GSTRSAVX	=	$75
GSTRTYPE	=	$76	;"%"=Bin, "$"=Hex, digit=Dec
GSTRMODE	=	$77	;0=Numeric, non-zero=Anything

WORKAREA	=	$95	;Math work area
MPYR	=	$9B
SETV	=	$9C	;Used in BIT to set V-flag
XSAV	=	$9D	;Register save areas
YSAV	=	$9E
ASAV	=	$9F
STRPTR	=	$A9
MASK	=	$AD
SCOUNT	=	$AE
FNAMES	=	$B3
LOMEM	=	$B5	;Lowest free page
HIMEM	=	$B6	;Highest free page
MEMPAGE	=	$B7	;2 bytes
RAMWORKSBANK	=	$B9	;Holds RamWorks bank or 64k bank of the 65816
MAXCH	=	$BB
CHPTR	=	$BC	;2 bytes
CURRENT	=	$BE
ZVAL	=	$CA
PPARMS	=	$CB	;16 bytes
PARMCNT	=	$DB
PARMPTR	=	$DC	;2 bytes
SRCBASL	=	$E2	;2 bytes
DESTBASL	=	$E4	;2 bytes
BUFEND	=	$E6
NUM	=	$F3	;4 bytes
YTEMP	=	$F7
PATPTR	=	$FD	;2 bytes
SAVBUF	=	$74

* Keyboard values for various special keys

RTARO	=	$95
LFTARO	=	$88
DNARO	=	$8A
UPARO	=	$8B
RTN	=	$8D
ESC	=	$9B
TAB	=	$89
CTRLW	=	$97

MkUnCnt	=	$0003	;Make Undo Write count

DivLine	=	59

TopLeftX	=	PPARMS+1
TopLeftY	=	PPARMS+2
BotRtX	=	PPARMS+3
BotRtY	=	PPARMS+4

*
* System fixed addresses and other constants
*

STACK	=	$100
INBUF	=	$220	;GETLN input buffer
PNAME	=	$240	;Pathname address
PNAME2	=	$280	;Rename pathname
PFXADR	=	$2C0	;SET PREFIX prefix address
SBUF	=	$300	;Search buffer
HLPStats	=	$370	;Help Stats (1st 8 bytes of .IDX)
CTXPARMS	=	$378	;Help Index parms
LNBUF	=	$380	;Catalog line & blk search buffer
BRKVECT	=	$3F0	;To trap errors
RESETEV	=	$3F2	;Reset vector
CTRLY	=	$3F8	;Control-Y vector
OURCH	=	$57B	;80 col CH value
OURCV	=	$5FB	;80 col CV value

CTXADR	=	CTXPARMS	;File position of this context
CTXROW	=	CTXPARMS+2	;Rows in this screen
CTXCOL	=	CTXPARMS+3	;Columns in this screen
CTXLEN	=	CTXPARMS+4	;Length of this context
CTXX	=	CTXPARMS+6	;X location of help window (supplied)
CTXY	=	CTXPARMS+7	;Y location of help window (supplied)

START	=	$800	;Final resting place

*
* Buffers start at the top of memory
* and work their way down.
* (probably should start buffers
*  at $800 and build up at some point)
*

* Subtract out the total buffer size

	DUM	$BF00-$2C00
	TR	ON

FREETOP	=	*

* Name         Size        Effective Address

HIDXBUF	DS	$400	;$9300
HLPBUF2	DS	$800	;$9700
UNDOWR	DS	$400	;$9F00
CLIPBRD	DS	$400	;$A700
BLKBUF	DS	$400	;$A700
BLKBUF2	DS	$400	;$AB00
HLPBUF	DS	$400	;$AF00
SECBUF	DS	$400	;$B300
TSBUF	DS	$200	;$B700
PRIBUF	DS	$400	;$B900
OLLIST	DS	$100	;$BD00
VTOCBUF	DS	$100	;$BE00

* Trip an error if we don't end
* at exactly $BEFF.

	ERR	*-$BF00

	TR	OFF
	DEND

;FREETOP = SECBUF

DIRBUF	=	SECBUF-$1000
NXTDIRBLK	=	SECBUF+2	;Offset to next block pointer
FILECNT	=	SECBUF+$25	;Offset to file count


*
* Monitor Reserved Zero Page Locations
*

WNDLFT	=	$20
WNDWDTH	=	$21
WNDTOP	=	$22
WNDBTM	=	$23
CH	=	$24
CV	=	$25
BASL	=	$28
LMNEM	=	$2C
RMNEM	=	$2D
FORMATL	=	$2E
LENGTH	=	$2F
FORMATH	=	$30
CSW	=	$36
PCL	=	$3A
PCH	=	$3B
A1L	=	$3C
A1H	=	$3D
A2L	=	$3E
A2H	=	$3F
A4L	=	$42
A4H	=	$43

*
* Disk driver reserved locations
*

DRVRCMD	=	$42	;Command (read, write, etc.)
DRVRUNIT	=	$43	;Unit number
DRVRBUF	=	$44	;Buffer to read from/write to
DRVRBLK	=	$46	;Block # to read/write


*
* KERNEL Stuff
*

CALLMLI	=	$BF00	;Kernel entry point
ERRNO	=	$BF0F
DEVADTBL	=	$BF10	;Device address table
DEVNUM	=	$BF30	;Last device used
DEVCNT	=	$BF31	;Count -1 of active devices
DATE	=	$BF90	;Current date
TIME	=	$BF92	;Current time
KMINVER	=	$BFFE	;Minimum compatible Kernel version
KVERSION	=	$BFFF	;Version of this Kernel
FCB	=	$D800	;ProDOS Kernel Version 1.0

*
* Softswitches & Monitor Equates
*

KBD	=	$C000	;Read keyboard
STORE80OFF	=	$C000	;Store main page
STORE80ON	=	$C001	;Store aux page
RAMRDOFF	=	$C002	;Read main 48k
RAMRDON	=	$C003	;Read aux 48k
RAMWRTOFF	=	$C004	;Write main 48k
RAMWRTON	=	$C005	;Write aux 48k
SETINTCX	=	$C007	;Enable $CX00 firmware
ALTZPOFF	=	$C008	;Main Stack, ZP & LC
ALTZPON	=	$C009	;Aux Stack, ZP & LC
STDCHARSET	=	$C00E	;Standard char set
ALTCHARSET	=	$C00F	;Alternate char set
STRB	=	$C010	;Reset keyboard
RAMRD	=	$C013	;Read RAMRD swtich
RAMWR	=	$C014	;Read RAMWR switch
ALTZP	=	$C016	;Read ALTZP switch
STORE80	=	$C018	;Read 80STORE switch
PAGE2	=	$C01C	;Read PAGE2 switch
RD80VID	=	$C01F	;Read 40/80 col switch
SPKR	=	$C030	;Click speaker
TXTPAGE1	=	$C054	;Select Text Page 1
TXTPAGE2	=	$C055	;Select Text Page 2
PAGE2OFF	=	$C054	;Read from main text page
PAGE2ON	=	$C055	;Read from aux text page
OAPPLE	=	$C061	;Open Apple
CAPPLE	=	$C062	;Closed Apple
BANKNUM	=	$C073	;RAMWorks Bank #
RDROM	=	$C081	;RD ROM; WR RAM; LC $D0 Bank 2
RDROM2	=	$C082	;RD ROM; no write; LC $D0 Bank 2
RDRAM	=	$C083	;R/W RAM, LC $D0 Bank 2
RWLCBK2	=	$C08B	;R/W RAM; LC $D0 Bank 1


*
* 80-col Firmware Routines
*

AUXMOVE	=	$C311

*
* Monitor ROM Routines
*

RELADR	=	$F938
PRNTAX	=	$F941
PRBL2	=	$F94A
PCADJ	=	$F953
SETTXT	=	$FB39
TABV	=	$FB5B
BASCALC	=	$FBC1
VTAB	=	$FC22
CLREOP	=	$FC42
HOME	=	$FC58
CLREOL	=	$FC9C
WAIT	=	$FCA8
CROUT	=	$FD8E
PRHEX	=	$FDE3
PRBYT	=	$FDDA
COUT	=	$FDED
MOVE	=	$FE2C	;A1.A2 --> A4
SETINV	=	$FE80
SETNORM	=	$FE84
OUTPORT	=	$FE95

MONITOR	=	$FF69

*
* MLI Command Numbers
*

ALLOCINT	=	$40
DALLOCINT	=	$41
QUIT	=	$65
READBLOCK	=	$80
WRITEBLOCK	=	$81
GETTIME	=	$82
CREATE	=	$C0
DESTROY	=	$C1
RENAME	=	$C2
SFILINFO	=	$C3
GFILINFO	=	$C4
ONLINE	=	$C5
SETPFX	=	$C6
GETPFX	=	$C7
OPEN	=	$C8
NEWLINE	=	$C9
READ	=	$CA
WRITE	=	$CB
CLOSE	=	$CC
FLUSH	=	$CD
SETMARK	=	$CE
GETMARK	=	$CF
SETEOF	=	$D0
GETEOF	=	$D1
SETBUF	=	$DF
GETBUF	=	$D3

WinBuf	=	$FE
WPTR	=	$FC

ENUM_START	MAC
	TR	ON
	DUM	]1
]INCR	=	]2
	<<<

ENUM_END	MAC
	DEND
	<<<

ENUM	MAC
	DS	]INCR
	<<<


CTX	MAC	;Context help macro
	LDA	#]1
	STA	MYCTX
	<<<

BOX	MAC	;X,Y,W,H
	JSR	BOXIT
	DFB	#]1,#]2,#]3,#]4
	<<<

WIN	MAC	;fmt,X,Y,W,H
	JSR	NEWWIN
	DFB	]1,]2,]3,]2+]4,]3+]5
	<<<

SAVBOX	MAC
	JSR	WSTUFF
	DFB	1,]1,]2,]1+]3,]2+]4
	<<<

RESBOX	MAC
	JSR	WSTUFF
	DFB	2,]1,]2,]1+]3,]2+]4
	<<<

CLBOX	MAC
	JSR	WSTUFF
	DFB	3,]1,]2,]1+]3,]2+]4
	<<<

WSIZE	MAC	;Set window size
	LDA	#]1
	STA	WNDLFT
	LDA	#]2
	STA	WNDWDTH
	<<<

FTP	MAC	;Hex filetype code
	HEX	]1	;and 3 letter ascii code
	ASC	]2
	<<<

ASZ	MAC	;ASC terminated w/00
	ASC	]1
	HEX	00
	<<<

ACR	MAC	;ASC terminated w/8D
	ASC	]1
	HEX	8D
	<<<

ACZ	MAC	;ASC terminated w/ 8D00
	ASC	]1
	HEX	8D00
	<<<

PUSH	MAC	;Push address on the stack
	LDA	]1+1
	PHA
	LDA	]1
	PHA
	<<<

PULL	MAC	;Pull an address off the stack
	PLA
	STA	]1
	PLA
	STA	]1+1
	<<<

POP	MAC
	PLA
	PLA
	<<<

POINT	MAC	;Set a pointer
	LDA	#<]2
	STA	]1
	LDA	#>]2
	STA	]1+1
	<<<

STDB	MAC	;Store double byte
	LDA	]1
	STA	]2
	LDA	]1+1
	STA	]2+1
	<<<

CMPW	MAC
	LDA	]1
	CMP	]2
	LDA	]1+1
	SBC	]2+1
	<<<

INCW	MAC
	INC	]1
	BNE	NC
	INC	]1+1
NC
	<<<

DECW	MAC
	LDA	]1
	BNE	NC
	DEC	]1+1
NC	DEC	]1
	<<<

MOVMEM	MAC
	LDA	#<]1	;Set source ptr
	STA	$3C
	LDA	#>]1
	STA	$3D
	LDA	#<]2	;end of source ptr
	STA	$3E
	LDA	#>]2
	STA	$3F
	LDA	#<]3	;Destination
	STA	$42
	LDA	#>]3
	STA	$43
	LDY	#0
	JSR	MOVE
	<<<

MLI	MAC	;Call MLI
	JSR	CALLMLI
	DFB	]1
	DA	]2
	<<<

RWBLK	MAC	;Read/Write a block
	MLI	]1;PRWBLK
	<<<

RDBLK	MAC	;Read a block
	RWBLK	$80
	<<<

WRBLK	MAC	;Write a block
	RWBLK	$81
	<<<

PRINT	MAC
	JSR	PRTXT
	DA	]1
	<<<

GOTO	MAC	;Tab to x,y
	JSR	GOTOXY
	DFB	#]1,#]2
	<<<

PushCursor	MAC
	LDA	OURCH
	PHA
	LDA	OURCV
	PHA
	<<<

PopCursor	MAC
	PLA
	JSR	SETCV
	PLA
	JSR	SETCH
	<<<

PRAT	MAC	;Print at x,y
	JSR	PRNTAT
	DFB	#<]3,#>]3,]1,]2
	<<<

COUTX	MAC
	JSR	COUT2
	DFB	#]1,#]2
	<<<

DLINE	MAC	;X,Y;L
	IF	H,]1
	JSR	LINEIT
	ELSE
	JSR	VLINE
	FIN
	DFB	#]2,#]3,#]4,#]5
	<<<

ON	MAC
	DA	']1'-64*32+']2'-64*32+']3'-64*2
	<<<

OXA	MAC
	DFB	#<]1-OPNAMESA/2+128
	<<<

OXB	MAC
	DFB	#<]1-OPNAMESB/2
	<<<

	TYP	$FF	;Say SYStem file
	;M32  OBJ $BFE0
	ORG	$2000

	DSK	BB2.SYSTEM

	JMP	MOVIT
CODESTART
	ORG	START

	PUT	BB2.DEFS


PROGSTART
	PUT	EDITA
	PUT	EDITB
	PUT	EDITC
	PUT	EDITD
	PUT	EDITE
	PUT	EDITF

	PUT	COMMON.1
	PUT	COMMON.2

STRTTRK
ENDTRK	DS	2

	DS	\

WSAVBUF	=	*

ENDOFCODE
	ORG
CODEEND

MOVIT
	JSR	$C300
	LDA	#0
	STA	FNAMES
	LDX	#$17
:0	STA	$BF58,X
	DEX
	BPL	:0
	LDA	#%11001111
	STA	$BF58
	LDA	#1
	STA	$BF58+$17

:1A	MOVMEM	CODESTART;CODEEND;START
	LDY	#0
	STY	CMDNUM	;Init command number
	LDA	DEVNUM	;Set our unit to the last
	STA	UNITNUM	; device used
	LDA	#$60
	STA	SETV	;Used to set overflow in BIT's
	STA	BRKFLAG
	LDA	#0	;Assume old //e
	STA	IDBYTE
	STA	YSAV
	LDA	MyMachId	;If MyMachine is nonzero, then
	BNE	:1	; use that value
	JSR	GetMachine	;else figure out what kind of
	STA	MyMachId	; machine we are in.
:1	CMP	#5
	BCC	:ID	;Still an old machine
	LDA	#$FF	;Got an enhanced //e or better
	STA	IDBYTE
:ID
	LDA	#<EditInit
	LDY	#>EditInit

	STA	CTRLY+1
	STY	CTRLY+2
	STA	RESETEV
	STY	RESETEV+1
	JSR	$FB6F	;Make reset vector valid
	LDA	#$4C
	STA	CTRLY
	STDB	BRKVECT;ORIGBRK
	POINT BRKVECT;MYBRK

*
* Set Help Files location
* 0=boot disk    1=saved path    2=copy to /RAM
*

	LDA	HELPLOC	;Where should Help files be?
	BNE	:00
	JMP	OnBootDev	;Boot disk
:00	CMP	#1
	BNE	Copy2Ram
	JMP	SetMem	;Saved path, so go set memory

Copy2Ram	LDX	RamHelp	;Copy to /RAM
:1	LDA	RamHelp,X	;Copy volume name to
	STA	IDXPN,X	;destination pathname buffers
	STA	HELPPN,X
	DEX
	BPL	:1

	LDX	IDXPN
	LDY	#0
:2	LDA	BBIDX+1,Y
	STA	IDXPN+1,X
	INX
	INY
	CPY	BBIDX
	BNE	:2
	STX	IDXPN

	LDX	HELPPN
	LDY	#0
:3	LDA	BBHLP+1,Y
	STA	HELPPN+1,X
	INX
	INY
	CPY	BBHLP
	BNE	:3
	STX	HELPPN

	LDA	DEVNUM	;Get boot device
	STA	HOLUNIT
	POINT	OLBUF;INBUF+1
	MLI	ONLINE;HONLINE
	BCC	:20
	JMP	OnBootDev	;Error, use boot disk
:20	LDA	INBUF+1	;Copy boot volume name
	AND	#$F	;to the copy buffer
	TAX
	INX
	INX
	STX	INBUF	;Set source
	STX	:VolNmLen	;Save for later
	LDA	#'/'
	STA	INBUF+1
	STA	INBUF,X	;INBUF now holds /{dev}/

*
* Copy index and help file
*

	LDX	:VolNmLen
	LDY	#0
:30	LDA	BBIDX+1,Y
	INX
	STA	INBUF,X
	INY
	CPY	BBIDX
	BNE	:30
	STX	INBUF
	POINT	:PN2;IDXPN
	JSR	:Load
	BCS	:ERRR

	LDX	:VolNmLen

	LDY	#0
:40	LDA	BBHLP+1,Y
	INX
	STA	INBUF,X
	INY
	CPY	BBHLP
	BNE	:40
	STX	INBUF
	POINT	:PN2;HELPPN
	JSR	:Load

	BCS	:ERRR

	JMP	SetMem

:ERRR	JMP	OnBootDev

:Load	POINT	:PN1;INBUF
	POINT	:Buf;COPYBUF
	LDA	#$BD
	CLC
	SBC	#>COPYBUF
	STA	:Len+1
	LDA	#0
	STA	:Len
	LDA	#<:FCB
	LDX	#>:FCB
	JSR	LoadFile
	RTS

:VolNmLen	DS	1

:FCB
:Buf	DS	2
:Len	DS	2
:PN1	DS	2
:PN2	DS	2

*
* Help on Boot Disk
*

OnBootDev	LDA	DEVNUM	;Use device Block Buster ran from
	STA	HOLUNIT
	POINT	OLBUF;INBUF+1
	MLI	ONLINE;HONLINE	;Get name of last device used
	BCS	:10	;Error, say can't find help files
:31	LDA	INBUF+1
	AND	#$F	;Mask length of volume name
	TAX
	INX
	INX
	STX	IDXPN
	LDA	#'/'
	STA	HELPPN+1
	STA	HELPPN,X
	STA	IDXPN+1
	STA	IDXPN,X
:4	DEX	;Build help file
	LDA	INBUF,X	; volume names
	STA	IDXPN,X
	STA	HELPPN,X
	CPX	#2
	BNE	:4

:5	LDX	IDXPN	;Add help file pathname
	LDY	#0	; to the volume name
:6	LDA	BBIDX+1,Y
	STA	IDXPN+1,X
	LDA	BBHLP+1,Y
	STA	HELPPN+1,X
	INX
	INY
	CPY	BBIDX
	BCC	:6
	BEQ	:6
	DEX
	STX	IDXPN
	STX	HELPPN

:10		;Can't find help files

SetMem	LDA	#>FREETOP-$200
	STA	HIMEM
	LDA	#>ENDOFCODE
	STA	LOMEM
	STA	TEMP
	STA	FNAMES+1
:1	DEC	TEMP
	LDA	TEMP
	CMP	#7
	BEQ	:1A
	JSR	MKPAGE
	JMP	:1

:1A	LDA	UNITNUM
	STA	DEVNUM
	LDA	#0
	STA	INBUF
	JMP	PROGSTART	;and go to it

RamHelp	STR	'/RAM/'

HONLINE	HEX	02
HOLUNIT	HEX	00
	DA	INBUF+1	;Buffer

*
* Mark the page as used
*

MKPAGE	PHA
	PHA
	AND	#7
	TAY
	LDX	MARKMASK,Y
	PLA
	LSR
	LSR
	LSR
	TAY
	TXA
	ORA	$BF58,Y
	STA	$BF58,Y
	PLA
	RTS

MARKMASK	HEX	80,40,20,10,08,04,02,01

*
* Adapted from Nibble Magazine 8/90
*

GetMachine
	lda	$c081
	sec
	jsr	$fe1f
	bcs	:old
	bcc	:new
:old	lda	$fbb3
	cmp	#$e8	;Old Apple ][
	bne	:old1
	lda	#1
	rts
:old1	cmp	#$ea	;][+ or III in emulation
	bne	:old2
	lda	$fb1e
	cmp	#$ad
	bne	:old3
	lda	#2	;][+
	rts
:old3	cmp	#$8a
	bne	:bad
	lda	#3	;III in emulation
	rts
:bad	lda	#0
	rts
:old2	cmp	#6
	bne	:bad
	lda	$fbc0
	beq	:c
	cmp	#$ea
	bne	:5
	lda	#4	;Old //e
	rts
:5	cmp	#$e0
	bne	:bad
	lda	#5	;Enhanced //e
	rts
:c	lda	$fbbf
	beq	:c2
	cmp	#$ff
	beq	:c1
	cmp	#3
	beq	:c3
	cmp	#4
	beq	:c4
	cmp	#5
	bne	:bad
	lda	#10	;//c plus
	rts
:c1	lda	#6
	rts
:c2	lda	#7
	rts
:c3	lda	#8
	rts
:c4	lda	#9
	rts

:new	clc
	dfb	$fb	;XCE
	php
	hex	c030	;REP $30
	jsr	$fe1f	;Call ID routine
	sta	:A
	stx	:X
	sty	:Y
	plp
	dfb	$FB	;XCE

	lda	:Y+1
	bne	:newer
	lda	:Y
	beq	:gs0
	cmp	#1
	beq	:gs1
	cmp	#3
	beq	:gs3
	lda	#14
	rts
:gs0	lda	#11
	rts
:gs1	lda	#12
	rts
:gs3	lda	#13
	rts
:newer	lda	#15
	rts

:Y	DS	2
:X	DS	2
:A	DS	2

FCBSize	=	8

LoadFile
	STA	PTR
	STX	PTR+1
	LDY	#FCBSize-1
:1	LDA	(PTR),Y
	STA	LOADFCB,Y
	DEY
	BPL	:1
	LDA	#0
	STA	FirstTime	;Say first time through
	STA	GotAll

RWLoop	LDA	FirstTime
	BNE	:Read	;Not the first time through
	LDA	#7
	STA	PInfo
	LDA	FCBPN1
	STA	OpenPn
	STA	InfoPath
	LDA	FCBPN1+1
	STA	OpenPn+1
	STA	InfoPath+1
	LDA	#$A
	STA	PInfo
	MLI	GFILINFO;PInfo
	BCS	:Err
	LDA	FCBBuf
	STA	OpenBuf
	STA	RdWrBuf
	CLC
	LDA	FCBBuf+1
	STA	OpenBuf+1
	ADC	#8
	STA	RdWrBuf+1
	LDA	FCBLen
	STA	RdWrLen
	SEC
	LDA	FCBLen+1
	SBC	#8
	STA	RdWrLen+1
	MLI	OPEN;POpen
	BCS	:Err
	LDA	OpenRef
	STA	ReadRef
	JMP	:Read

:Err	JMP	LoadErr

:Read	LDA	ReadRef
	STA	RdWrRef
	MLI	READ;PRdWr
	BCC	:10
	CMP	#$4C	;End of File
	BNE	:Err
	STA	GotAll	;Signal that we got it all
:10	LDA	FirstTime
	BNE	:Write
	LDA	FCBPN2
	STA	OpenPn
	STA	InfoPath
	LDA	FCBPN2+1
	STA	OpenPn+1
	STA	InfoPath+1
	CLC
	LDA	FCBBuf
	STA	OpenBuf
	LDA	FCBBuf+1
	ADC	#4
	STA	OpenBuf+1
	LDA	#7
	STA	PInfo
	LDX	#3
:19	LDA	$BF90,X
	STA	PInfo+8,X
	DEX
	BPL	:19
	MLI	CREATE;PInfo
	BCC	:20
	CMP	#$47
	BNE	:Err
	MLI	CLOSE;PClose	;File exists, exit OK
	RTS
:20	MLI	OPEN;POpen
:Err2	BCS	:Err
	LDA	OpenRef
	STA	WriteRef
	STA	FirstTime	;Say not the first time
:Write	LDA	WriteRef
	STA	RdWrRef
	STDB	RdWrAct;RdWrLen
	MLI	WRITE;PRdWr
	BCS	:Err2
	LDA	GotAll
	BNE	Done
	JMP	:Read

Done	MLI	CLOSE;PClose
	BCS	:1
	LDA	#7
	STA	PInfo
	MLI	SFILINFO;PInfo
:1	RTS

LoadErr	PHP
	PHA
; MLI CLOSE;PClose
	BRK

	PLA
	PLP
	RTS

LOADFCB
FCBBuf	DS	2
FCBLen	DS	2
FCBPN1	DS	2
FCBPN2	DS	2

ReadRef	DS	1
WriteRef	DS	1
FirstTime	DS	1
GotAll	DS	1

POpen	HEX	03
OpenPn	DS	2
OpenBuf	DS	2
OpenRef	DS	1

PClose	HEX	0100

* Parameter list for Create, Get_File_Info & Set_File_Info

PInfo	HEX	07
InfoPath	DS	2	;Address of Pathname
InfoAccs	HEX	C3	;Access bits
InfoType	DS	1	;File Type
InfoAux	DS	2	;Auxillary File Type
InfoStor	HEX	01	;Seedling file to start
InfoXtra	DS	10	;Other Stuff

PRdWr	HEX	04
RdWrRef	DS	1
RdWrBuf	DS	2
RdWrLen	DS	2
RdWrAct	DS	2

	LST	OFF

	ds	\

COPYBUF	=	*
