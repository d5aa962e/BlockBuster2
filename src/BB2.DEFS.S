***************************************************
*                                                 *
*                Block Buster 2.0                 *
*        The Next Generation Block Editor         *
*                                                 *
*            Originally written in the            *
*               1985-1992 timeframe.              *
*                                                 *
*                 Code Repository                 *
*    https://github.com/d5aa962e/BlockBuster2     *
*                                                 *
*              License: CC BY-SA 4.0              *
*      Creative Commons Attribution-ShareAlike    *
* https://creativecommons.org/licenses/by-sa/4.0  *
*                                                 *
***************************************************

********************************
*                              *
*        File: BB.DEFS.S       *
*                              *
*  This file contains the      *
*  default values for Block    *
*  Buster.  Please see the     *
*  embedded descriptions for   *
*  how each parameter is used. *
*                              *
********************************

Defaults

BBVERNUM HEX   21         ;Version 2.1
BBTAG    ASC   "2.1.0"00  ;Specific Github release tag

         DS    32+BBTAG-* ;Total of 32 bytes avaliable
                          ; for the GitHub tag.

*
* Printer info
*

PRTRSLOT DFB   1          ;Printer slot
PRINIT   DFB   10         ;Count
         HEX   81         ;Initialization string
         ASC   "15B"81
         ASC   "1P"81
         ASC   "1D"

         DS    15+PRINIT-* ;MUST be 15 bytes

COPR     DA    BBVER-Defaults ;Version  address

*
* Global Configuration Flags
*

FIRSTFLG DFB   0          ;0=First time through (for opening screen)
AAUpDn   DFB   4          ;# of lines  to move for AnyApple-Up/Down
AALftRt  DFB   16         ;# of bytes to move for AnyApple-Left/Right
DebugFlg DFB   $FF        ;Debug flag (0=debugging)
MyMachId DFB   0          ;Machine ID byte (0=determine)
KeyDly   DFB   $70,$80    ;On/Off delays for flashing cursor
Buzz1    DFB   $36,$4,$18 ;Delay values for first part of beep
Buzz2    DFB   $30,$2,$23 ;  "     "     "  second part of beep

*
* Location of help files
* 0 = Read from boot disk
* 1 = Use saved path
* 2 = Copy help files to /RAM
*

HELPLOC  DFB   0          ;Help files location
IDXPN    DS    48         ;Pathname buffer for Index file
HELPPN   DS    48         ;Pathname buffer for Help File

*
* Block Buster Specifics
*

ENTFLG   DFB   0          ;0=no entry descriptions, >0=descriptions
OSTYPE   DFB   0          ;Current operating system mode
OPFLAG   DFB   0          ;Doing Opcodes if non-zero
IMMSIZE  DFB   0          ;Immediate mode size
EMODE    DFB   0          ;Block editor edit mode
VIEWFLG  DFB   0          ;ASCII display mode (nor, inv, mouse)
EOBFlag  DFB   0          ;End of Block flag (1=goto next/prev)
WPFlag   DFB   0          ;Write Protect Flag (non-zero = protect)
IBTHRESH DFB   10         ;Index Block Confidence Threshold

BBVER    ASC   "Block Buster v"00
BBVER2   ASC   "GitHub Rel: "00

         HEX   00

BBIDX    STR   'BB2.IDX'
BBHLP    STR   'BB2.HLP'

         DS    \          ;Align with page start
