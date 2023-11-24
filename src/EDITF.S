***************************************************
*                                                 *
*                Block Buster 2.x                 *
*        The Next Generation Block Editor         *
*                                                 *
*            Originally written in the            *
*               1985-1992 timeframe.              *
*                                                 *
*                 Code Repository                 *
*    https://github.com/d5aa962e/BlockBuster2     *
*                                                 *
*       BlockBuster2 by github.com/d5aa962e       *
*    is licensed under CC BY-SA 4.0. To view a    *
*           copy of this license, visit           *
*  http://creativecommons.org/licenses/by-sa/4.0/ *
*                                                 *
***************************************************

********************************
*                              *
*        File: EDITF.S         *
*                              *
*           Contents           *
*           --------           *
*                              *
* - More Program text          *
* - Pascal Date formatting     *
* - CP/M Dir Entries           *
* - Pascal Dir Entries Logic   *
* - Entries Helper logic       *
*                              *
********************************

DOSLOC	LDA	TRACK
	CMP	#$11
	BNE	:0
	LDA	SECTOR
	BNE	:0
	JMP	VTOCLOC	;VTOC entries
:0	LDA	PTR
	LDX	#6
:1	CMP	DOSDIRLOC,X
	BCS	:2
	DEX
	BPL	:1
	CMP	#1
	BCC	:2A
	CMP	#3
	BCS	:2A
	PRINT	DOSNCAT
	LDA	PTR+1
	STA	TEMPPTR+1
	LDY	#0
	STY	TEMPPTR
	INY
	JSR	TSLOC	;Print T/S list
	JMP	LOCCLN
:2	LDA	DOSDIRLOC,X
	STA	TEMPPTR	;Base in TEMPPTR
	LDA	PTR
	SBC	DOSDIRLOC,X
	TAX	;Offset in X
	ASL
	TAY
	LDA	PTR+1
	STA	TEMPPTR+1
	LDA	DOSDOFST,Y
	STA	PPARMS
	LDA	DOSDOFST+1,Y
	STA	PPARMS+1
	JSR	TXTCOLN
	TXA
	TAY
	CPY	#2
	BCC	:3C	;TSL
	BEQ	:4	;Type
	CPY	#33
	BCC	:5	;Name
	LDX	#1
	LDY	#33
	JSR	GODO
:2A	JMP	LOCCLN
:3A	LDY	#0
	LDA	(TEMPPTR),Y
	BNE	:2A
:3B	PRINT	EMPTY
	JMP	:2A
:3C	LDY	#0
	JSR	TSLOC
	JMP	:2A
:4	LDX	#9
	LDY	#2
	LDA	(TEMPPTR),Y
	PHA
	AND	#$7F
:4A	DEX
	BEQ	:4B
	CMP	DOSFTYP,X
	BNE	:4A
:4B	LDA	TYPOFST,X
	TAX
:4C	LDA	DOSFTYP,X
	BEQ	:4D
	JSR	COUT
	INX
	BNE	:4C
:4D	PLA
	BPL	:2A
	PRINT	DOSLOKED
	JMP	:2A
:5	LDY	#0
	LDA	(TEMPPTR),Y
	BEQ	:3B	;Empty or deleted entry
	LDY	#3
:5A	LDA	(TEMPPTR),Y
	AND	#$7F
	CMP	#' '
	BCS	:5B
	ORA	#$40
:5B	ORA	#$80
	JSR	COUT
	INY
	CPY	#33
	BNE	:5A
	BEQ	:2A

TSLOC	PRINT	DOSTRK
	LDA	#"$"
	JSR	COUT
	LDA	(TEMPPTR),Y
	JSR	PRBYT
	PRINT	DOSSEC
	LDA	#"$"
	JSR	COUT
	INY
	LDA	(TEMPPTR),Y
	AND	#$F
	JSR	PRHEX
	RTS

VTOCLOC	POINT	TEMPPTR;BLKBUF
	LDY	PTR
	BEQ	:0	;Unused 1
	CPY	#3
	BCS	:1
	PRINT	VTCAT	;1st catalog sector
	LDY	#1
	JSR	TSLOC
:0	JMP	LOCCLN
:1	BNE	:2
	PRINT	VTVER	;DOS version INITed with
	LDY	#3
	BNE	:3A
:2	CPY	#6
	BCC	:0	;Unused 2
	BNE	:3
	PRINT	VTVOL	;Volume number
	LDY	#6
	BNE	:3A
:3	CPY	#$27	;Unused 40
	BCC	:0
	BNE	:4
	PRINT	VTTSP	;TS pairs per TSL
	LDY	#$27
:3A	LDX	#0
:3B	JSR	GODO
:3C	JMP	LOCCLN
:4	CPY	#$30
	BCC	:3C	;Unused 8
	CPY	#$32
	BCS	:5
	PRINT	VTLAST	;Last allocated track
	LDY	#$30
	LDX	#0
	JSR	GODO
	PRINT	VTDIR	;Direction of allocation
	LDY	#$31
	LDX	#"+"
	LDA	BLKBUF,Y
	BPL	:4A
	LDX	#"-"
:4A	TXA
	JSR	COUT
	LDA	#"1"
	JSR	COUT
:4B	JMP	LOCCLN
:5	CPY	#$34
	BCC	:4B	;Unused 2
	BNE	:6
	PRINT	VTSIZE	;Tracks per disk
	LDY	#$34
	BNE	:3A
:6	CPY	#$35
	BNE	:7
	PRINT	VTSECTS	;Sectors per disk
	LDY	#$35
	BNE	:3A
:7	CPY	#$38
	BCS	:8
	PRINT	VTBYTES	;Bytes per sector
	LDX	#1
	LDY	#$36
	BNE	:3B
:7A	JMP	LOCCLN
:8	PRINT	VTBIT	;Free sector map
	LDA	PTR
	SEC
	SBC	#$38
	LSR
	LSR
	STA	ASAV
	JSR	PRBYT
	LDX	#2
	JSR	PRBL2
	LDA	ASAV
	ASL
	ASL
	TAY
	LDA	BLKBUF+$38,Y
	STA	TEMPPTR
	LDA	BLKBUF+$39,Y
	STA	TEMPPTR+1
	ORA	TEMPPTR
	BEQ	:9
	LDY	#0
:8A	LSR	TEMPPTR
	ROR	TEMPPTR+1
	BCC	:8C
	TYA
	AND	#$F
	JSR	PRHEX
:8B	INY
	CPY	#16
	BNE	:8A
	BEQ	:7A
:8C	LDX	#1
	JSR	PRBL2
	JMP	:8B
:9	PRINT	NONE
	JMP	LOCCLN

DOSDIRLOC	HEX	0B,2E,51,74,97,BA,DD

DOSDOFST	DA	DOSTSL,DOSTSL
	DA	DOSTYP
	LUP	30
	DA	DOSNAME
	--^
	DA	DOSSLEN,DOSSLEN

DOSTSL	ASC	"Track/S"0F
	ASZ	" list"
DOSTYP	DFB	13,0	;Type
DOSNAME	DFB	14,0	;Name
DOSSLEN	ASC	"Number of s"0FF300
DOSNCAT	ASC	"Next Catalog s"0f
	ASZ	": "

TYPOFST	DFB	DOSUNKN-DOSFTYP,DOSTXT-DOSFTYP,DOSINT-DOSFTYP
	DFB	DOSFP-DOSFTYP,DOSBIN-DOSFTYP,DOSSTYP-DOSFTYP
	DFB	DOSREL-DOSFTYP,DOSATYP-DOSFTYP,DOSBTYP-DOSFTYP

DOSFTYP	HEX	FF,00,01,02,04,08,10,20,40
DOSUNKN	ASZ	"Unknown"
DOSTXT	ASZ	"Text"
DOSINT	ASZ	"Integer"
DOSFP	ASZ	"Applesoft"
DOSBIN	ASZ	"Binary"
DOSSTYP	ASZ	"S Type"
DOSREL	ASZ	"Relocatable"
DOSATYP	ASZ	"A Type"
DOSBTYP	ASZ	"B Type"
DOSLOKED	ASZ	" - Locked"
DOSTRK	ASZ	"track "
DOSSEC	ASC	", s"0FA000

VTCAT	ASZ	"Catalog starts at "
VTVER	ASZ	"Version: "
VTVOL	ASZ	"Volume: "
VTTSP	ASZ	"TS pairs in TS list: "
VTLAST	ASZ	"Last track allocated: "
VTDIR	ASZ	"  Dir: "
VTSIZE	ASZ	"Tracks/disk: "
VTSECTS	ASC	"S"0F
	ASZ	"s/Track: "
VTBYTES	ASC	"Bytes/s"0F
	ASZ	": "
VTBIT	ASC	"Free s"0F
	ASZ	"s, track $"

MEMLOC	GOTO	38;23
	JSR	CLREOL
	LDA	MEMPAGE+1
	CMP	#$BF
	BNE	:5
	LDX	#SYSOFST-SYSLOCS-1
	LDA	PTR
:3	CMP	SYSLOCS,X
	BCS	:6
	DEX
	BNE	:3
	POINT	PPARMS;SYSMLI
:4	JSR	PRTXT2
:5	JMP	LOCCLN
:6	TXA
	ASL
	TAX
	LDA	SYSOFST,X	;Text of location
	STA	PPARMS
	LDA	SYSOFST+1,X
	STA	PPARMS+1
	JSR	PRTXT2
	LDA	OURCH
	PHA
	LDA	PTR
:8	CMP	#$10
	BCC	:7
	CMP	#$30
	BCS	:9
	GOTO	38;23	;Device driver list
	LDA	PTR
	ASL
	ASL
	ASL
	EOR	#$80
	AND	#$F0
	JSR	PRSD
:7	JMP	MEMCLN
:9	BNE	:10
	GOTO	38;23
	PRINT	SYSLDEV
	JMP	MEMCLN
:10	CMP	#$40
	BCC	:7
	CMP	#$50
	BCS	:11
	AND	#$40
	STA	TEMPPTR
	LDA	PTR+1
	STA	TEMPPTR+1
	LDY	#0
:101	LDA	(TEMPPTR),Y
	JSR	PRABLE
	JSR	COUT
	INY
	CPY	#15
	BNE	:101
	PLA
	JMP	LOCCLN
:11	CMP	#$70
	BCC	:7
	CMP	#$80
	BCS	:12
	PHA
	GOTO	48;23
	PLA
	LSR
	AND	#7
	CLC
	ADC	#1
	JSR	PRHEX
	JMP	MEMCLN
:12	CMP	#$88
	BCS	:13
	PHA
	GOTO	48;23
	PLA
	LSR
	AND	#7
	CLC
	ADC	#1
	JSR	PRHEX
	JMP	MEMCLN
:13	CMP	#$98	;Machine ID
	BNE	:14
	JMP	MEMCLN
:14	CMP	#$99	;ROM bitmap
	BNE	:15
	LDY	#0
	LDA	(PTR),Y
	LDX	#0
:141	LSR
	PHA
	LDA	#$A0
	BCC	:142
	TXA
	ORA	#$B0
:142	JSR	COUT
	PLA
	INX
	CPX	#8
	BNE	:141
	PLA
	JMP	LOCCLN
:15

MEMCLN	PLA
	STA	OURCH
	JMP	LOCCLN

PRSD	PHA
	LDA	#"S"
	JSR	COUT
	PLA
	PHA
	LSR
	LSR
	LSR
	LSR
	AND	#7
	ORA	#$B0
	JSR	COUT
	LDA	#$AC	;Quoted comma doesn't work in Merlin32
	JSR	COUT
	LDA	#$A0
	JSR	COUT
	LDA	#"D"
	JSR	COUT
	LDX	#"1"
	PLA
	BPL	:1
	INX
:1	TXA
	JSR	COUT
	RTS

SYSLOCS	HEX	00,03,06,09,0C,0F,10,30,31,32,40,50,56,58
	HEX	70,80,88,8D,8E,90,94,95,96,98,99,9A,9B,9C
	HEX	9E,A0,D0,F4,F6,FC,FE

SYSOFST	DA	SYSMLI,SYSBFF6,SYSCLK,SYSERR,SYSDEATH,SYSERRNO
	DA	SYSDEVAD,SYSLDEV,SYSDCNT,SYSACTD,SYSCOPR,SYSCIRQ,SYSTMP
	DA	SYSBIT,SYSBUFA,SYSIRQA,SYSSAV,SYSBID,SYSIRQR,SYSDTTM
	DA	SYSFLEVL,SYSBAKUP,SYSUN,SYSMACID,SYSROMMP,SYSPFX,SYSMLIA
	DA	SYSLMLI,SYSMSAV,SYSLCENT,SYSIRQE,SYSSTOR,SYSCDTH
	DA	SYSIVER,SYSKVER

SYSMLI	ASC	"MLI E"05
	ASZ	"Point"
SYSBFF6	ASZ	"--> $BFF6"
SYSCLK	ASC	"Clock Handler "1400
SYSERR	ASC	"--> "15c51600
SYSDEATH	ASC	"--> "15
	ASZ	"Death"
SYSERRNO	HEX	15C516
	ASZ	" Number"
SYSDEVAD	ASC	"       "17
	ASZ	"Driver "1400
SYSLDEV	ASZ	"Last "1700
	ASZ	"Used"
SYSDCNT	HEX	17
	ASZ	"count(-1)"
SYSACTD	HEX	17
	ASZ	"List"
SYSCOPR	HEX	00	;Just display Apple's copyright
SYSCIRQ	ASZ	"Call IRQ"
SYSTMP	ASZ	"Temporary storage"
SYSBIT	ASZ	"Bitmap"
SYSBUFA	ASC	"Open F"03
	ASC	"  Buffer "1400
SYSIRQA	ASC	"Interrupt   "1400
SYSSAV	ASZ	"Register (AXYSP) save"
SYSBID	ASZ	"Bank ID"
SYSIRQR	ASZ	"IRQ Return "1400
SYSDTTM	ASZ	"Date/Time"
SYSFLEVL	ASC	"F"03
	ASZ	"Level"
SYSBAKUP	ASZ	"Backup Bit"
SYSUN	ASZ	"Unused"
SYSMACID	ASZ	"Machine ID byte"
SYSROMMP	ASZ	"ROM in slots "
SYSPFX	ASZ	"Prefix Flag"
SYSMLIA	ASZ	"MLI Active"
SYSLMLI	ASC	"Last MLI Call "1400
SYSMSAV	ASZ	"MLI (XY) savarea"
SYSLCENT	ASC	"LC E"0588
	ASZ	"/Exit Routines"
SYSIRQE	ASC	"IRQ E"0588
	ASZ	"/Exit Routines"
SYSSTOR	ASZ	"$E000, $D000 storage"
SYSCDTH	ASC	"Call "15 ;System
	ASZ	"Death"
SYSIVER	ASC	"Interpreter "13D609AFD60900 ;minver/ver
SYSKVER	ASC	"Kernel "13d609afd60900

PASLOC	LDA	BLOCK+1
	BEQ	:1
:1B	JMP	LOCCLN
:1	LDA	BLOCK
	CMP	#2	;1st directory block?
	BCC	:1B
	BNE	:0A	;No
:2	LDA	PTR+1
	CMP	#>BLKBUF
	BNE	:0A	;Normal file entry
	LDA	PTR
	CMP	#26
	BCS	:0A	; here too
	JMP	PASVOLENT	;Do volume entries
:0A	LDX	#38
	LDY	BLOCK
	CPY	#7
	BCC	:0B
	JMP	LOCCLN
:0B	LDA	PASDIRLOC,X
	CLC
	ADC	PASDFIX-2,Y
	STA	TEMPPTR
	LDA	PASDIRLOC+1,X
	ADC	#0
	STA	TEMPPTR+1
	LDA	PTR
	CMP	TEMPPTR
	LDA	PTR+1
	SBC	TEMPPTR+1
	BCS	:3
	DEX
	DEX
	BPL	:0B
	SEC
	LDA	PASDIRLOC
	SBC	PASDFIX2-2,Y
	STA	TEMPPTR
	LDA	PASDIRLOC+1
	SBC	#0
	STA	TEMPPTR+1
	BNE	:3	;Always
:1C	JMP	:15A
:3	SEC
	LDA	PTR+1
	SBC	TEMPPTR+1
	LDA	PTR
	SBC	TEMPPTR
	TAX	;Offset in X
	ASL
	TAY	;Txt offset in Y
	LDA	PASDOFST,Y
	STA	PPARMS
	LDA	PASDOFST+1,Y
	STA	PPARMS+1
	JSR	TXTCOLN
	TXA
	TAY
	CPY	#2
	BCS	:5
	LDY	#0	;1st block
	BEQ	:14
:5	CPY	#4
	BCS	:6
	LDY	#2	;1st of next file
	BNE	:14
:6	CPY	#6
	BEQ	:16	;Name len
	BCS	:7
	LDY	#5	;Type
	BNE	:19
:7	CPY	#22
	BCC	:17	;Name
	CPY	#24
	BCS	:18	;Date
	LDY	#22
	BNE	:14	;Last block count
:13	LDX	#0
	HEX	2C	;Skip next instruction
:14	LDX	#1
:15	JSR	GODO
:15A	JMP	LOCCLN
:16	LDA	(TEMPPTR),Y
	BEQ	:17B
	BNE	:13
:17	LDY	#6
	LDA	(TEMPPTR),Y
	BEQ	:17B
	TAX
:17A	INY
	LDA	(TEMPPTR),Y
	JSR	PRABLE
	JSR	COUT
	CPY	#21
	BEQ	:15A	;Do maximum of 15 chars
	DEX
	BNE	:17A
	BEQ	:15A
:17B	PRINT	EMPTY
	JMP	:15A
:18	LDY	#24	;PASCAL Date
	JSR	DATEPAS
	JMP	:15A
:19	LDA	(TEMPPTR),Y
	BNE	:UNKN
	DEY	;Y=4
	LDA	(TEMPPTR),Y
:20	DEY	;Y=3
	BMI	:UNKN
	CMP	PASTTYP,Y
	BNE	:20
	TYA
	ASL
	TAY	;Txt offset in Y
:21	LDA	PASTLOC,Y
	STA	PPARMS
	LDA	PASTLOC+1,Y
	STA	PPARMS+1
	JSR	PRTXT2
	JMP	LOCCLN
:UNKN	LDY	#0
	BEQ	:21

PASVOLENT	LDA	PTR
	ASL
	TAY
	LDA	PASVOFST,Y
	STA	PPARMS
	LDA	PASVOFST+1,Y
	STA	PPARMS+1
	JSR	PRTXT2
	POINT	TEMPPTR;BLKBUF
	LDY	PTR
	CPY	#2
	BCS	:1
	BCC	:11	;First 2 bytes always zero
:1	CPY	#4
	BCS	:2
	JSR	COLON
	LDY	#2	;Start of 1st file
	BNE	:10
:2	CPY	#6
	BEQ	:13A	;File name length
	BCC	:11	;Unused
	CPY	#14
	BCC	:12	;Name
	CPY	#16
	BCS	:3
	JSR	COLON
	LDY	#14	;Blocks on disk
	BNE	:10
:3	CPY	#18
	BCS	:4
	JSR	COLON
	LDY	#16	;Number of files
	BNE	:10
:4	CPY	#20
	BCC	:11	;Unused
	CPY	#22
	BCS	:11	;Unused
	JSR	COLON
	LDY	#20
	JSR	DATEPAS
	JMP	:11
:9	LDX	#0
	HEX	2C
:10	LDX	#1
	JSR	GODO
:11	JMP	LOCCLN
:12	LDY	#6
	JSR	COLON
	LDA	(TEMPPTR),Y
	BEQ	:14
	TAX
:13	INY
	LDA	(TEMPPTR),Y
	JSR	PRABLE
	JSR	COUT
	CPY	#21
	BEQ	:11	;Max 15 chars in filename
	DEX
	BNE	:13
	BEQ	:11
:13A	JSR	COLON
	LDA	(TEMPPTR),Y
	BNE	:9
:14	PRINT	EMPTY
	JMP	:11


PASDFIX	DFB	0,8,16,24
PASDFIX2	DFB	0,18,10,2

PASDIRLOC
]A	=	BLKBUF
	LUP	20
	DA	]A
]A	=	]A+26
	--^

PASDOFST	DA	PAS1ST,PAS1ST,PAS1NXT,PAS1NXT
	DA	PASFTYP,PASFTYP,PASFLEN
	LUP	15
	DA	PASFNAM
	--^
	DA	PASBLB,PASBLB,PASDAT,PASDAT

PAS1ST	ASC	"1st b"0700
PAS1NXT	ASC	"1st b"07
	ASC	" of next f"0300
PASFTYP	DFB	13,0	;Type
PASFLEN	DFB	14
	ASZ	" length"
PASFNAM	DFB	14,0
PASBLB	ASC	"Bytes in last b"0700
PASDAT	DFB	18,0

PASVOFST	DA	PASV1ST,PASV1ST,PASV1POS,PASV1POS
	DA	NULSTR,NULSTR,PASVVLEN
	LUP	7
	DA	PASVVNAM
	--^
	DA	PASVTBLK,PASVTBLK,PASVCNT,PASVCNT
	DA	NULSTR,NULSTR,PASDAT,PASDAT
	DA	NULSTR,NULSTR,NULSTR,NULSTR

PASV1ST	ASZ	"Always zero"
PASV1POS	ASC	"First data b"0700
PASVVLEN	DFB	14
	ASZ	" length"
PASVVNAM	DFB	8,14,0
PASVTBLK	ASC	"Total B"07F300
PASVCNT	ASZ	"File count"
NULSTR	HEX	00

PASTTYP	DFB	0,2,5,3
PASTLOC	DA	PASUNKN,PASCODE,PASDATA,PASTEXT

PASUNKN	ASZ	"Unknown file type"
PASCODE	ASZ	"Codefile"
PASDATA	ASZ	"Datafile"
PASTEXT	ASZ	"Textfile"

DATEPAS	INY
	LDA	(TEMPPTR),Y
	LSR
	DEY
	LDA	(TEMPPTR),Y
	AND	#$F
	STA	:TEMP
	LDA	(TEMPPTR),Y
	ROR
	ROR
	ROR
	ROR
	AND	#$1F
	JSR	PRDEC
	LDA	#"-"
	JSR	COUT
	LDA	:TEMP
	ASL
	CLC
	ADC	:TEMP
	TAX
	LDA	#3
	STA	:TEMP
:18A	LDA	MONTHS,X
	JSR	COUT
	INX
	DEC	:TEMP
	BNE	:18A
	LDA	#"-"
	JSR	COUT
	INY
	LDY	#25	;Year
	LDA	(TEMPPTR),Y
	LSR
	JSR	PRDEC
	RTS
:TEMP	DS	1

CPMLOC	LDA	PTR
	PHA
	AND	#$E0	;Entries are 31 bytes long
	STA	TEMPPTR
	LDA	PTR+1
	STA	TEMPPTR+1
	PLA
	AND	#$1F
	TAX	;Offset in X
	CPX	#$D
	BEQ	:1B
	CPX	#$E
	BEQ	:1B
	ASL
	TAY
	LDA	CPMDOFST,Y
	STA	PPARMS
	LDA	CPMDOFST+1,Y
	STA	PPARMS+1
	JSR	TXTCOLN
	LDY	#0
	LDA	(TEMPPTR),Y
	CMP	#$E5	;Deleted
	BEQ	:4
	TXA
	TAY	;Offset in Y
	CPY	#0
	BEQ	:1	;User number
	CPY	#12
	BCC	:2	;Name
	BEQ	:1	;Extent
	CPY	#15
	BCC	:1B	;Unused 2 bytes
	CPY	#16
	BCS	:5	;Block allocation
	LDY	#15	;# of records
	BNE	:1	;Always
:1	LDX	#0
:1A	JSR	GODO	;Print decimal & hex number
:1B	JMP	LOCCLN
:2	LDY	#1
:2A	LDA	(TEMPPTR),Y
	CMP	#$20
	BEQ	:2B
	JSR	PRABLE
	JSR	COUT
	CPY	#9	;Only 8 chars in file name
	BEQ	:2B
	INY
	BNE	:2A	;Always
:2B	LDA	#"."
	JSR	COUT
	LDY	#8
:2C	INY
	LDA	(TEMPPTR),Y
	JSR	PRABLE
	JSR	COUT
	CPY	#12
	BNE	:2C
	BEQ	:1B
:4	PRINT	EMPTY
	JMP	:1B
:5	JSR	ZWRKAREA
	LDY	#32
:6	DEY
	CPY	#15
	BEQ	:7
	LDA	(TEMPPTR),Y
	BEQ	:6
:7	TYA
	SEC
	SBC	#15
	STA	WORKAREA
	LDY	#8
	JSR	Conv2Dec
	JSR	DECPRNT
	PRINT	T4
	PRINT	T4A
	JMP	LOCCLN

CPMDOFST	DA	CPMUNUM
	LUP	11
	DA	CPMFNAME
	--^
	DA	CPMEXT
	DA	NULSTR,NULSTR
	DA	CPMRECS
	LUP	16
	DA	CPMBLKS
	--^

CPMUNUM	ASZ	"User Number"
CPMFNAME	ASZ	"Filename/Ext."
CPMEXT	ASZ	"Extent"
CPMRECS	ASZ	"Records"
CPMBLKS	ASC	"B"07
	ASZ	" Allocation"

TXTCOLN	JSR	PRTXT2
COLON	LDA	#":"
	JSR	COUT
	LDA	#$A0
	JSR	COUT
	RTS

ZWRKAREA	LDA	#0
	LDX	#3
:1	STA	WORKAREA,X
	DEX
	BPL	:1
	RTS

CLEAR23	GOTO	0;23
	JSR	CLREOL
	RTS

PRNTSTOR	CMP	#$F
	BNE	:1
	PRINT	VOLDIR
	RTS
:1	CMP	#$E
	BNE	:2
	PRINT	SUBDIR
	RTS
:2	CMP	#$D
	BNE	:3
	PRINT	DIRECT
	RTS
:3	CMP	#$3
	BNE	:4
	PRINT	TRE
	RTS
:4	CMP	#$2
	BNE	:5
	PRINT	SAP
	RTS1
:5	PRINT	SEED
	RTS


PRBLKNUM	LDA	OSTYPE
	BEQ	:1
	CMP	#1
	BEQ	:2
	CMP	#2
	BEQ	:3
	CMP	#3	;Pascal
	BEQ	:1
	JSR	SAVCURLOC	;Print CP/M big block
	GOTO	77;4
	LDA	BIGBLOCK+1
	AND	#$F
	JSR	PRHEX
	LDA	BIGBLOCK
	JSR	PRBYT
	JSR	RESTCLOC
	RTS
:1	JSR	SAVCURLOC	;Print the current block number
	GOTO	76;4
	LDA	BLOCK+1
	JSR	PRBYT
	LDA	BLOCK
	JSR	PRBYT
	JSR	RESTCLOC
	RTS
:2	JSR	SAVCURLOC
	GOTO	74;4
	LDA	TRACK
	JSR	PRBYT
	GOTO	79;4
	LDA	SECTOR
	JSR	PRHEX
	JSR	RESTCLOC
	RTS
:3	JSR	SAVCURLOC
	GOTO	76;4
	LDA	RAMWORKSBANK
	PHA
	JSR	PRBYT
	LDA	MEMPAGE+1
	JSR	PRBYT
	GOTO	73;20
	LDA	#$A0
	JSR	COUT
	DEC	OURCH
	PLA	;Get RamWorksBank from stack
	BNE	:4	;If != 0 then in aux memory
	LDA	MEMPAGE+1	;Is this page protected?
	PHA
	AND	#7
	TAY
	LDX	MAPMASK,Y
	PLA
	LSR
	LSR
	LSR
	TAY
	TXA
	AND	$BF58,Y
	BEQ	:4	;Page is not in use
	LDA	#"P"	;Page is protected.
	JSR	COUT
:4	JSR	RESTCLOC
	RTS

MAPMASK	DFB	$80,$40,$20,$10
	DFB	$08,$04,$02,$01

PREMODE	JSR	SAVCURLOC
	JSR	SAVEWIN
	PRAT	72;18;EDTXT
	GOTO	72;19
	LDA	EMODE
	BPL	:1	;pos = ascii
	PRINT	HXMOD	;neg = hex
	JMP	:3
:1	AND	#%01000000
	BNE	:2
	PRINT	HICLR
	JMP	:3
:2	PRINT	HISET
:3	JSR	RESTWIN
	JSR	RESTCLOC
	RTS

EDITERR	PHA
	JSR	SAVCURLOC
	GOTO	38;23
	JSR	CLREOL
	PLA
	JSR	ERROR
	LDA	#$A0
	JSR	COUT
	JSR	MYKEYIN
	JSR	RESTCLOC
	RTS

PRABLE	AND	#$7F
	BEQ	:2
	CMP	#' '
	BCS	:1
	ORA	#$40
:1	ORA	#$80
:2	RTS

HEX2BIN	JSR	COPYNUM
	LDX	#0
:0	LDA	#8
	STA	TEMP
:1	LSR	WORKAREA,X
	LDA	#"0"
	BCC	:2
	LDA	#"1"
:2	STA	LNBUF,Y
	DEY
	DEC	TEMP
	BNE	:1
	LDA	#$A0
	STA	LNBUF,Y
	DEY
	INX
	CPX	#3
	BNE	:0
	RTS

HEX2HEX	JSR	COPYNUM
	LDX	#0
:1	LDA	WORKAREA,X
	JSR	HEXLINE
	INX
	CPX	#3
	BNE	:1
	RTS
HEXLINE	PHA
	JSR	:1
	PLA
	LSR
	LSR
	LSR
	LSR
:1	AND	#$F
	CMP	#$A
	BCC	:2
	ADC	#"@"-10
	BNE	:3
:2	ORA	#$B0
:3	STA	LNBUF,Y
	DEY
	RTS

HIBITS	ASZ	"0 1 2 3 4 5 6 7 8 9 A B C D E F   ",00
OLDPARMS	ASC	'A'
	ASC	"-cmd"00
PARMSO	ASZ	" ? "
PARMS	HEX	8D
	ACR	"Byte:"
	HEX	00

APS1	ACR	"Ascii  "
	ACR	"Copy    "
	ACR	"Drive"
	ACR	"Entries"
	ACR	"File    "
	ACR	"Goto   "
	ACR	"Indx Blk"
	ACR	"Jump to"
	ACR	"maKefile"
	ACR	"Look for"
	ACR	"Mode  "
	ACR	"Number  "
	ASZ	"        "

APS2	ACR	"Opcodes"
	ACR	"Print   "
	ACR	"Quit  "
	ACR	"Read   "
	ACR	"Slot    "
	ACR	"Trk/sec"
	ACR	"Undo    "
	ACR	"Version"
	ACR	"Write   "
	ACR	"Xchange "
	ACR	"Zero  "
	ACR	"8(*)-Mon"
	ASZ	"Ctl-Prot"

MAKPARMS	ACR	"       "
	ACR	"Makefile"
	ACR	"  keys  "
	ACR	"        "
	ACR	"Control+"
	ACR	"        "
	ACR	"B)ack   "
	ACR	"C)lose "
	ACR	"E)of    "
	ACR	"W)rite  "
	ACR	"Q)uit   "
	ASZ	"      "

BLKNAM	ACR	"Blk:"
AHLPTXT	ASZ	"-? for Help"
EDTXT	ASZ	"EditMode"
HXMOD	ASZ	"   Hex  "
HISET	ASZ	"Hi Ascii"
HICLR	ASZ	"Lo Ascii"
FILMOD	ASZ	"File: "
LKPRMPT	ASZ	"Look for: "
WHATPOS	ASC	"F"03
	ASC	"p"0a
	ASZ	" ($=hex): "
UNITTXT	ASZ	"Slot: "
UNITTXT2	ASZ	"   Drive: "
VOLDIR	HEX	08
	ASC	"d"0100
SUBDIR	ASZ	"Subd"0100
DIRECT	ASC	"D"0100
TRE	ASZ	"Tree"
SAP	ASZ	"Sapling"
SEED	ASZ	"Seedling"
EMPTY	ASC	"Empty or deleted e"0500
OSM	ASZ	"OS Mode: "

TSBLK	ASZ	"T:   S:"
MEMBLK	ASZ	"Mem:"
PASBLK	ASZ	"PAS:"
CPMBLK	ASZ	"CP/M:"

OPSYS	HEX	05
OPPro	ASZ	"ProDOS"
OPDos	ASZ	"DOS 3.3"
OPMem	ASZ	"Memory"
OPPas	ASZ	"Apple Pascal"
OPCpm	ASZ	"CP/M"

UNDW	HEX	02
	ASZ	"Edits"
	ASZ	"Writes"

CP	HEX	02
	ASZ	"To Clipboard"
	ASZ	"From Clipboard"

CCP	HEX	02
	ASZ	"Cut"
	ASZ	"Kopy"

RI	HEX	02
	ASZ	"Replace"
	ASZ	"Insert"

BDF	HEX	04
	ASZ	"Block"
	ASZ	"Data Block"
	ASZ	"File Position"
	ASZ	"End of File"

ZV	HEX	02
	ASZ	"Zeros"
	ASZ	"Value"

RTE	HEX	02
	ASZ	"To end"
	ASZ	"Range"

AO	HEX	02
	ASZ	"Append"
	ASZ	"Overwrite"

ALSM	HEX	03
	ASZ	"All"
	ASZ	"Some"
	ASZ	"To end"

FolAct	ASZ	"You are following a file, close before quitting"
MakAct	ASZ	"Please close the maKefile before quitting"
BothAct	ASZ	"Follow & maKefile active, close before quitting"
EOVR	ASZ	"End of volume reached "
CLIPLIM	ASZ	"Clipboard size (512 bytes) exceeded"
NoOpCHil	ASZ	"You can't copy while Opcodes are active"
CANTDO	ASZ	"Command only valid in ProDOS and DOS 3.3 modes"
NFILACT	ASZ	"Command not valid while a file is active"
MAKKEYS	ASC	"Makefile Control Keys:  B)ack  C)lose  E)of  "
	ASZ	"R)ead  W)rite  Q)uit"
KPY	ASZ	"Copy: "
HLT	ASZ	"Use arrows to highlight range."
UNDOTXT	ASZ	"Undo what? "
FW	ASZ	"Fill with: "
FW2	HEX	8888
	ASZ	" ($=hex): "
NOB	ASZ	"Number of bytes ($=hex): "
NCONV	ASZ	"Convert ($=hex,%=bin): "
J2	ASZ	"Jump to: "
MPAGE	ASZ	"Memory page: $"
RAMWKSBK	ASZ	" RamWorks bank: $"
RSVD8	ASZ	"8 bytes"
EXNW	ASZ	" exists, now what? "
MKG	ASZ	"Making "
EA	ASZ	", EOF: "
CURP	ASZ	"Position: "
WTW	ASZ	"Write how much? "
WRTN	ASZ	" written"
NEEDFIL	ASC	"You must be following a file for File Byte "
	ASZ	"and End of File options"
BadDigit	ASZ	" <== Invalid digit in number"
