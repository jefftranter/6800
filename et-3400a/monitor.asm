        NAM Heathkit ET-3400A Monitor
        PAGE 132,66

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>.
; Fixed some small errors in the listing.
; Adapted to the crasm assembler (https://github.com/colinbourassa/crasm).
; Note that I do not own an ET-3400A and have no way of testing it.

        CPU 6800

;;      ASSEMBLY CONSTANT TABLE

;;      KEYBOARD LOCATIONS

        COL1  EQU $C003              ; RIGHTMOST COLUMN
        COL2  EQU $C005
        COL3  EQU $C006              ; LEFTMOST COLUMN

;;      MISC CONSTANTS

        TIME EQU 32
        NBR  EQU 4                   ; NUMBER BREAKPOINTS

;;      DISPLAY ADDRESSES

        DG6ADD EQU $C16F             ; LEFTMOST DIGIT
        DG5ADD EQU $C15F
        DG4ADD EQU $C14F
        DG3ADD EQU $C13F
        DG2ADD EQU $C12F
        DG1ADD EQU $C11F             ; RIGHTMOST DIGIT
        

;;      DISPLAYED CHARACTER SEGMENT CODES

        HEX0 EQU $7E
        HEX1 EQU $30
        HEX2 EQU $6D
        HEX3 EQU $79
        HEX4 EQU $33
        HEX5 EQU $5B
        HEX6 EQU $5F
        HEX7 EQU $70
        HEX8 EQU $7F
        HEX9 EQU $7B
        HEXA EQU $77
        HEXB EQU $1F
        HEXC EQU $4E
        HEXD EQU $3D
        HEXE EQU $4F
        HEXF EQU $47
        LTRA EQU $7D
        LTRB EQU $1F
        LTRC EQU $0D
        LTRF EQU $47
        LTRN EQU $15
        LTRI EQU $30
        LTRP EQU $67
        LTRL EQU $0E
        LTRD EQU $3D
        LTRO EQU $1D
        LTRR EQU $05
        LTRU EQU $3E
        LTRY EQU $3B
        LTRS EQU $5B
        DASH EQU $08

        PAGE

;;      RESERVED MEMORY BYTES IN RAM

        DUMMY
        * EQU $00D1

USRSTK  EQU *-6
        DS 19
MONSTK  EQU *-1
BKTBL   DS 2*NBR
T0      DS 2                         ; TEMPORARY
TEMP    DS 2                         ; JSRD BY SINGLE STEPPER
DIGADD  DS 2                         ; DISPLAY POINTER
USERS   DS 2                         ; USER STACK POINTER
T1      EQU TEMP
SYSSWI  DS 3                         ; SYSTEM SWI VECTOR
UIRQ    DS 3                         ; USER IRQ VECTOR
USWI    DS 3                         ; USER SWI VECTOR
UNMI    DS 3                         ; USER NMI VECTOR

        PAGE

;;      MONITOR CODE

        CODE
        * EQU $FC00

;;      RESET - CLEAR BREAKPOINT TABLE AND INITIALIZE STACK
       
RESET   LDS     #2*NBR+BKTBL-1
        JSR     OUTSTO
        DB      HEXC,LTRP,LTRU,0,LTRU,LTRP+$80
        LDX     #USRSTK
        STX     USERS
        LDAA    #$FF
        LDAB    #2*NBR
RESE1   PSHA
        DECB
        BNE     RESE1

;;      MAIN - MAIN MONITOR LOOP
;
;       HANDLERS RETURN:
;               (B) = NUMBER BYTES SUBJECT TO "CHANGE"
;               (X) = ADDRESS BYTES SUBHECT TO "CHANGE"
;               (A) = 0 ENABLES "FORWARD" AND "BACK"

MAIN    STAA    T1
        LDAA    #-MAIN/256*256+MAIN  ; LO ORDER RET.ADDR.
        PSHA
        LDAA    #MAIN/256            ; HI ORDER BYTE RET. ADDR.
        PSHA                         ;   RETURN ONTO STACK
MAIN1   JSR     INCH                 ; GET COMMAND
        TST     T1
        BEQ     MAIN2                ; FORWARD OR BACK OK
        CMPA    #$F
        BEQ     MAIN1                ; ILLEGAL NOW
        CMPA    #$B
        BEQ     MAIN1                ; ALSO ILLEGAL NOW
MAIN2   STX     T0
        LDX     #CMDTAB-2
MAIN3   INX
        INX                          ; GET HANDLER ADDRESS
        DECA
        BPL     MAIN3
        LDAA    1,X                  ; TARGET ADDRESS ONTO STACK
        PSHA
        LDAA    0,X
        PSHA
        LDX     T0                   ; RESTORE X
        LDAA    T1
ZERO    RTS                          ; JUMP TO HANDLER


;;      RESET - ENTRY FOR BREAKPOINT TABLE
;
;       ENTRY:  NONE
;       EXIT    (B) = 2
;               (X) = ADDRESS IN TABLE
;       USES: ALL,TO,11

BKSET   LDX     #BKTBL-2
        LDAA    #$FF
        LDAB    #NBR                 ; FIND SPOT IN TABLE
BKSE1   INX
        INX
        CMPA    0
        BNE     BKSE2
        CMPA    1,X
        BEQ     BKSE3                ; EMPTY SPOT
BKSE2   DECB
        BNE     BKSE1                ; STILL HOPE

;       FULL UP

        JSR     OUTSTO
        DB      0,LTRF,LTRU,LTRL,LTRL,$A0
        INCA
        RTS

BKSE3   STX     T1
        BSR     OUTSTA
        DB      LTRB,LTRR+$80
        BSR     DOPM1
        INCA                         ; (A) = 1
        RTS

;;      DOPPMT - ACCEPT ADDRESS VALUE WITH "DO" PROMPT
;
;       ENTRY:   (X) = ADDRESS TO STORE INPUTTED VALUE
;       EXIT:    (B) = 2
;                (X) UNCHANGED
;       USES:    ALL,TO,T1

DOPMT   STX      T1
        BSR      OUTSTA              ; OUTPUT PROMPT "DO"
        DB       LTRD,LTRO+$80
DOPM1   BSR      REDIS               ; RESET DISPLAY
        LDX      T1                  ; RESTORE X
        LDAB     #2
        JMP      PROMPT              ; INPUT NEW VALUE

;;      ADDR - ACCEPT ADDRESS VALUE WITH 'AD' PROMPT
;
;       ENTRY, EXIT -- SEE 'DOPMT'

ADDR    STX      T1
        BSR      OUTSTA
        DB       HEXA,LTRD+$80
        BRA      DOPM1

;;      OUTSTA - OUTPUT STRING FOR ADDRESS PROMPT
;

OUTSTA  LDX      #DG2ADD
        JMP      OUTST1

;;      DO - RESET USER PC AND RESUME
;
;       ENTRY:  NONE
;       EXIT:   TO 'RESUME'
;       U:      ALL

DO      LDX     USERS
        INX
        INX
        INX
        INX
        INX
        INX                          ; X TO USER PC
        BSR     DOPMT

;;      RESUME - RESUME USER PROGRAM
;
;       1) BLANKS ALL DISPLAYS
;       2) INITIALIZES (DIGADD)
;       3) STEPS USER CODE PAST BREAKPOINT
;       4) INSERTS BREAKPOINTS
;       5) PRINTS INSTRUCTION UPON RETURN
;       ENTRY:NONE
;       EXIT: (B) = 1
;             (X) = USERPC
;       USES  ALL,TO,T1

RESUME  BSR     REDIS                ; RESET DISPLAY
        CLRA
        LDAB    #6
RES1    JSR     OUTCH                ; CLEAR DISPLAYS
        DECB
        BNE     RES1
        BSR     REDIS                ; RESET DISPLAY
RES2    JSR     SSTEP                ; STEP PAST BREAKPOINT
        LDAB    #NBR                 ; SET BREAKPOINTS
RES3    TSX
        LDX     2*NBR,X              ; GET BREAKPOINT ADDRESS

        LDAA    0,X
        PSHA
        PSHA
        LDAA    #$3F                 ; REPLACE WITH SWI
        STAA    0,X
        DECB
        BNE     RES3
        LDX     #BKPT
        JMP     SWIVE1               ; GO TO USER CODE

;;      REDIS - RESET DISPLAYS
;
;       ENTRY:  NONE
;       EXIT:   DIGADD SET TO LEFTMOST DIGIT
;       USES:   T0

REDIS   STX     T0
        LDX     #DG6ADD
        STX     DIGADD
        LDX     T0
        RTS

;;      BADDR - BUILD ADDRESS
;
;       ENTRY:  NONE
;       EXIT    (X) = ADDRESS

BADDR   LDX     #T1
        BSR     ADDR
        LDX     T1
        RTS

;;      BKPT - BREAK POINT RETURN
;       1) REMOVE BKPTS FROM USER CODE
;       2) CHECK FOR BREAKPOINT HIT AND EITHER
;           A)  RESUME IF NO HIT
;           B)  PRINT INSTRUCTION AND RETURN IF HIT

BKPT    TSX
        STS     USERS
        LDAA    6,X
        BNE     BKP1                 ; DECREMENT PC ON USERS STACK
        DEC     5,X
BKP1    DECA
        STAA    6,X
        LDAB    5,X
        STAB    T0                   ; SAVE FOR COMPARE
        STAA    T0+1

;;      NOW CLEAR BREAKPOINTS

        CLC                          ; 'C' IS HIT FLAG
BKP2    LDS     #BKTBL-3-NBR-NBR

        LDAB    #NBR
BKP3    PULA
        PULA                         ; OLD OP CODE INTO A
        TSX
        LDX     2*NBR,X
        CPX     T0                   ; DO WE HAVE A HIT?
        BNE     BKP4                 ;    NO WE DO NOT
        SEC                          ;       YES WE DO - SET FLAG
BKP4    EQU     *
        STAA    0,X                  ; FIX USER CODE
        DECB
        BNE     BKP3
        BCC     RES2                 ; BREAKPOINT NOT HIT
        LDX     T0                   ;  = USER PC

;;      MEM - DISPLAY ADDRESS AND DATA
;
;       ENTRY:  (X) = ADDRESS
;       EXIT:   (B) = 1
;       USES: A,B,C,T0,T1

MEM     BSR   REDIS                  ; RESET DISPLAY
        STX   T1
        LDX   #T1
        LDAB  #2
        BSR   MEM2                   ; DISPLAY ADDRESS
        LDX   0,X
        DECB
MEM2    JMP   DSPLAY                 ; OUTPUT DATA

;;      AUTO - AUTO LOAD OF MEMORY
;
;       ENTRY: NONE
;       EXIT:  NO EXIT POSSIBLE
;       USES:  ALL,T0,T1

AUTO    BSR    BADDR                 ; BUILD ADDRESS
AUT1    BSR    MEM
        BSR    REPLAC
        INX
        BRA     AUT1                 ; NO EXIT

;;      EXAM - EXAMINE MEMORY
;
;       ENTRY:  NONE
;       EXIT:   (X) = ADDRESS
;               (B) = 0
;               (A) = 0
;       USES:   ALL,T0,T1

EXAM    BSR     BADDR                ; BUILD ADDRESS
        DEX

;;      FOWD - DISPLAY NEXT BYTE
;
;       ENTRY:  (X) = OLD ADDRESS
;       EXIT:   (X) = (XOLD) + 1
;               (B) = 1
;               (A) = 0
;       USES:   ALL,T0

FOWD    INX
        INX

;;      BACK - DISPLAY PREVIOUS BYTE
;
;       ENTRY:  (X) = ADDRESS
;       EXIT:   (X) = (XOLD) + 1
;               (B) = 1
;               (A) = 0
;       USES:   ALL,T0
BACK    DEX
        BRA     MEM                  ; DISPLAY ADDRESS AND DATA

;;      REPLAC - REPLACE DISPLAYED VALUE
;
;       'REPLAC' 1) BACKSPACES DISPLAY TO CANCEL DISPLAYED VALUE
;                2) SENDS PROMPT FOR REPLACEMENT VALUE
;                3) ACCEPTS AND REPLACES DESIGNATED BYTE(S)
;       ENTRY:  (X) = ADDRESS OF BYTE(S) TO REPLACE
;               (B) = NUMBER OF BYTES
;               (DIGIADD) = ADDRESS OF DIGIT TO RIGHT OF DISPLAYED
;       EXIT:   B,X,DIGADD UNCHANGED
;       USES:   T0,A,C

REPLAC  TSTB
        BEQ     REPL1                ; NO BYTES
        PSHA
        BSR     BKSP                 ; BACKSPACE DISPLAYS
        BSR     PROMPT
        PULA
REPL1   RTS


;;      PROMPT - PROMPT AND INPUT BYTES
;
;       ENTRY:  (X) = ADDRESS TO STORE VALUE
;               (B) = NUMBER OF BYTES
;               (DIGADD) = ADDRESS OF FIRST ECHO CHARACTER
;       EXIT:   B,X UNCHANGED
;               DIGADD UPDATED
;       USES:   T0, DIGADD

PROMPT  PSHB
        LDAA    #DASH                ; PROMPT CHARACTER
        ASLB
PROM1   JSR     OUTCH                ; SEND PROMPT

        DECB
        BNE     PROM1
        PULB
        BSR     BKSP                 ; BACKSPACE DISPLAYS
        PSHB                         ; **ALTERNATE ENTRY**
PROM2   JSR     IHB                  ; GET BYTE VALUE
        STAA    0,X                  ; PLACE INTO MEMORY
        INX                          ; BUMP POINTER
        DECB
        BNE     PROM2                ; MORE TO GO
        PULB
        TBA                          ; DUPLICATE
PROM3   DEX                          ; FIX X
        DECA
        BNE     PROM3
        RTS                          ; EXIT


;;      BKSP - BACKSPACE DISPLAYS
;
;       ENTRY: (B) = NUMBER DIGIT PAIRS TO BACKSPACE
;       EXIT:  (DIGADD) = (DIGADD) + 20 * (B)
;       USES:  A,C

BKSP    PSHB
        LDAA    DIGADD+1             ; L.S. BYTE
BKSP1   ADDA    #$20                 ; BACKSPACE TWO PLACES
        DECB
        BNE     BKSP1
        STAA    DIGADD+1
        PULB
        RTS

;;      REGISTER DISPLAY FUNCTIONS
;
;       ENTRY:  NONE
;       EXIT:   (B) = NUMBER BYTES THIS REGISTER
;               (X) = REGISTER ADDRESS ON STACK
;               (DIGADD) INITIALIZED TO DIGIT 6
;       USES:   ALL,T0

REGX    BSR     OUTSTJ               ; PRINT 'REGX'
        DB      LTRI,LTRN+$80
        BRA     REGX1

REGA    BSR     OUTSTJ               ; PRINT 'ACCA'
        DB      HEXA,LTRC,LTRC,LTRA+$80
        BRA     REGA1

REGB    BSR     OUTSTJ               ; PRINT 'ACCB'
        DB      HEXA,LTRC,LTRC,LTRB+$80
        BRA     REGB1

REGP    BSR     OUTSTJ               ; PRINT 'PC'
        DB      LTRP,LTRC+$80

        INCA
        INCA
REGX1   INCB
        INCA
REGA1   INCA
REGB1   INCB
        ADDA    #2

        LDX     USERS                ; POINT X TO REGISTER
REG1    INX
        DECA
        BNE     REG1
        BSR     DSPLAY
        INCA
        RTS

;;      DISPLAY - DISPLAY INDEXED BYTES
;
;       ENTRY:  (X) = ADDRESS OF BYTES TO OUTPUT
;               (B) = NUMBER OF BYTES TO DISPLAY
;       EXIT:   X,B UNCHANGED
;               (DIGADD) UPDATED
;       USES:   ALL, T0

DSPLAY  PSHB
DIS1    LDAA    0,X                  ; GET BYTE
        JSR     OUTBYT               ; DISPLAY BYTE
        INX
        DECB
        BNE     DIS1
        PULB
        TBA                          ; DUPLICATE BYTE COUNT
DIS2    DEX
        DECA
        BNE     DIS2
        RTS

;       CLEAR B AND JUMP TO OUTSTR

OUTSTJ  CLRB
OUTSTO  LDX     #DG6ADD
        JMP OUTST1

;;      CONDX - DISPLAY CONDITION CODES
;
;       ENTRY:  DIGADD INITIALIZED
;       EXIT:   (B) = 0
;       USES:   ALL,T0

CONDX   JSR     REDIS                ; RESET DISPLAYS
        LDX     USERS
        LDAB    #$20
COND0   CLRA
        BITB    1,X                  ; MASK DESIRED BIT

        BEQ     COND1                ; IS A ZERO
        INCA                         ; IS A ONE
COND1   JSR     OUTHEX
        RORB
        BNE     COND0                ; MORE TO DO
        INCA
        RTS

;;      STKPTR - OUTPUT USER STACK POINTER
;
;       ENTRY:  (DIGADD) INITIALIZED
;       EXIT:   (B) = 0
;       USES: ALL, T0

REGS    EQU     *
STKPTR  BSR     OUTSTJ
        DB      LTRS,LTRP+$80
        LDAB    USERS+1
        ADDB    #7
        ADCA    USERS                ; CLEAN UP FOR THE USER
        BSR     OUTBYT
        TBA
        CLRB
        BSR     OUTBYT
        LDAA    #1
        RTS

;;      ENCODE - SCAN END ENCODE KEYBOARD
;
;       ENTRY:  NONE
;       EXIT:   (A) = HEX VALUE OF KEY PRESSED
;               'C' SET FOR VALID CONDITION
;       USES:   A,T,T0

ENCODE  PSHB
        LDAB    COL1                 ; GET KEYBOARD DATA
        LDAA    COL3
        ASLA
        ASLA
        ASLA
        ROLB
        ASLA
        ROLB
        ASLA
        ROLB
        PSHB
        LDAB    COL2                 ; GET LAST DATA
        ANDB    #$1F                 ; MASK ANY GARBAGE
        ABA
        PULB
        COMA
        COMB

;       (B4) IS NOW KEYBOARD PATTERN

        STX     T0
        LDX     #HEXTAB-1            ; TABLE OF POSSILE OUTPUTS
        CBA                          ; FIND ACTIVE ACCUMULATOR
        BEQ     ENC3                 ; ILLEGAL OR NO KEY
        BCC     ENC1                 ; A ACTIVE
        PSHA                         ; B ACTIVE
        TBA                          ;     INTERCHANGE B,A
        PULB
        LDX     #HEXTAB+7
ENC1    TSTB                         ; B SHOULD BE ZERO
        BNE     ENC3                 ; ILLEGAL
ENC2    INX                          ; SCAN FOR ACTIVE BIT
        ASLA
        BHI     ENC2                 ; NOT ACTIVE BIT
        BEQ     ENC4                 ; LEGAL CHARACTER
ENC3    CLC                          ; ILLEGAL RETURNS 'C' CLEAR
ENC4    LDAA    0,X                  ; GET HEX FROM TABLE
        LDX     T0
        PULB                         ; CLEAN UP
        RTS                          ;   AND RETURN


;;      INCH - INPUT CHARACTER FROM KEYBOARD
;
;         'INCH' WAITS FOR A TRANSITION BETWEEN ILLEGAL AND
;            LEGAL KEYBOARD CONDITIONS, AND RETURNS HEX VALUE
;               OF KEY DEPRESSED
;
;       ENTRY:  NONE
;       EXIT:   (A) = HEX VALUE
;       USES:   A,T,T0

INCH    PSHB
INC1    LDAB    #TIME                ; VIOLATION COUNT
INC2    BSR     ENCODE               ; WAIT FOR ILLEGAL INTERVAL
        BCS     INC1                 ; STILL LEGAL
        DECB
        BNE     INC2                 ; NOT A FELONY

;       NOW WE'RE SURE WE HAVE AN ILLEGAL CONDITION AND
;       NOT JUST A RELEASE CONTACT BOUNCE

INC3    LDAB    #TIME                ; TIME UNTIL PAROLE
INC4    BSR     ENCODE
        BCC     INC3                 ; BAD BEHAVIOR
        DECB
        BNE     INC4                 ; BACK IN THE SLAMMER
        PULB
        RTS

;;      IHB - INPUT HEX BYTE AND DISPLAY ON LEDS
;
;       ENTRY: NONE
;       EXIT:  (A) = BYTE VALUE
;              (DIGADD) UPDATED
;       USES: A,T0,C

IHB     BSR     INCH                 ; GET FIRST HALF
        BSR     OUTHEX               ; ECHO TO DISPLAYS
        ASLA
        ASLA
        ASLA
        ASLA
        PSHB
        TAB
        BSR     INCH                 ; GET NEXT HALF
        BSR     OUTHEX               ; ECHO TO DISPLAYS
        ABA
        PULB
        PSHA
IHB1    BSR     ENCODE               ; WAIT FOR KEY RELEASE
        BCS     IHB1
        PULA                         ; RESTORE LEGAL ENTRY
        RTS

;;      OUTBYT - OUTPUT TWO HEX DIGITS
;
;       ENTRY:  (A) = BYTE VALUE TO OUTPUT
;       EXIT:   (DIGADD) UPDATED
;       USES:   C,T0

OUTBYT  PSHA
        LSRA
        LSRA
        LSRA
        LSRA
        BSR     OUTHEX               ; OUTPUT M.S. FOUR BITS
        PULA

;;      OUTHEX - OUTPUT HEX DIGIT
;
;       ENTRY: (A) = HEX VALUE
;       EXIT: (DIGADD UPDATED)
;       USES: C,T0

OUTHEX  PSHA
        ANDA    #$F                 ; MASK GARBAGE
        STX     T0
        LDX     #DISTAB-1           ; DISPLAY CODE TABLE
OUTH1   INX
        DECA
        BPL     OUTH1
        LDAA    0,X                 ; DISPLAY CODE FOR HEX
        BSR     OUT0                ; ALTERNATE ENTRY FOR 'OUTCH'
        PULA
        RTS

;;      OUTCH - OUTPUT CHARACTER TO DISPLAY
;
;       ENTRY: (A) = SEGMENT CODE
;              (DIGADD) = ADDRESS OF DIGIT TO OUTPUT
;       EXIT:  (DIGADD) UPDATED
;       USES: C,T0

OUTCH   STX     T0
OUT0    LDX     DIGADD              ; **ALTERNATE ENTRY** FROM 'OUTHEX'
        PSHB
        ROLA
        ROLA                        ; PRE-ROTATE A
        LDAB    #$10                ; TO GET NEXT DIGIT
OUT1    ROLA                        ; HERE WE MAKE TWO PASSES AT
        STAA    0,X                 ;    LIGHTING DIGITS--
        DEX                         ;       KING'S X ON FIRST PASS!!
        DECB
        BNE     OUT1
        STX     DIGADD              ; UPDATE 'DIGADD'
        LDX     T0                  ; RESTORES X
        PULB
        RTS

;;      OUTSTR--OUTPUT IMBEDDED CHARACTER STRING
;          CALLING CONVENTION:
;               JSR     OUTSTR
;               FIRST CHARACTER
;                    *
;                    *
;               LAST CHARACTER (AS D.P. LIT)
;               NEXT INSTRUCTION
;
;       ENTRY:  NONE
;       EXIT:   TO 'NEXT INSTRUCTION'
;               (A0) = 0
;       USES:   A,X,T0

OUTST1  STX     DIGADD              ; **ALTERNATE ENTRY** SETS UP DIGADD
OUTSTR  TSX                         ; POINT 'X' AT STRING
        LDX     0,X
        INS
        INS
OUTST3  LDAA    0,X                 ; GET CHARACTER
        BSR     OUTCH               ; OUTPUT IT TO DISPLAYS
        INX
        TSTA                        ; LAST CHARACTER IS NEGATIVE
        BPL     OUTST3
        CLRA
        JMP     0,X                 ; RETURN TO 'NEXT INST.'

;;      STEP - STEP USER CODE
;
;       ENTRY:  NONE
;       EXIT:   (B) = 1
;               (X) = USER P.C.
;               (A) = 0
;       USES:   ALL,T0,T1
STEP    BSR     SSTEP               ; STEP USER CODE
        LDX     USERS               ; DISPLAY INSTRUCTION
        LDX     6,X
        JMP     MEM

;;      SSET - PERFORM SINGLE STEP.
;

SSTEP   STS     TEMP                 ; WE'LL USE THIS WHEN WE RETURN
        LDX     USERS
        LDAA    7,X                  ; PUSHING USER PC ONTO MONITOR
        PSHA                         ;   STACK
        LDAA    6,X
        PSHA
        LDX     6,X                  ; NOW GET USER PC INTO X
        LDAA    #$3F                 ; SWI'S ARE NORMAL EXIT FROM
        PSHA                         ;   SCRATCHPAD EXECUTION
        PSHA
        LDAA    2,X                  ; NOW WE ARE COPYING THREE BYTES
        PSHA                         ;   OF INSTRUCTION
        LDAA    1,X
        PSHA
        LDAA    0,X                  ; THIS IS THE OP CODE SO
BYTCNT  PSHA                         ;   SCRUTINIZE CAREFULLY
        TAB
        LDX     #OPTAB-1
BYT1    INX
        SUBB    #8
        BCC     BYT1
        LDAA    0,X
BYT2    RORA
        INCB
        BNE     BYT2
        PULA
        PSHA
        BCS     BYT7
        CMPA    #$30                 ; CHECK FOR BRANCH
        BCC     BYT3
        CMPA    #$20
        BCC     BYT5                 ; IT IS A BRANCH
BYT3    CMPA    #$60
        BCS     BYT6                 ; IT IS ONE BYTE
        CMPA    #$8d
        BEQ     BYT5                 ; IT IS BSR
        ANDA    #$BD
        CMPA    #$8C
        BEQ     BYT4                 ; IS X OR SP IMMEDIATE
        ANDA    #$30                 ; CHECK FOR THREE BYTES
        CMPA    #$30
BYT4    SBCB    #$FF
BYT5    INCB
BYT6    INCB
BYT7    BEQ     BSTRD
        TSX
        BCS     STEP1
        STAB    1,X                  ; BRANCH OFFSET TO 2
STEP1   LDAA    #1
        CMPB    #2
        BGT     STEP3
        BEQ     STEP2                ; TWO BYTES
        STAA    1,X                  ; FOR ONE BYTERS
STEP2   STAA    2,X                  ; NOT FOR THREE BYTERS
STEP3   CLRA                         ; NOW ADD BYTE COUNT TO PC
        ADDB    6,X
        ADCA    5,X
        STAA    5,X
        STAB    6,X

;;      DOES THE INSTRUCTION INVOLE THE PC? IF SO THEN IT
;         MUST BE INTERPRETED

SRCHOP  LDX     USERS
        STAA    6,X
        STAB    7,X                  ; UPDATE PC ON USER STACK
        LDAB    #6
        PULA
        PSHA                         ; GET COPY OF OPCODE
        ANDA    #$CF                 ; IS THIS A SUBROUTINE CALL?
        CMPA    #$8D
        PULA
        BEQ     BSRH
        CMPA    #$6E                 ; IT IS INDEXED JUMP
        BEQ     JPXH
        CMPA    #$7E
        BEQ     JMPH                 ; IT IS EXTENDED JUMP
        CMPA    #$39
        BEQ     RTSH                 ; IT IS RTS
        CMPA    #$3B
        BEQ     RTIH                 ; IT IS RTI
        CMPA    #$3F
        BEQ     SWIH                 ; IT IS SWI
        STS     6,X                  ; AIM USER PC AT SCRATCH AREA
        PSHA                         ; REPLACE OPCODE
        LDX     #SSRET

;;      SWIVE1 - SET UP BREAKPOINT RETURN AND JUMP TO USER CODE
;
;       ENTRY:  (X) = SWI VECTOR
;       EXIT:   TO USER PROGRAM
;

SWIVE1  LDAA    #$7E
        STAA    SYSSWI
        STX     SYSSWI+1
        LDS     USERS
        RTI

;;      THE FOLLOWING CODE IS EXECUTED AFTER A SINGLE STEP
;         OF AN OUT-OF-PLACE INSTRUCTION.  NOW CHECK TO SEE
;           IF BRANCH OCURRED, MODIFY THE USER PC ACCORDINGL
;

SSRET   TSX                          ; GET SWI LOCATION INTO X
        LDX     5,X
        INX
        CLRA
        CLRB
        CPX     TEMP
        BNE     BCHNTK

;       ADD THE BRANCH OFFSET TO THE USER PC

        DEX                          ; X WILL NOW POINT AT USERPC
        LDX     0,X                  ; SAVED VALUE OF PC INTO X
        DEX                          ; PREPARE TO FETCH BRANCH OFFSET
        LDAB    0,X
        BPL     PLUS
        COMA                         ; A IS SIGN EXENSION OF B
PLUS    TSX                          ; LO COST WAY TO POINT TO USERPC
        LDX     5,X
BCHNTK  ADDB    1,X                  ; ADD BRANCH OFFSET OR ZERO TO PC
        ADCA    0,X
        TSX                          ; PLACE NEW USERPC ONTO STACK
        STAA    5,X
        STAB    6,X
        DEX                          ; NOW X AND SP ARE EQUAL
STOX    STX     USERS
BSTRD   LDS     TEMP                 ; RETURN TO CALLING ROUTINE
        RTS

;;      SPECIAL HANDLERS

;;      BSR HANDLER

BSRH    CMPA    #$8D                 ; IS IT BSR
        BNE     JSRH
        LDAA    #$5F                 ; THIS CONVERTS BSR'S TO BRA'S

;;      JSR HANDLER

JSRH    SUBA    #$3F                 ; JSR'S TO JUMPS
        PSHA                         ; CORRECTED OPCODE ONTO STACK
        DEX
        DEX
        STX     USERS
JSRH1   LDAA    3,X
        STAA    1,X                  ; MOVE USER REGISTERS
        INX
        DECB
        BPL     JSRH1
        BRA     SRCHOP               ; NOW EXECUTE JUMP INSTRUCT

;;      JPXH - INDEXED JUMP HANDLER.

JPXH    PULB                         ; GET OFFSET
        CLRA
        ADDB    5,X
        ADCA    4,X
        DB      $8C                  ; CPX#: ONE BYTE BRA NEWPC

;;      JMP HANDLER

JMPH    PULA
        PULB
NEWPC   STAA    6,X
        STAB    7,X
        BRA     STOX                 ; RETURN TO CALLER

;;      RTS HANDLER

RTSH    INX
        INX
        STX     USERS                ; NET PULL OF TWO BYTES
RTS1    LDAA    3,X
        STAA    5,X
        DEX
        DECB
        BGT     RTS1
        BRA     BSTRD

;;      RTI HANDLER

RTIH    INX
        DECB
        BPL     RTIH
        BRA     STOX

;;      SWI HANDLER

SWIH    LDAA    7,X
        STAA    0,X
        DEX
        DECB
        BPL     SWIH
        ORAA    #%00010000           ; SET INTERRUPT MASK
        STAA    1,X
        LDAB    #-USWI/256*256+USWI  ; USWI LO ORDER
        LDAA    #USWI/256
        BRA     NEWPC                ; PATCH IN UIRQ

;;      OPTAB - LEGAL OP-CODE LOOKUP TABLE

OPTAB   DW      $9C00,$3CAF,$4000,$00AC,$6412,$6412,$6410,$6410
        DW      $1101,$1004,$1000,$1000,$110D,$100C,$100C,$100C

;;      HEX DISPLAY CODE TABLE

DISTAB  DB      HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7
        DB      HEX8,HEX9,HEXA,HEXB,HEXC,HEXD,HEXE,HEXF

;;      KEY VALUE TABLE

HEXTAB  DB      7,10,13,2,5,8,11,14
        DB      3,6,9,12,15,0,1,4

;;      COMMAND HANDLER ENTRY POINT TABLE

CMDTAB  DW      ZERO,REGA,REGB,REGP,REGX,CONDX,REGS,RESUME,STEP
        DW      BKSET,AUTO,BACK,REPLAC,DO,EXAM,FOWD


        * EQU $FFF8

;;      INTERRUPT VECTORS.

        DW      UIRQ                 ; USER IRQ HANDLER
        DW      SYSSWI               ; SYSTEM SWI HANDLER
        DW      UNMI                 ; USER NMI HANDLER
        DW      RESET
