* This is a port of Robert Uiterwyk's Micro Basic to my 6800 Single
* Board Computer.
*
* Changes made:
*
* - Modified to build with the as09 assembler
* - Changed I/O routines and PIA address to work with by SBC
* - Added corrections and bug fixes listed on the web site.
*
* PROGRAM FILE AND SYSTEM CUSTOMIZING
*  1. The program is stored starting at location $OCA4
*  2. The next available core location is stored in $002A and $0028
*  3. Location $0046 and $0047 contain the high end of
*     memory. This is set to $7FFF (32K) and must be changed if
*     you have more or less. (The system will run in 4K, but you
*     will have room for only about 35 statements)
*  4. Memory location $43 contains $48 (Decimal 72) (And must be changed
*     per different print line lengths)
*  5. Memory location $44 contains $OF (Backspace control)
*  6. Memory location $45 contains $18 (Cancel control)
*
* For more information, see https://deramp.com/swtpc.com/NewsLetter1/MicroBasic.htm

        title "MICROBASIC"

* ***** VERSION 1.3A *****
*
* BY ROBERT H UITERWYK, TAMPA, FLORIDA
*
*THIS PROGRAM ASSUMES THAT THE
*MOTOROLA MIKBUG ROM IS INSTALLED
*AND THAT ITS ASSOCIATED 128 BYTE
*RAM IS ALSO PRESENT
*THE SP AND XSTACK WILL HAVE TO
*BE MOVED IF THIS IS NOT THE CASE

        org $20
INDEX1  fdb $0000
INDEX2  fdb $0000
INDEX3  fdb $0000
INDEX4  fdb $0000
SAVESP  fdb $0000
NEXTBA  fdb END
WORKBA  fdb END
SOURCE  fdb END
PACKLN  fdb $0000
HIGHLN  fdb $0000
BASPNT  fdb $0000
BASLIN  fdb $0000
PUSHTX  fdb $0000
XSTACK  fdb $7F7F
RNDVAL  fdb $0000
DIMPNT  fdb $0000
DIMCAL  fdb $0000
PRCNT   fcb 0
MAXLIN  fcb 72
BACKSP  fcb $0F
CANCEL  fcb $18
MEMEND  fdb $7F00
ARRTAB  fdb $0000
KEYWD   fdb $0000
TSIGN   fcb 0
NCMPR   fcb 0
TNUMB   fcb 0
ANUMB   fcb 0
BNUMB   fcb 0
AESTK   fdb ASTACK
FORPNT  fdb FORSTK
VARPNT  fdb VARTAB
SBRPNT  fdb SBRSTK
SBRSTK  rmb 16
FORSTK  rmb 48
DIMVAR  fdb VARTAB


        org $00AC
BUFNXT  fdb $00B0
ENDBUF  fdb $00B0
        org $00B0
BUFFER  rmb $50

        org $0100
PROGM   jmp START
VARTAB  rmb 78
        fcb $1E
COMMAN  fcc "RUN"
        fcb $1E
        fdb RUN
        fcc "LIST"
        fcb $1E
        fdb CLIST
        fcc "NEW"
        fcb $1E
        fdb START
        fcc "PAT"
        fcb $1E
        fdb PATCH
GOLIST  fcc "GOSUB"
        fcb $1E
        fdb GOSUB
        fcc "GOTO"
        fcb $1E
        fdb GOTO
        fcc "GO TO"
        fcb $1E
        fdb GOTO
        fcc "SIZE"
        fcb $1E
        fdb SIZE
        fcc "THEN"
        fcb $1E
        fdb IF2
        fcc "PRINT"
        fcb $1E
        fdb PRINT
        fcc "LET"
        fcb $1E
        fdb LET
        fcc "INPUT"
        fcb $1E
        fdb INPUT
        fcc "IF"
        fcb $1E
        fdb IF
        fcc "END"
        fcb $1E
        fdb READY
        fcc "RETURN"
        fcb $1E
        fdb RETURN
        fcc "DIM"
        fcb $1E
        fdb DIM
        fcc "FOR"
        fcb $1E
        fdb FOR
        fcc "NEXT"
        fcb $1E
        fdb NEXT
        fcc "EEM"
        fcb $1E
        fdb REMARK
PAUMSG  fcc "PAUSE"
        fcb $1E
        fdb PAUSE
        fcb $20
COMEND  fcb $1E
IMPLET  fdb LET
        rmb 60
ASTACK  equ *-1
RDYMSG  fcb $0D
        fcb $0A
        fcb $15
        fcb $0A
        fcb $15
        fcc "READY"
        fcb $1E
PROMPT  fcb $23
        fcb $00
        fcb $1E
        fcb $1E
PGCNTL  fcb $10
        fcb $16
        fcb $1E
        fcb $1E
        fcb $1E
ERRMS1  fcc "ERROR# "
        fcb $1E
ERRMS2  fcc " IN LINE "
        fcb $1E
KEYBD   ldaa  #$3F
        bsr OUTCH
KEYBD0  ldx #BUFFER
        ldab  #10
KEYBD1  bsr INCH
        cmpa  #$00
        bne KEYB11
        decb
        bne KEYB11
KEYB10  jmp READY
KEYB11  cmpa  CANCEL
        beq DEL
        cmpa  #$0D
        beq IEXIT
KEYBD2  cmpa  #$0A
        beq KEYBD1
        cmpa  #$15
        beq KEYBD1
        cmpa  #$13
        beq KEYBD1
KEYB55  cmpa  BACKSP
        bne KEYBD3
        cpx #BUFFER
        beq KEYBD1
        dex
        bra KEYBD1
KEYBD3  cpx #BUFFER+71
        beq KEYBD1
        staa  0,x
        inx
        bra KEYBD1
DEL     bsr CRLF
CNTLIN  ldx #PROMPT
        bsr OUTNCR
        bra KEYBD0
IEXIT   ldaa  #$1E
        staa  0,x
        stx ENDBUF
        bsr CRLF
        rts

OUTCH   bsr BREAK
        jmp OUTEEE
OUTEEE  equ $F569

INCH    jmp INEEE

BREAK   jmp BREAK1
BREAK1  psha
        ldaa  PIAD
PIAD    equ $8004
        bmi BREAK2
        jmp READY

BREAK2  pula
        rts

INEEE   equ $F520
OUTPUT  equ *
        bsr OUTNCR
        bra CRLF

OUTPU2  bsr  OUTCH
OUTPU3  inx
OUTNCR  ldaa  0,x
        cmpa  #$1E
        bne OUTPU2
        rts

CRLF    bsr PUSHX
        ldx #CRLFST
        bsr OUTNCR
        bsr PULLX
        rts

CRLFST  fcb $00
        fcb $0D
        fcb $0A
        fcb $15
CREND   fcb $1E
        fcb $FF,$FF
        fcb $FF,$FF
        fcb $1E
PUSHX   stx PUSHTX
        ldx XSTACK
        dex
        dex
        stx XSTACK
        psha
        ldaa  PUSHTX
        staa  0,x
        ldaa  PUSHTX+1
        staa  1,x
        pula
        ldx PUSHTX
        rts

PULLX   ldx XSTACK
        ldx 0,x
        inc XSTACK+1
        inc XSTACK+1
        rts

STORE   psha
        pshb
        bsr PUSHX
        jsr PULLAE
        ldx AESTK
        inx
        inx
        stx AESTK
        dex
        dex
        ldx 0,x
        staa  0,x
        stab  1,x
        bsr PULLX
        pulb
        pula
        rts

IND     bsr PUSHX
        psha
        pshb
        ldx AESTK
        inx
        inx
        stx AESTK
        dex
        dex
        ldx 0,x
        ldaa  0,x
        ldab  1,x
        jsr PUSHAE
        pulb
        pula
        bsr PULLX
        rts

LIST    ldx NEXTBA
        stx WORKBA
        ldx SOURCE
        bra LIST1
LIST0   ldx INDEX3
LIST1   cpx WORKBA
        beq LEXIT
        bsr OUTLIN
        inx
        bra LIST1
LEXIT   rts

OUTLIN  ldaa  0,x
        clr PRCNT
        inx
        ldab  0,x
        inx
        clr TSIGN
        jsr PRN0
        bsr PRINSP
OUTLI1  ldaa  0,x
        inx
        bsr PUSHX
        ldx #COMMAN
        stx KEYWD
        staa  KEYWD+1
        ldx KEYWD
        dex
OUTLI2  dex
        ldaa  0,x
        cmpa  #$1E
        bne OUTLI2
        inx
        inx
        inx
        jsr OUTNCR
        jsr PULLX
        jmp OUTPUT

PRINSP  psha
        ldaa  #$20
        jsr OUTCH
        pula
        rts

RANDOM  inx
        inx
        ldaa  0,x
        cmpa  #'D'
        bne  TSTVER
        jsr PUSHX
        ldaa  RNDVAL
        ldab  RNDVAL+1
        ldx  #0000
RAND1   adcb  1,x
        adca  0,x
        inx
        inx
        cpx #RNDVAL
        bne  RAND1
        anda  #$7F
        staa  RNDVAL
        stab  RNDVAL+1
        stx   INDEX1
        ldaa  INDEX1
        ldab  INDEX1+1
        jmp   TSTV9

TSTV    jsr   SKIPSP
        jsr   BREAK
        jsr   TSTLTR
        bcc   TSTV1
        rts

TSTV1   cmpa  #'R'
        bne TSTV2
        ldab  1,x
        cmpb  #'N'
        beq  RANDOM
TSTV2   jsr PUSHX
        suba  #$40
        staa  VARPNT+1
        asla
        adda  VARPNT+1
        staa  VARPNT+1
        ldx VARPNT
        ldaa  VARPNT
        ldab  VARPNT+1
        tst  2,x
        bne  TSTV20
        jmp  TSTV9

TSTV20  ldx  0,x
        stx  DIMPNT
        inx
        inx
        stx DIMCAL
        jsr  PULLX
        jsr INXSKP
        cmpa  #'('
        beq TSTV22
TSTVER  jmp DBLLTR
TSTV22  inx
        jsr EXPR
        jsr PUSHX
        jsr PULLAE
        tsta
        beq TSTV3
SUBER1  jmp  SUBERR

TSTV3   ldx DIMPNT
        tstb
        beq  SUBER1
        cmpb  0,x
        bhi  SUBER1
        ldaa  1,x
        staa  ANUMB
        beq TST666
        ldx DIMCAL
TSTV4   decb
        beq TSTV6
        ldaa  ANUMB
TSTV5   inx
        inx
        deca
        bne TSTV5
        bra TSTV4

TSTV6   stx DIMCAL
        jsr PULLX
        jsr SKIPSP
        cmpa  #','
        bne TSTVER
        inx
        jsr EXPR
        jsr PUSHX
        jsr PULLAE
        tsta
        bne SUBER1
        ldx DIMPNT
        tstb
        beq SUBER1
        cmpb  1,x
        bhi SUBER1
TST666  ldx DIMCAL
TSTV7   inx
        inx
        decb
        bne TSTV7
        dex
        dex
        stx DIMCAL
        jsr PULLX
        jsr SKIPSP
TSTV8   cmpa   #')'
        bne TSTVER
        jsr PUSHX
        ldaa  DIMCAL
        ldab  DIMCAL+1
TSTV9   jsr  PULLX
        inx
        jsr PUSHAE
        clc
        rts

TSTLTR  cmpa  #$41
        bmi NONO
        cmpa  #$5A
        ble YESNO
TESTNO  cmpa  #$30
        bmi NONO
        cmpa  #$39
        ble YESNO
NONO    sec
        rts
YESNO   clc
        rts

PULPSH  bsr PULLAE
PUSHAE  sts SAVESP
        lds AESTK
        pshb
        psha
        sts AESTK
        lds SAVESP
        rts

PULLAE  sts SAVESP
        lds AESTK
        pula
        pulb
        sts AESTK
        lds SAVESP
        rts

FACT    jsr SKIPSP
        jsr TSTV
        bcs FACT0
        jsr IND
        rts

FACT0   jsr TSTN
        bcs FACT1
        rts

FACT1   cmpa  #'('
        bne FACT2
        inx
        bsr  EXPR
        jsr  SKIPSP
        cmpa  #')'
        bne FACT2
        inx
        rts

FACT2   ldab  #13
        jmp  ERROR

TERM    bsr  FACT
TERM0   jsr SKIPSP
        cmpa  #'*'
        bne TERM1
        inx
        bsr FACT
        bsr MPY
        bra TERM0

TERM1   cmpa  #'"'
        bne TERM2
        inx
        bsr FACT
        jsr DIV
        bra TERM0

TERM2   rts

EXPR    jsr SKIPSP
        cmpa  #'-'
        bne EXPR0
        inx
        bsr TERM
        jsr NEG
        bra EXPR1
EXPR0   cmpa  #'+'
        bne EXPR00
        inx
EXPR00  bsr TERM
EXPR1   jsr SKIPSP
        cmpa  #'+'
        bne EXPR2
        inx
        bsr TERM
        jsr ADD
        bra EXPR1
EXPR2   cmpa  #'-'
        bne EXPR3
        inx
        bsr TERM
        jsr SUB
        bra EXPR1
EXPR3   rts

MPY     bsr MDSIGN
        ldaa  #15
        staa  0,x
        clrb
        clra
MPY4    lsr 3,x
        ror 4,x
        bcc MPY5
        addb  2,x
        adca  1,x
        bcc MPY5
MPYERR  ldaa  #2
        jmp ERROR
MPY5    asl 2,x
        rol 1,x
        dec 0,x
        bne MPY4
        tsta
        bmi MPYERR
        tst TSIGN
        bpl MPY6
        jsr NEGAB
MPY6    stab  4,x
        staa  3,x
        jsr PULLX
        rts

MDSIGN  jsr PUSHX
        clra
        ldx AESTK
        tst 1,x
        bpl MDS2
        bsr NEG
        ldaa  #$80
MDS2    inx
        inx
        stx AESTK
        tst 1,x
        bpl MDS3
        bsr NEG
        adda  #$80
MDS3    staa  TSIGN
        dex
        dex
        dex
        rts

DIV     bsr MDSIGN
        tst 1,x
        bne DIV33
        tst 2,x
        bne DIV33
        ldab  #8
        jmp ERROR
DIV33   ldaa  #1
DIV4    inca
        asl 2,x
        rol 1,x
        bmi DIV5
        cmpa  #17
        bne DIV4
DIV5    staa  0,x
        ldaa  3,x
        ldab  4,x
        clr 3,x
        clr 4,x
DIV163  subb  2,x
        sbca  1,x
        bcc DIV165
        addb  2,x
        adca  1,x
        clc
        bra DIV167
DIV165  sec
DIV167  rol 4,x
        rol 3,x
        lsr 1,x
        ror 2,x
        dec 0,x
        bne DIV163
        tst TSIGN
        bpl DIV169
        bsr NEG
DIV169  jsr PULLX
        rts

NEG     psha
        pshb
        jsr PULLAE
        bsr NEGAB
        jsr PUSHAE
        pulb
        pula
        rts

NEGAB   coma
        comb
        addb  #1
        adca  #0
        rts

SUB     bsr NEG
ADD     jsr PULLAE
ADD1    stab  BNUMB
        staa  ANUMB
        jsr PULLAE
        addb  BNUMB
        adca  ANUMB
        jsr PUSHAE
        clc
        rts

FINDNO  ldaa  HIGHLN
        ldab  HIGHLN+1
        subb  PACKLN+1
        sbca  PACKLN
        bcs  HIBALL
FINDN1  ldx  SOURCE
FIND0   jsr PULPSH
        subb  1,x
        sbca  0,x
        bcs FIND3
        bne FIND1
        tstb
        beq  FIND4
FIND1   inx
FIND2   bsr  INXSKP
        cmpa  #$1E
        bne  FIND2
        inx
        cpx NEXTBA
        bne FIND0
HIBALL  ldx  NEXTBA
FIND3   sec
FIND4   stx WORKBA
        jsr PULPSH
        rts

SKIPSP  ldaa  0,x
        cmpa  #$20
        bne  SKIPEX
INXSKP  inx
        bra SKIPSP
SKIPEX  rts

LINENO  jsr INTSTN
        bcc  LINE1
        ldab  #7
        jmp  ERROR
LINE1   jsr PULPSH
        staa  PACKLN
        stab  PACKLN+1
        stx BUFNXT
        rts

NXTLIN  ldx  BASPNT
NXTLI2  ldaa  0,x
        inx
        cmpa  #$1E
        bne  NXTLI2
        stx BASLIN
        rts

CCODE   bsr SKIPSP
        stx INDEX4
        sts SAVESP
        ldx #COMMAN-1
LOOP3   lds  INDEX4
LOOP4   inx
        pula
        ldab  0,x
        cmpb  #$1E
        beq LOOP7
        cba
        beq  LOOP4
LOOP5   inx
        cpx #COMEND
        beq CCEXIT
        ldab  0,x
        cmpb  #$1E
        bne  LOOP5
LOOP6   inx
        inx
        bra LOOP3
LOOP7   inx
        sts BUFNXT
        sts BASPNT
LOOP8   lds SAVESP
        rts

CCEXIT  lds SAVESP
        ldx #IMPLET
        rts

START   ldx SOURCE
        stx NEXTBA
        stx WORKBA
        stx ARRTAB
        dex
        clra
START2  inx
        staa  0,x
        cpx MEMEND
        bne  START2
START1  clra
        staa  PACKLN
        staa  PACKLN+1
        staa  PRCNT
        ldx PACKLN
        stx HIGHLN
READY   lds #$7F45
        ldx #RDYMSG
        jsr OUTPUT
NEWLIN  lds #$7F45
        ldx #$7F7F
        stx XSTACK
        clr PRCNT
NEWL3   jsr CNTLIN
        ldx #BUFFER
        jsr SKIPSP
        stx BUFNXT
        jsr TESTNO
        bcs LOOP2
        jmp NUMBER
LOOP2   cmpa  #$1E
        beq NEWLIN
        jsr CCODE
        ldx 0,x
        jmp  0,x

ERROR   lds #$7F45
        jsr CRLF
        ldx #ERRMS1
        jsr OUTNCR
        clra
        jsr PUSHAE
        jsr PRN
        ldx #ERRMS2
        jsr OUTNCR
        clrb
        ldaa  BASLIN
        beq ERROR2
        ldx BASLIN
        ldaa  0,x
        ldab  1,x
ERROR2  jsr PRN0
        jsr CRLF
        bra READY

RUN     ldx  SOURCE
        stx BASLIN
        ldx #SBRSTK
        stx SBRPNT
        ldx #FORSTK
        stx FORPNT
        ldx #$7F7F
        stx XSTACK
        ldx NEXTBA
        stx ARRTAB
        clra
        dex
RUN1    inx
        staa  0,x
        cpx MEMEND
        bne RUN1
        ldx #VARTAB
        ldab   #78
RUN2    staa  0,x
        inx
        decb
        bne RUN2
        jmp  BASIC

CLIST   ldx #PGCNTL
        jsr OUTPUT
        ldx  BASPNT
        dex
CLIST1  jsr SKIPSP
        cmpa  #$1E
        beq CLIST4
        jsr INTSTN
        stx BASPNT
        jsr FINDN1
        stx INDEX3
        ldx BASPNT
        psha
        jsr SKIPSP
        cmpa  #$1E
        pula
        bne CLIST2
        jsr PUSHAE
        bra  CLIST3
CLIST2  inx
        jsr  INTSTN
CLIST3  clra
        ldab  #1
        jsr ADD1
        jsr FINDN1
        jsr LIST0
        bra CLIST5
CLIST4  jsr  LIST
CLIST5  jmp  REMARK
        nop

PATCH   jsr  NXTLIN
        ldx #BASIC
        stx $7F46
        lds #$7F40
        sts SP
SP      equ $7F08
        jmp CONTRL
CONTRL  equ  $F400

NUMBER  jsr LINENO
NUM1    jsr FINDNO
        bcc DELREP
        ldx WORKBA
        cpx NEXTBA
        beq CAPPEN
        bsr INSERT
        bra NEXIT
DELREP  ldx BUFNXT
        jsr SKIPSP
        cmpa  #$1E
        bne REPLAC
        ldx NEXTBA
        cpx SOURCE
        beq NEXIT
        bsr DELETE
        bra NEXIT

REPLAC  bsr DELETE
        bsr INSERT
NEXIT   jmp NEWLIN
CAPPEN  bsr INSERT
        ldx PACKLN
        stx HIGHLN
        bra NEXIT
DELETE  sts SAVESP
        ldx WORKBA
        lds NEXTBA
        ldab  #2
        inx
        inx
        des
        des
DEL2    ldaa   0,x
        des
        inx
        incb
        cmpa  #$1E
        bne DEL2
        sts NEXTBA
        sts ARRTAB
        ldx WORKBA
        stab  DEL5+1
* IN AT OBJECT TIME
DEL4    cpx  NEXTBA
        beq  DELEX
DEL5    ldaa  0,x
        staa  0,x
        inx
        bra DEL4

DELEX   lds SAVESP
        rts

INSERT  ldx BUFNXT
        jsr  CCODE
INS1    stx  KEYWD
        ldab  ENDBUF+1
        subb  BUFNXT+1
        addb  #$04
        stab  OFFSET+1
        addb  NEXTBA+1
        ldaa  #$00
        adca  NEXTBA
        cmpa  MEMEND
        bhi OVERFL
        stab  NEXTBA+1
        staa  NEXTBA
        ldx NEXTBA
        stx  ARRTAB
INS2    cpx  WORKBA
        beq BUFWRT
        dex
        ldaa  0,x
OFFSET  staa  0,x
        bra  INS2
BUFWRT  ldx  WORKBA
        sts SAVESP
        ldaa  PACKLN
        staa  0,x
        inx
        ldaa  PACKLN+1
        staa  0,x
        inx
        ldaa  KEYWD+1
        staa  0,x
        inx
        lds BUFNXT
        des
BUF3    pula
        staa  0,x
        inx
        cmpa  #$1E
        bne BUF3
        lds SAVESP
        rts

OVERFL  ldab  #14
        jmp ERROR
BASIC   ldx BASLIN
        cpx NEXTBA
        bne BASIC1
BASIC0  jmp READY
BASIC1  tst BASLIN
        beq BASIC0
        inx
        inx
        ldaa  0,x
        inx
        stx  BASPNT
        ldx #COMMAN
        stx KEYWD
        staa  KEYWD+1
        ldx #ASTACK
        stx AESTK
        ldx KEYWD
        ldx 0,x
BASIC2  jmp 0,x

GOSUB   ldx BASLIN
        stx INDEX1
        jsr NXTLIN
        ldx SBRPNT
        cpx #SBRSTK+16
        bne  GOSUB1
        ldab  #9
        jmp  ERROR
GOSUB1  ldaa  BASLIN
        staa  0,x
        inx
        ldaa  BASLIN+1
        staa  0,x
        inx
        stx SBRPNT
        ldx INDEX1
        stx BASLIN
GOTO    ldx BASPNT
        jsr EXPR
        jsr FINDN1
        bcc GOTO2
        ldab  #7
        jmp  ERROR
GOTO2   stx BASLIN
        bra  BASIC

RETURN  ldx  SBRPNT
        cpx #SBRSTK
        bne RETUR1
        ldab  #10
        jmp  ERROR
RETUR1  dex
        dex
        stx SBRPNT
        ldx  0,x
        stx BASLIN
        bra BASIC

PAUSE   ldx  #PAUMSG
        jsr OUTNCR
        jsr PRINSP
        ldx  BASLIN
        ldaa  0,x
        inx
        ldab  0,x
        inx
        jsr  PRN0
PAUSE1  jsr  INCH
        cmpa  #$0D
        bne  PAUSE1
        jsr  CRLF
PAUSE2  jmp  REMARK
INPUT   ldaa   BASPNT
        bne INPUT0
        ldab  #12
        bra INPERR
INPUT0  jsr KEYBD
        ldx  #BUFFER
        stx BUFNXT
        ldx BASPNT
INPUT1  jsr TSTV
        bcs INPEX
        stx BASPNT
        ldx BUFNXT
INPUT2  bsr  INNUM
        bcc INPUT4
        dex
        ldaa  0,x
        cmpa  #$1E
        beq INPUTS
        ldab  #2
INPERR  jmp  ERROR
INPUTS  jsr  KEYBD
        ldx #BUFFER
        bra INPUT2
INPUT4  jsr  STORE
        inx
        stx BUFNXT
        ldx BASPNT
        jsr SKIPSP
        inx
        cmpa  #','
        beq INPUT1
INPEX   dex
        clr PRCNT
        cmpa  #$1E
        beq PAUSE2
DBLLTR  ldab  #3
        jmp  ERROR
TSTN    bsr INTSTN
        bcs TSTN0
        jsr PULLAE
        tsta
        bpl TSTN1
TSTN0   sec
        rts
TSTN1   jsr  PUSHAE
        rts

INNUM   jsr  SKIPSP
        staa  TSIGN
        inx
        cmpa  #'-'
        beq  INNUM0
        dex
INTSTN  clr  TSIGN
INNUM0  jsr   SKIPSP
        jsr TESTNO
        bcc INNUM1
        rts
INNUM1  dex
        clra
        clrb
INNUM2  inx
        psha
        ldaa  0,x
        jsr TESTNO
        bcs INNEX
        suba  #$30
        staa  TNUMB
        pula
        aslb
        rola
        bcs INNERR
        stab  BNUMB
        staa  ANUMB
        aslb
        rola
        bcs INNERR
        aslb
        rola
        bcs INNERR
        addb  BNUMB
        adca  ANUMB
        bcs INNERR
        addb  TNUMB
        adca  #0
        bcc  INNUM2
INNERR  ldab  #2
        jmp  ERROR
INNEX   pula
        tst TSIGN
        beq INNEX2
        jsr NEGAB
INNEX2  jsr PUSHAE
        clc
        rts

PRINT   ldx  BASPNT
PRINT0  jsr  SKIPSP
        cmpa  #'"'
        bne PRINT4
        inx
PRINT1  ldaa  0,x
        inx
        cmpa   #'"'
        beq  PRIN88
        cmpa  #$1E
        bne PRINT2
        ldab   #4
        bra  PRINTE
PRINT2  jsr  OUTCH
        jsr ENLINE
        bra PRINT1
PRINT4  cmpa  #$1E
        bne PRINT6
        dex
        ldaa  0,x
        inx
        cmpa  #';'
        beq PRINT5
        jsr CRLF
        clr PRCNT
PRINT5  inx
        stx BASLIN
        jmp BASIC
PRINT6  cmpa  #'T'
        bne PRINT8
        ldab  1,x
        cmpb  #'A'
        bne PRINT8
        inx
        inx
        ldaa  0,x
        cmpa  #'B'
        beq PRINT7
        ldab  #11
PRINTE  jmp  ERROR
PRINT7  inx
        jsr EXPR
        jsr PULLAE
        subb  PRCNT
        bls PRIN88
PRIN77  jsr PRINSP
        bsr ENLINE
        decb
        bne PRIN77
        bra PRIN88
PRINT8  jsr  EXPR
        jsr  PRN
PRIN88  jsr  SKIPSP
        cmpa  #','
        bne PRIN99
        inx
PRLOOP  ldaa  PRCNT
        tab
        andb  #$F8
        sba
        beq PRI999
        jsr PRINSP
        bsr ENLINE
        bra PRLOOP
PRIN99  cmpa  #';'
        bne PREND
        inx
PRI999  jmp  PRINT0
PREND   cmpa  #$1E
        beq PRINT4
        ldab  #6
        bra PRINTE
ENLINE  psha
        ldaa  PRCNT
        inca
        cmpa  MAXLIN
        bne ENLEXT
        jsr CRLF
        clra
ENLEXT  staa  PRCNT
        pula
        rts
PRN     jsr PRINSP
        bsr ENLINE
        ldaa  #$FF
        staa  TSIGN
        jsr PULLAE
        tsta
        bpl PRN0
        jsr NEGAB
        psha
        ldaa  #'-'
        jsr OUTCH
        bsr ENLINE
        pula
PRN0    jsr  PUSHX
        ldx #KIOK
PRN1    clr  TNUMB
PRN2    subb  1,x
        sbca  0,x
        bcs PRN5
        inc TNUMB
        bra PRN2
PRN5    addb  1,x
        adca  0,x
        psha
        ldaa  TNUMB
        bne PRN6
        cpx #KIOK+8
        beq PRN6
        tst TSIGN
        bne PRN7
PRN6    adda  #$30
        clr TSIGN
        jsr OUTCH
        bsr ENLINE
PRN7    pula
        inx
        inx
        cpx #KIOK+10
        bne PRN1
        jsr PULLX
        rts

KIOK    fdb 10000
        fdb 1000
        fdb 100
        fdb 10
        fdb 1

LET     ldx BASPNT
        jsr TSTV
        bcc LET1
LET0    ldab  #12
LET00   jmp  ERROR
LET1    jsr  SKIPSP
        inx
        cmpa  #'='
        beq LET3
LET2    ldab  #6
        bra LET00
LET3    jsr EXPR
        cmpa  #$1E
        bne LET2
        jsr STORE
        bra REMARK
SIZE    ldab  ARRTAB+1
        ldaa  ARRTAB
        subb  SOURCE+1
        sbca  SOURCE
        jsr PRN0
        jsr PRINSP
        ldab  MEMEND+1
        ldaa  MEMEND
        subb  ARRTAB+1
        sbca  ARRTAB
        jsr PRN0
        jsr CRLF
REMARK  jsr NXTLIN
        jmp BASIC
DIM     ldx BASPNT
DIM1    jsr SKIPSP
        jsr TSTLTR
        bcc DIM111
        jmp DIMEX
DIM111  suba  #$40
        staa  DIMVAR+1
        asla
        adda  DIMVAR+1
        staa  DIMVAR+1
        jsr PUSHX
        ldx DIMVAR
        tst 0,x
        bne DIMERR
        tst 1,x
        bne DIMERR
        tst 2,x
        bne DIMERR
        ldaa  ARRTAB+1
        staa  1,x
        ldaa  ARRTAB
        staa  0,x
        staa  2,x
        jsr PULLX
        jsr INXSKP
        cmpa  #'('
        beq  DIM2
DIMERR  ldab  #5
DIMER1  jmp ERROR
DIM2    inx
        jsr EXPR
        jsr PULPSH
        tstb
        beq SUBERR
        tsta
        beq  DIM3
SUBERR  ldab  #15
        bra DIMER1
DIM3    bsr STRSUB
        ldaa  0,x
        cmpa  #','
        bne DIM6
        inx
        jsr EXPR
        jsr PULPSH
        tstb
        beq SUBERR
        tsta
        bne SUBERR
        bsr STRSUB
        jsr MPY
DIM6    clra
        ldab  #2
        jsr PUSHAE
        jsr MPY
        ldaa  0,x
        cmpa  #')'
        bne DIMERR
        inx
        ldab  ARRTAB+1
        ldaa  ARRTAB
        jsr ADD1
        clra
        ldab  #2
        jsr ADD1
        jsr PULLAE
        cmpa  MEMEND
        bls DIM7
        jmp OVERFL
DIM7    staa  ARRTAB
        stab  ARRTAB+1
        jsr SKIPSP
        cmpa  #','
        bne DIMEX
        inx
        jmp DIM1
DIMEX   cmpa  #$1E
        bne DIMERR
        jmp REMARK
STRSUB  jsr PUSHX
        ldx DIMVAR
        ldx 0,x
STRSU2  tst 0,x
        beq STRSU3
        inx
        bra STRSU2
STRSU3  stab  0,x
        jsr PULLX
        rts

FOR     ldx  BASPNT
        jsr TSTV
        bcc FOR1
        jmp LET0
FOR1    stx BASPNT
        jsr PULPSH
        ldx FORPNT
        cpx #FORSTK+48
        bne FOR11
        ldab  #16
        jmp ERROR
FOR11   staa  0,x
        inx
        stab  0,x
        inx
        stx FORPNT
        ldx BASPNT
        jsr SKIPSP
        inx
        cmpa  #'='
        beq  FOR3
FOR2    jmp  LET2
FOR3    jsr EXPR
        jsr STORE
        inx
        cmpa  #'T'
        bne FOR2
        ldaa  0,x
        inx
        cmpa  #'O'
        bne FOR2
        jsr EXPR
        jsr PULLAE
        stx BASPNT
        ldx FORPNT
        staa  0,x
        inx
        stab  0,x
        inx
        stx FORPNT
        ldx BASPNT
        ldaa  0,x
        cmpa  #$1E
FOR8    bne FOR2
        inx
        stx BASLIN
        ldx FORPNT
        ldaa  BASLIN
        staa  0,x
        inx
        ldab  BASLIN+1
        stab  0,x
        inx
        stx FORPNT
        jmp BASIC

NEXT    ldx BASPNT
        jsr TSTV
        bcc NEXT1
        jmp LET0
NEXT1   jsr SKIPSP
        cmpa  #$1E
        bne FOR8
        inx
        stx  BASLIN
        ldx #FORSTK
        jsr PULPSH
NEXT2   cpx FORPNT
        beq NEXT6
        cmpa  0,x
        bne NEXT5
        cmpb  1,x
        bne NEXT5
        jsr IND
        jsr PULPSH
        subb  3,x
        sbca  2,x
        bcs NEXT4
        stx  FORPNT
NEXT3   jmp  BASIC
NEXT4   jsr PULLAE
        addb  #1
        adca  #0
        jsr PUSHX
        ldx 0,x
        staa  0,x
        stab  1,x
        jsr PULLX
        ldx 4,x
        stx BASLIN
        bra  NEXT3
NEXT5   inx
        inx
        inx
        inx
        inx
        inx
        bra NEXT2
NEXT6   ldab  #17
        jmp ERROR

IF      ldx BASPNT
        jsr EXPR
        bsr RELOP
        staa  NCMPR
        jsr EXPR
        stx BASPNT
        bsr CMPR
        bcc IF2
        jmp  REMARK
IF2     ldx  BASPNT
        jsr  CCODE
        ldx 0,x
        jmp 0,x
RELOP   jsr SKIPSP
        inx
        cmpa  #'='
        bne RELOP0
        ldaa  #0
        rts
RELOP0  ldab  0,x
        cmpa  #'<'
        bne RELOP4
        cmpb  #'='
        bne RELOP1
        inx
        ldaa  #2
        rts
RELOP1  cmpb  #'>'
        bne RELOP3
RELOP2  inx
        ldaa  #3
        rts
RELOP3  ldaa  #1
        rts
RELOP4  cmpa  #'>'
        beq REL44
        ldab  #6
        jmp ERROR
REL44   cmpb   #'='
        bne RELOP5
        inx
        ldaa  #5
        rts
RELOP5  cmpb  #'<'
        beq RELOP2
        ldaa  #4
        rts

CMPR    ldaa   NCMPR
        asla
        asla
        staa  FUNNY+1
        ldx #CMPR1
        jsr SUB
        jsr PULLAE
        tsta
FUNNY   jmp  0,x
CMPR1   beq MAYEQ
        bra NOCMPR
        bmi OKCMPR
        bra NOCMPR
        bmi OKCMPR
        bra CMPR1
        bne OKCMPR
        bra MYNTEQ
        beq MYNTEQ
        bmi NOCMPR
        bpl OKCMPR
NOCMPR  sec
        rts
OKCMPR  clc
        rts
MAYEQ   tstb
        beq OKCMPR
        bra NOCMPR
MYNTEQ  tstb
        bne OKCMPR
        bra NOCMPR

END     equ *
        end
