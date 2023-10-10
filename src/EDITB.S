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
*        File: EDITB.S         *
*                              *
*           Contents           *
*           --------           *
* - Copy / Paste Logic         *
*                              *
********************************

*
* Copy a chunk of bytes
*

KOPY     CTX   HLPaaC
         JSR   SAVCURLOC
:TF      GOTO  0;23
         JSR   CLREOL
         PRAT  0;23;KPY
         POINT CHPTR;CP
         LDX   #1
         JSR   CHOOSE
         BEQ   :E
         CMP   #1         ;Cut
         BEQ   :CUT
         JMP   :PASTE     ;Paste
:E       JMP   :E3
:CUT     LDA   OPFLAG
         BEQ   :C1
         GOTO  0;23       ;Opcodes active, don't
         JSR   CLREOL     ;allow a cut
         JSR   BUZZ       ; (can't hilight opcodes)
         PRINT NoOpCHil   ; yet!
         CTX   HLPClipHlp
         JSR   ERROR1
         JMP   :E3
:C1      JSR   LITECHNK   ;Get chunk to copy
         BCC   :E         ;don't try again, must DOSCRN
         CTX   HLPCpy2Clip
         JSR   SAVCURLOC
         LDA   PTR+1      ;Did we try to copy
         SEC              ;> 512 bytes?
         SBC   PTR2+1
         CMP   #2
         BCC   :F         ;No
         CMP   #$FE
         BCS   :F
         JSR   BUZZ       ;Yes
         CTX   HLPClipHlp
         PRAT  0;23;CLIPLIM ;Print limit
         JSR   WAIT4      ;... hit a key
         JMP   :E3
:F       STDB  PTR;IBPTR
         GOTO  6;23
         JSR   CLREOL
         POINT CHPTR;CCP
         LDX   #1
         JSR   CHOOSE     ;Cut/Kopy
         BEQ   :E
         CMP   #1
         BEQ   :KUT       ;Delete block data
:KPY     POINT DIRPTR;CLIPBRD
         PUSH  PTR2       ;PUSH PTR originally
         LDY   #0
         STY   IBCOUNT
         STY   IBCOUNT+1
         JSR   CMPPW
         BCS   :K1
:4       LDA   (PTR),Y
         STA   (DIRPTR),Y ;PTR < PTR2
         LDA   PTR+1
         CMP   PTR2+1
         BNE   :4A
         LDA   PTR
         CMP   PTR2
         BEQ   :9
:4A      INCW  IBCOUNT
         INCW  DIRPTR
:5A      INCW  PTR
         BNE   :4         ;Always
:K1      LDA   (PTR2),Y   ;PTR >= PTR2
         STA   (DIRPTR),Y
         LDA   PTR2+1
         CMP   PTR+1
         BNE   :6
         LDA   PTR2
         CMP   PTR
         BEQ   :9
:6       INCW  IBCOUNT
:7       INCW  PTR2
:8       INCW  DIRPTR
         BNE   :K1        ;Always
:9       JMP   :E4

:KUT     POINT DIRPTR;CLIPBRD
         PUSH  PTR2       ;PUSH PTR2 originally
         LDY   #0
         STY   IBCOUNT
         STY   IBCOUNT+1
         JSR   CMPPW
         BCS   :14A
         STDB  PTR2;IBPTR
:10A     INCW  IBPTR
:10      LDA   (PTR),Y
         STA   (DIRPTR),Y ;PTR < PTR2
         LDA   (IBPTR),Y
         STA   (PTR),Y
         LDA   PTR+1
         CMP   PTR2+1
         BNE   :11
         LDA   PTR
         CMP   PTR2
         BNE   :11
         STDB  PTR;PTR2
         JMP   :19

:11      INCW  IBCOUNT
:13      INCW  DIRPTR
:14      INCW  PTR
         BNE   :10A       ;Always

:14A     STDB  PTR;IBPTR
:14B     INCW  IBPTR
:K3      LDA   (PTR2),Y   ;PTR >= PTR2
         STA   (DIRPTR),Y
         LDA   (IBPTR),Y
         STA   (PTR2),Y
         LDA   PTR2+1
         CMP   PTR+1
         BNE   :15
         LDA   PTR2
         CMP   PTR
         BEQ   :19C
:15      INCW  IBCOUNT
:16      INCW  PTR2
:18      INCW  DIRPTR
         BNE   :14B       ;Always
:19      INCW  IBPTR
:19A     INCW  PTR2
:19B     LDA   PTR2+1
         CMP   BUFEND
         BNE   :19C
         JSR   SetDirty
         JMP   :E4
:19C     LDA   (IBPTR),Y
         STA   (PTR2),Y
         JMP   :19

:E4      PULL  WORKAREA   ;PULL PTR
         JSR   CLEAR23
         JSR   RESTCLOC
         JSR   MOV2
         JMP   DOSCRN
:E3      JSR   CLEAR23
         JSR   RESTCLOC
         JMP   DOSCRN
:E2      JMP   :E1

:PASTE   POINT CHPTR;RI
         CTX   HLPCpyFrmClip
         LDX   #1
         JSR   CHOOSE
         BNE   :P1
         JMP   :TF
:P1      PHA
         JSR   CLREOL
         JSR   RESTCLOC
         PLA
         BEQ   :E2
         CMP   #1         ;Replace
         BEQ   :REP
         LDA   #$FF       ;Insert
         CLC
         SBC   IBCOUNT
         STA   IBPTR
         LDA   #>BLKBUF+$1FF
         SBC   IBCOUNT+1
         STA   IBPTR+1
         POINT DIRPTR;BLKBUF+$1FF
         STDB  IBCOUNT;DIRCOUNT
         LDY   #0
:9A      LDA   (IBPTR),Y
         STA   (DIRPTR),Y
         LDA   IBPTR
         CMP   PTR
         BNE   :9B
         LDA   IBPTR+1
         CMP   PTR+1
         BEQ   :REP
:9B      LDA   IBPTR
         SEC
         SBC   #1
         STA   IBPTR
         BCS   :9C
         DEC   IBPTR+1
:9C      LDA   DIRPTR
         SEC
         SBC   #1
         STA   DIRPTR
         BCS   :9A
         DEC   DIRPTR+1
         BNE   :9A        ;Always

:REP     STDB  IBCOUNT;DIRCOUNT ;Save old count
         STDB  PTR;IBPTR
         POINT DIRPTR;CLIPBRD
         LDY   #0
:20      LDA   (DIRPTR),Y
         STA   (IBPTR),Y
         INCW  IBPTR
:21      INCW  DIRPTR
:22      DEC   DIRCOUNT
         LDA   DIRCOUNT
         CMP   #$FF
         BNE   :20
         DEC   DIRCOUNT+1
         LDA   DIRCOUNT+1
         CMP   #$FF
         BNE   :20
:E1      JSR   SAVCURLOC
         JSR   CLEAR23
         JSR   RESTCLOC
         JSR   SetDirty
         JMP   DOSCRN

*
* Compare PTR to PTR2
* Carry set   if PTR2 >= PTR
*       clear if PTR2 < PTR
*

CMPPW    LDA   PTR+1
         CMP   PTR2+1
         BCC   :1
         BNE   :1
         LDA   PTR
         CMP   PTR2
:1       RTS

COPYRT   JSR   CMPPW
         BCC   :1
         JSR   INVBYTE
         JSR   RIGHT
         RTS
:1       JSR   NORMBYTE
         JSR   RIGHT
         RTS

COPYLFT  JSR   CMPPW
         BEQ   :1
         BCS   :2
:1       JSR   INVBYTE
         JSR   LEFT
         RTS
:2       JSR   NORMBYTE
         JSR   LEFT
         RTS

COPYUP   LDA   #$FF
         STA   Hilitng
         LDX   #$20
:1       JSR   COPYLFT
         DEX
         BNE   :1
         RTS

COPYDN   LDA   #1
         STA   Hilitng
         LDX   #$20
:1       JSR   COPYRT
         DEX
         BNE   :1
         RTS

LITECHNK PRINT HLT
         CTX   HLPHilite
         LDA   #0
         STA   Hilitng
         JSR   RESTCLOC
         STDB  PTR;PTR2
:0       JSR   INVBYTE
         JSR   EDITKEY
         PHA
         JSR   NORMBYTE
         PLA
         CMP   #RTARO
         BNE   :2
         JSR   COPYRT
         BNE   :3
:2       CMP   #LFTARO
         BNE   :3
         JSR   COPYLFT
         JMP   :0
:3       CMP   #UPARO
         BNE   :3A
         JSR   COPYUP
         BEQ   :0
:3A      CMP   #DNARO
         BNE   :CR
         JSR   COPYDN
         BEQ   :0
:CR      CMP   #$8D
         BEQ   :5         ;Carry is set if OK
         CMP   #$9B       ;Escape
         BNE   :0
         JSR   SAVCURLOC
         GOTO  0;22
         JSR   CLREOL
         JSR   RESTCLOC
         CLC              ;Carry set if escaped
:5       PHP
         LDA   #0
         STA   Hilitng
         PLP
         RTS

Hilitng  DS    1          ;Zero if hilighting a chunk
