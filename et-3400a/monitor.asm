        NAM Heathkit ET-3400A Monitor

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
