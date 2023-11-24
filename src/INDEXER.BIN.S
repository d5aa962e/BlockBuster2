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
*    File: INDEXER.BIN.S       *
*                              *
*           Contents           *
*           --------           *
* This is the main code for    *
* parsing an AppleWorks file   *
* for use in the Block Buster  *
* Help System.  The routines   *
* here are called from the     *
* Basic program AWP.INDEXER.   *
*                              *
********************************

LASTPTR	=	$60
PTR	=	$62
TXTPTR	=	$64

CALLMLI	=	$BF00
KBD	=	$C000
STRB	=	$C010
COUT	=	$FDED
PRBYT	=	$FDDA

ESC	=	$9B

ONLINE	=	$C5
OPEN	=	$C8
READ	=	$CA
CLOSE	=	$CC
GETMARK	=	$CF

	EXP	OFF
	TR	ON

MLI	MAC	;Call MLI
	JSR	CALLMLI
	DFB	]1
	DA	]2
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

ASZ	MAC
	ASC	]1,00
	<<<

ACZ	MAC	;ASC terminated w/ 8D00
	ASC	]1
	HEX	8D00
	<<<

INCW	MAC
	INC	]1
	BNE	NC
	INC	]1+1
NC
	<<<


	ORG	$4000

* This first section contains fixed code and data
* which is referenced by the AppleSoft Basic
* program.  Do not change anything in this section
* without making the corresponding change to the
* Basic program or the code will break.

	JMP	START

* Main program entry points.

	JMP	GetOnline
	JMP	START	;Placeholder for future
	JMP	START	;Placeholder for future

PRNTON	DFB	1	;Non-zero if echoing

	DA	PNBUF	;Pathname buffer for AWP file
	DA	IDXBUF	;Location to store the indices
	DA	AWPBUF	;AWP Buffer
	DA	OnlineBuf	;Buffer to hold all online volumes

PNBUF	DS	64

****
* End of Static Section
****

* Get all Online volumes and return

GetOnline	MLI	ONLINE;POnline
	RTS

* Main entry point

START	LDA	#1
	STA	PRNTON
	STA	TopicID
	POINT	PTR;IDXBUF+8
	POINT	LASTPTR;IDXBUF
	LDX	#0
	STX	FLAG
	STA	TopicCount
	STA	TitleFlag
	TXA
:1	STA	IDXBUF,X
	STA	IDXBUF+$100,X
	STA	IDXBUF+$200,X
	STA	IDXBUF+$300,X
	INX
	BNE	:1
	POINT	SaveXCoord;$FFFF
	POINT	PrevLoc;0

	MLI	OPEN;POpen
	BCC	:00
	JSR	PRBYT
	LDA	#1
	JSR	PRBYT
	BRK
:00	LDA	OpenRef
	STA	RdWrRef
	STA	CloseRef
	STA	GMarkRef

	POINT	RdWrLen;300
:0	MLI	READ;PRdWr
	BCC	LOOP
ERR	JSR	PRBYT
	LDA	#2
	JSR	PRBYT
	BRK

* Process each line of the AppleWorks word processor
* file. Each line is either a text line or a command
* line.  Parse accordingly.
*
* AppleWorks Word Processor File Format
* Summarized from AppleWorks Technical Note "File
* formats for AppleWorks and ///E-Z Pieces", as
* it pertains to the Block Buster Help System.
*
* 300 byte header
*
* Three "line" types:
*
* 1. Empty Line
* 2. Command Line Records
* 3. Text Records
*
* Empty Lines
*
* Byte     Description
* ====     ==============================
* +000     # of blank spaces before
*           this carriage return (0-79)
* +001     $D0
*
* Command Line Records
*
*  Byte     Description
*  ====     =============================
*  +000     See Command List below
*  +001     Command
*
*    Commands    Description
*    ========    =================
*    $D5         Page Header End
*    $D6         Page Footer End
*    $D8         Platen width
*    $E2         Paper Length
*    $EC         Page Header Begin
*    $ED         Page Header End
*    $EE         Skip Lines
*    $EF         Page Number
*    $FF         End of File
*
* Text Records
*
*  Byte        Description
*  ====        ====================================
*  +000-001    # of bytes following this word;
*               +001 is always zero and is used
*               to identify text lines.
*  +002        Lower seven bits contain the number
*               of leading spaces for this line.
*  +003        Lower seven bits contain the number
*               of text bytes.
*  +004-nnn    Actual text, including any special
*               codes (bold, italic, etc.)
*

LOOP	POINT	RdWrLen;2
	POINT	RdWrBuf;AWPBUF
	MLI	READ;PRdWr
	BCS	ERR
	LDA	AWPBUF+1
	BEQ	IsText
	CMP	#$D0	;Blank line
	BEQ	CR
	CMP	#$FF	;End of file
	BNE	:CMDCHAR
	JMP	DONE
:CMDCHAR	JMP	DOCMDCH

CHARCNT	DFB	1

* The line contains text.

IsText	POINT	RdWrBuf;AWPBUF+2
	STDB	AWPBUF;RdWrLen
	MLI	READ;PRdWr
	BCS	ERR
	LDA	TitleFlag
	BEQ	:0
	POINT	TXTPTR;TopicTxt
	JSR	PRASZ
	BEQ	:00	;Always
:0	LDA	FLAG
	STA	PRNTON
	BEQ	LOOP
:00	LDA	AWPBUF+3
	AND	#$7F
	STA	CHARCNT
	LDX	#0
:1	LDA	AWPBUF+4,X
	CMP	#$20
	BCS	:ASCII
	LDA	#'^'
:ASCII	ORA	#$80
	JSR	COUT
	INX
	CPX	CHARCNT
	BNE	:1
CR	LDA	#$8D
	JSR	COUT
	LDA	FLAG
	CMP	#$8D
	BNE	:1
	JMP	LOOP
:1	CMP	#ESC
	BEQ	:RTS
:K	LDA	KBD
	BPL	:K
	STA	FLAG
	STA	STRB
	JMP	LOOP
:RTS	RTS

FLAG	DFB	1

* Process an AWP command character.  Certain
* formatting Options are mapped to Help System
* functionality as described below.

DOCMDCH	CMP	#$EC	;Help Title (AWP Page Header Begin)
	BEQ	HelpTitle
	CMP	#$D5	;Help Title End (AWP Page Header End)
	BEQ	HelpTitleEnd
	CMP	#$ED	;Topic ID (AWP Page Footer Begin)
	BEQ	TopicId
	CMP	#$D6	;Topic ID End (AWP Page Footer End)
	BEQ	TopicIdEnd
	CMP	#$D8	;Columns (AWP Platen Width)
	BEQ	GetCols
	CMP	#$EE	;Rows (AWP Skip Lines)
	BEQ	GetRows
	CMP	#$EF	;Y Coordinate (AWP Page Number)
	BEQ	:GoGetYCoord
	CMP	#$F2	;X Coordinate (AWP Set Marker)
	BEQ	GetXCoord
	CMP	#$E9	;New Topic (AWP New Page)
	BEQ	:GoNewTopic
	LDA	#"+"	;Unsupported command
	JSR	COUT
	LDA	#$8D
	JSR	COUT
	JMP	LOOP

:GoGetYCoord	JMP	GetYCoord
:GoNewTopic	JMP	NewTopic

HelpTitle
	LDA	#1
	STA	TitleFlag
	LDA	PRNTON
	BEQ	:1
	POINT	TXTPTR;TXT1
	JSR	PRASZ
:1	JMP	LOOP

HelpTitleEnd
	LDA	#0
	STA	TitleFlag
	LDA	PRNTON
	BEQ	:1
	POINT	TXTPTR;TXT2
	JSR	PRASZ
:1	JMP	LOOP

TopicId	INC	TopicId

TopicIdEnd
	JMP	LOOP

GetRows	LDA	AWPBUF
	STA	SaveRows
	LDA	PRNTON
	BEQ	:1
	POINT	TXTPTR;TXTROWS
	JSR	PRASZ
:1	JMP	LOOP

GetCols	LDA	AWPBUF
	STA	SaveCols
	LDA	PRNTON
	BEQ	:1
	POINT	TXTPTR;TXTCOLS
	JSR	PRASZ
:1	JMP	LOOP

GetXCoord
	LDX	AWPBUF
	STX	SaveXCoord
	LDA	PRNTON
	BEQ	:1
	POINT	TXTPTR;TXTXCORD
	JSR	PRASZ
:1	JMP	LOOP

GetYCoord
	LDX	AWPBUF
	DEX
	STX	SaveYCoord
	LDA	PRNTON
	BEQ	:1
	POINT	TXTPTR;TXTYCORD
	JSR	PRASZ
:1	JMP	LOOP

NewTopic
	MLI	GETMARK;PGetMark
	BCS	:Err
	INC	TopicCount
	STDB	GMarkPos;SaveLoc
	LDY	TopicCount
	DEY
	BEQ	:0
	LDY	#4	; Position of Topic Length Word
	SEC
	LDA	SaveLoc
	SBC	PrevLoc
	STA	(LASTPTR),Y
	INY
	LDA	SaveLoc+1
	SBC	PrevLoc+1
	STA	(LASTPTR),Y

:0	STDB	SaveLoc;PrevLoc

	LDY	#7
:1	LDA	SaveLoc,Y
	STA	(PTR),Y
	DEY
	BPL	:1
	STDB	PTR;LASTPTR
	CLC
	LDA	PTR
	ADC	#8
	STA	PTR
	BCC	:2
	INC	PTR+1
:2
	POINT	SaveXCoord;$FFFF
	POINT	SaveLen;$1000

	LDA	PRNTON
	BEQ	:9
	POINT	TXTPTR;TxtNewTopic
	JSR	PRASZ
:9	JMP	LOOP
:Err	JMP	ERR


PRASZ	LDY	#0
:1	LDA	(TXTPTR),Y
	BEQ	:2
	JSR	COUT
	INY
	BNE	:1
:2	RTS

DONE	MLI	CLOSE;PClose
	RTS

TXT1	ACZ	"======= Header Begin"
TXT2	ACZ	"======= Header End"
TXTROWS	ACZ	"======= Rows"
TXTCOLS	ACZ	"======= Cols"
TXTXCORD	ACZ	"======= X-Coord"
TXTYCORD	ACZ	"======= Y-Coord"
TxtNewTopic	ACZ	"======= New Topic"
TopicTxt	ASZ	"Help Topic: "

TitleFlag	DS	1

TopicID	DS	1

PrevLoc	DS	2

SaveLoc	DS	2
SaveRows	DS	1
SaveCols	DS	1
SaveLen	DS	2
SaveXCoord	DS	1
SaveYCoord	DS	1

POpen	HEX	03
OpenPn	DA	PNBUF
OpenBuf	DA	FILEBuf
OpenRef	DS	1

PClose	HEX	01
CloseRef	DS	1

PRdWr	HEX	04
RdWrRef	DS	1
RdWrBuf	DA	AWPBUF
RdWrLen	DS	2
RdWrAct	DS	2

PGetMark	HEX	02
GMarkRef	DS	1
GMarkPos	DS	3

POnline	HEX	02
OlUnitN	DS	1
OlBufPtr	DA	OnlineBuf


	DS	\

	DUM	*

OnlineBuf	DS	$100
FILEBuf	DS	$400
IDXBUF	DS	$400
AWPBUF	DS	$400

TopicCount	=	IDXBUF	;# of topics is in the first
	; byte of the index buffer.

	DEND
