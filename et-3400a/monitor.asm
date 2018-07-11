        NAM Heathkit ET-3400A Monitor
        PAGE 132,66

	CPU 6800

;;      ASSEMBLY CONSTANT TABLE

;;      KEYBOARD LOCATIONS

        COL1  EQU $0003              ; RIGHTMOST COLUMN
        COL2  EQU $0005
        COL3  EQU $0006              ; LEFTMOST COLUMN

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
        HEX5 EQU $58
        HEX6 EQU $5F
        HEX7 EQU $70
        HEX8 EQU $7F
        HEX9 EQU $7B
        HEXA EQU $77
        HEXB EQU $1F
        HEXC EQU $4E
        HEXD EQU $3D
        HEXE EQU $4F
        HEXE EQU $47
        LTRA EQU $7D
        LTRB EQU $1F
        LTRC EQU $0D
        LTRF EQU $47
        LTRN EQU $15
        LTRI EQU $30
        LTRP EQU $67
        LTRL EQU $0E
        LTRH EQU $37
        LTRD EQU $3D
        LTRG EQU $5E
        LTRO EQU $1D
        LTRR EQU $05
        LTRU EQU $3E
        LTRY EQU $3B
        LTRS EQU $58
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
T1      EQU TEMP+1
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


        PAGE

;;      RESET - ENTRY FOR BREAKPOINT TABLE
;
;       ENTRY:  NONE
;       EXIT    (B) = 2
;               (X) = ADDRESS IN TABLE
;       USES: ALL.TO.11

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

        JSR     STO
        DB      0,LTRF,LTRU,LTRL,LTRL,$A0
        INCA
        RTS

BKSE3   STX     T1
        BSR     OUTSTA
        DB      LTRB,LTRR+$80
        BSR     DOPM1
        INCA                         ; (A) = 1
        RTS

        PAGE
;;      DOPPMT - ACCEPT ADDRESS VALUE WITH "DO" PROMPT
;
;       ENTRY:   (X) = ADDRESS TO STORE INPUTTED VALUE
;       EXIT:    (B) = 2
;                (X) UNCHANGED
;       USES:    ALL.TO.T1

DOPMT   STX      T1
        BSR      OUTSTA              ; OUTPUT PROMPT "DO"
        DW       LTRD,LTRO+$80
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
        BRA      DOMP1

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

        PAGE
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
;       USES  ALL.TO.T1

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

        PAGE
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
EE      LDX   #T1
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
