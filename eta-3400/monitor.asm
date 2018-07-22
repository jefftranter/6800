        NAM HEATH KEYBOARD MONITOR
        PAGE 132,66

; Entered from listing in ETA-340A manual by Jeff Tranter <tranter@pobox.com>.
; Fixed some small errors in the listing.
; Adapted to the crasm assembler (https://github.com/colinbourassa/crasm).
; Note that I do not own an ETA-3400 and have no way of testing it but I
; have confirmed that it produces the same binary output as the Heathkit
; ROMs.

        CPU 6800

;;;     HEATH/WINTEK TERMINAL MONITOR SYSTEM
;
;       BY JIM WILSON FOR WINTEK CORPORATION
;         COPYRIGHT 1978 BY WINTEK CORP.
;            ALL RIGHTS RESERVED
;

;;      CONDITIONAL ASSEMBLIES

DEBUG   EQU     0               ; DEBUG CODE OFF

;;      CHARACTER DEFINITIONS

CR      EQU     $0D
LF      EQU     $0A
SPACE   EQU     ' '

;;      PIA DEFINITION

*       EQU     $1000
TERM    DS      1
TERM.C  DS      1
TAPE    DS      1
TAPE.C  DS      1

;;      EXTERNALS

SSTEP   EQU     $FE6B
SWIVE1  EQU     $FEFC
OPTAB   EQU     $FF76
REDIS   EQU     $FCBC
DISPLAY EQU     $FD7B
OUTBYT  EQU     $FE20
BKSP    EQU     $FD43
PROMPT  EQU     $FD25
OUTSTA  EQU     $FC86
OUTSTR  EQU     $FE52

;;      RAM TEMPORARIES

*       EQU     $00CC
USERC   DS      1               ; CONDX CODES
USERB   DS      1
USERA   DS      1               ; ACCUMULATORS
USERX   DS      2               ; INDEX
USERP   DS      2               ; P.C.

*       EQU     $00E4
NBR     EQU     4               ; FOUR BREAKPOINTS ALLOWED
BKTBL   DS      2*NBR
T0      DS      2
T1      DS      2
DIGADD  DS      2
USERS   DS      2
T2      EQU     *
SYSSWI  DS      3
UIRQ    DS      3
USWI    DS      3
UNMI    DS      3

        IF      DEBUG
        ELSE
*       EQU     $1400
        ENDC


;;      MAIN MONITOR LOOP
;
;       1)  FEELS OUT MEMORY
;       2)  SEARCHES FOR PAST INCARNATIONS
;            A) CLEARS BREAKPOINTS IF REINCARNATED
;            B) CLEARS BREAKPOINT TABLE OTHERWISE
;       3)  SENDS PROMPT "MON>"
;       4)  ACCEPTS COMMAND CHARACTERS AND JUMPS
;             TO APPROPRIATE HANDLER

MAIN    SEI
        LDX     #TERM           ; TERMINAL PIA
        CLR     1,X             ; IN CASE IRREGULAR ENTRY
        CLR     3,X
        LDAA    #1
        STAA    0,X
        LDAA    #%01111111
        STAA    2,X
        LDAB    #4
        STAB    1,X
        STAB    3,X
        STAA    0,X             ; IDLE MARKING!!

;;      NOW FIND MEMORY EXTENT

MAIN1   DEX
        LDAA    0,X
        COM     0,X
        COMA
        CMPA    0,X
        BNE     MAIN1
        COM     0,X             ; RESTORE GOOD BYTE
        LDAA    #4*NBR+5
MAIN2   DEX                     ; GO TO MONITOR GRAVEYARD
        DECA
        BNE     MAIN2
        TXS
        LDAA    #2*NBR+4
        LDX     2*NBR,X         ; RETURN ADDRESS IF ANY
        CPX     #MAIN5
        BEQ     MAIN4           ; IS RE-INCARNATION
        LDAB    #$FF
        TSX
MAIN3   STAB    2*NBR+2,X
        INX
        DECA
        BNE     MAIN3
MAIN4   LDAA    #NBR            ; CLEAR BREAKPOINTS
MAIN44  PULB
        PULB
        TSX
        LDX     2*NBR+4,X
        STAB    0,X
        DECA
        BNE     MAIN44
        CLC                     ; NO ERROR MESSAGE
        INS
        INS
MAIN5   BCC     MAIN6           ; NO ERROR
        JSR     OUTIS
        DB      CR,LF
        ASC     "ERROR!"
        db      7,0
MAIN6   JSR     OUTIS
        DB      CR,LF
        ASC     "MON> "
        DB      0
MAIN66  TST     TERM
        BPL     MAIN66
        JSR     INCH            ; INPUT COMMAND
        LDX     #CMDTAB-3
MAIN7   INX
        INX
        INX
        CMPA    0,X
        BCS     MAIN7
        BNE     MAIN5           ; ILLEGAL COMMAND
        PSHA
        JSR     OUTSP
        PULA
        LDAB    #-MAIN5/256*256+MAIN5
        PSHB
        LDAB    #MAIN5/256
        PSHB
        LDAB    2,X
        PSHB
        LDAB    1,X
        PSHB
        CLRB
        LDX     USERS
        RTS

;;      GO - GO TO USER CODE
;
;       ENTRY:  (X) = USERS
;       EXIT:   UPON BREAKPOINT
;       USES:   ALL,T0,T1,T2

GO      JSR     AHV
        BCC     GO1             ; NO OPTIONAL ADDRESS
        STAA    7,X
        STAB    6,X              
GO1     JSR     SSTEP           ; STEP PAST BKPT
        LDAB    #NBR
GO2     TSX                     ; COPY IN BREAKPOINTS
        LDX     2*NBR+4,X
        LDAA    0,X
        PSHA
        PSHA
        LDAA    #$3F
        STAA    0,X
        DECB
        BNE     GO2
        BRA     GO7

GO3     TSX
        LDAA    6,X
        BNE     GO33
        DEC     5,X
GO33    LDAB    5,X
        DECA
        STAA    6,X             ; DECREMENT USER PC
        STS     USERS
        LDS     T0
        PSHA
        LDAA    #NBR
        STAA    T0
        PULA
        TSX
GO4     INX                     ; SEARCH TABLE FOR HIT
        INX
        CMPA    2*NBR+5,X
        BNE     GO5
        JSR     OUTIS
        DB      CR,LF,0
        LDAA    #NBR
GO44    PULB
        PULB                    ; OP CODE INTO B
        TSX
        LDX     2*NBR+4,X
        STAB    0,X
        DECA
        BNE     GO44
        JMP     REGS            ; DISPLAY REGISTERS

GO5     DEC     T0
        BNE     GO4

;       SWI NO MONITORS SO INTERPRET

        JSR     SSTEP           ; STEP PAST SWI
GO7     STS     T0
        LDX     #GO3
        JMP     SWIVE1

;;      BKPT - INSERT BREAKPOINT INTO TABLE
;
;       ENTRY:  NONE
;       EXIT:   'C' SET IF TABLE FULL
;       USES:   ALL,T0

BKPT    TSX
        LDAA    #$FF
        LDAB    #NBR
BKP1    INX
        INX                     ; LOOK FOR EMPTY SPOT
        CMPA    4,X
        BNE     BKP2            ; NOT EMPTY
        CMPA    5,X
        BEQ     BKP3            ; IS EMPTY
BKP2    DECB
        BNE     BKP1            ; STILL HOPE
        SEC
        RTS                     ; FULL!!

BKP3    JSR     AHV             ; GET BREAKPOINT VALUE
        BCC     BKP4            ; NO ENTRY
        STAA    5,X
        STAB    4,X
BKP4    CLC
        RTS

;;      CLEAR - CLEAR BREAKPOINT ENTRY
;
;       ENTRY:  (X) = USERS
;       EXIT:   'C' SET IF NOT FOUND
;       USES:   ALL,T0

CLEAR   LDAA    #NBR
        STAA    T0
        JSR     AHV             ; GET LOCATION
        BCS     CLE1            ; NO VALID HEX
        LDAA    7,X
        LDAB    6,X             ; USER PC FOR DEFAULT
CLE1    TSX
CLE2    INX
        INX
        CMPA    5,X             ; SEARCH TABLE
        BNE     CLE3            ; NOT FOUND
        CMPB    4,X
        BEQ     CLE4            ; FOUND
CLE3    DEC     T0
        BNE     CLE2
        SEC
        RTS

CLE4    LDAB    #$FF
        STAB    4,X             ; CLEAR ENTRY
        STAB    5,X
        CLC
        RTS

;;      EXEC - PROCESS MULTIPLE SINGLE STEP
;
;       ENTRY:  NONE
;       EXIT:   REGISTERS PRINTED
;       USES:   ALL,T0,T1,T2

EXEC    JSR     AHV             ; GET COUNT
        BCS     EXEC1
        LDAA    #1              ; DEFAULT COUNT
        BRA     EXEC1

EXEC0   PSHA                    ; SAVE COUNT
        JSR     SSTEP           ; STEP CODE
        PULA
EXEC1   DECA
        BNE     EXEC0           ; MORE STEPS
        JSR     COUTIS
        DB      CR,LF,0

;;      STEP - STEP USER CODE
;
;       ENTRY:  NONE
;       EXIT:   REGISTERS PRINTED
;       USES:   ALL,T0,T1,T2

STEP    JSR     SSTEP           ; STEP USER CODE

;;      REGS - DISPLAY ALL USER REGISTERS
;
;       ENTRY:  NONE
;       EXIT:   REGISTERS PRINTER
;       USES:   ALL,T0

REGS    CLRB
        LDX     USERS
        LDAA    #'C'
        BSR     REGS1
        LDAA    #'B'
        BSR     REGS3
        LDAA    #'A'
        BSR     REGS3
        LDAA    #'X'
        BSR     REGS2
        LDAA    #'P'
        BSR     REGS3
        LDAA    #'S'
        DEX
        STX     T0
        LDX     #T0-1
        BSR     REGS1
        LDX     USERS
        LDX     6,X             ; (X) = USERPC
        STX     T0
        LDAA    0,X
        BSR     TYPINFO         ; TYPE INSTRUCTION
        CLC
        RTS

REGS1   INX
REGS2   INCB
REGS3   JSR     OUTCH           ; OUTPUT REGISTER NAME
        LDAA    #'='
        JSR     OUTCH
        BRA     TYPIN2

;;      REGISTER DISPLAY COMMANDS
;
;       ENTRY:  (X) = USERSP
;               (B) = 0
;       EXIT:   OPTIONAL REPLACEMENT VALUE STORED
;       USES:   ALL,T0

REGP    INX
        INX
REGX    INX
        INCB
REGA    INX
REGB    INX
REGC    ADDA    #$40            ; DISPLAY REG NAME
        BSR     REGS1           ; OUTPUT WITH NAME
        PSHB
        JSR     AHV
        BCC     MEM4
        BSR     REG1
        TBA
        PULB
        DECB
        BEQ     REG2
REG1    DEX
        STAA    0,X
        CMPA    0,X
        BEQ     REG2
        SEC
REG2    RTS

;;      MEM - DISPLAY MEMORY BYTES
;
;       ENTRY:  (B) = 0
;               (X) = USER S.P.
;       USES:   ALL,T0

MEM     DECB

;;      INST - DISPLAY INSTRUCTIONS
;
;       ENTRY:  (B) = 0
;               (X) = USER S.P.
;       USES:   ALL,T0

INST    PSHB
        LDX     6,X             ; GET USER P.C.
        BSR     AHV
        BCC     MEM1
        PSHA
        PSHB
        TSX
        LDX     0,X
        INS
        INS
MEM1    CLC
MEM2    PULB
        BCC     MEM3
        BSR     REG1
        BCS     MEM5
        INX
MEM3    BSR     TYPINS          ; TYPE THE DATA
        PSHB                    ; SAVE MODE FLAGS
        BSR     AHV             ; GET REPLACEMENT VALUE
        BLS     MEM2
MEM4    CLC
        PULB
MEM5    RTS

;;      TYPINS - TYPE INSTRUCTION IN HEX
;
;       ENTRY:  (X) = ADDRESS OF INSTRUCTION
;       EXIT:   (X) = ADDRESS OF NEXT INS.
;       USES:   ALL

TYPINS  LDAA    0,X             ; OP CODE
        PSHA                    ;  ONTO STACK
        STX     T0
        BSR     OUTIS
        DB      CR,LF,0
        LDX     #T0
        BSR     OUT4HS
        PULA
        TSTB
        BMI     TYPIN1          ; ONE BYTE ONLY
TYPIN0  BSR     BYTCNT
        DECB
        BPL     TYPIN1          ; IS VALID INST.
        INCB                    ; RESTORE (B)
        BSR     OUTIS
        ASC    "DATA="
        DB      0
TYPIN1  LDX     T0
        BSR     OUT2HS
TYPIN2  CMPB    #1
        BMI     THB1
        BEQ     OUT2H2
        BRA     OUT4HS

;;      DISB - DISPLAY BREAKPOINTS
;
;       ENTRY:  NONE
;       EXIT:   BREAKPOINT TABLE PRINTED
;       USES:   ALL

DISB    LDAB    #6              ; OFFSET INTO TABLE
        TSX
DISB1   INX
        DECB
        BNE     DISB1
        LDAB    #NBR
DISB2   BSR     OUT4HS
        DECB
        BNE     DISB2
        RTS

;;      OUT4HS, OUT2HS - OUTPUT HEX AND SPACES
;
;       ENTRY:  (X) = ADDRESS
;       EXIT:   X UPDATED PAST BYTE(S)
;       USES:   X,A,C

OUT4HS  BSR     THB             ; TYPE HEX BYTE
OUT2HS  BSR     THB
        JMP     OUTSP

;;      THB - TYPE HEX BYTE
;
;       ENTRY:  (X) = ADDRESS OF BYTE
;       EXIT:   X INCREMENTED PAST BYTE
;       USES:   X,A,C

THB     PSHB
        CLRB
        JSR     OCH
        PULB
THB1    RTS

;;      OUTIS - OUTPUT IMBEDDED STRING
;
;       CALLING CONVENTION:
;               JSR    OUTIS
;               FCB    'STRING',0
;               <NEXT INST>
;       EXIT:  TO NEXT INSTRUCTION
;       USES:  A,X

OUTIS   TSX
        LDX     0,X
        INS
        INS
        PSHB
        CLRB
        JSR     OAS
        PULB
        JMP     0,X

;;      AHV - ACCUMULATE HEX VALUE
;
;       ENTRY:  NONE
;       EXIT:   (BA) = ACCUMULATED HEX VALUE OR
;                (A) = ASCII IF NO HEX
;                'C' SET FOR VALID HEX
;                'Z' SET FOR TERMINATOR = CR
;       USES:  B,A,C

AHV     CLRB
AHVD    JSR     IHD             ; GET FIRST DIGIT
        BCC     AHV3            ; NOT HEX
AHV1    PSHA
        PSHB
        ASLA
        ROLB
        ASLA
        ROLB
        ASLA
        ROLB
        ASLA
        ROLB                    ; MAKE WAY FOR NEXT DIGIT
        PSHB
        PSHA
        JSR     IHD
        BCC     AHV2            ; THIS NOT HEX
        PULB
        ABA
        PULB
        INS
        INS                     ; DISCARD OLD VALUE
        BRA     AHV1

AHV2    INS
        INS                     ; SKIP LATEST VALUE
        PULB
        PULA
        SEC
AHV3    RTS

;;      BYTCNT - COUNT INSTRUCTION BYTES
;
;       ENTRY:  (A) = OPCODE
;       EXIT:   (B) = 0,1,2 OR 3
;               'C' CLEAR IF RELATIVE ADDRESSING
;               'Z' SET IF ILLEGAL

BYTCNT  PSHA
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
        BCS     BYT7
        CMPA    #$30            ; CHECK FOR BRANCH
        BCC     BYT3
        CMPA    #$20
        BCC     BYT5            ; IS BRANCH
BYT3    CMPA    #$60
        BCS     BYT6            ; IS ONE BYTE
        CMPA    #$8D
        BEQ     BYT5            ; IS BSR
        ANDA    #$BD
        CMPA    #$8C
        BEQ     BYT4            ; IS X OR SP IMM.
        ANDA    #$30            ; CHECK FOR THREE BYTES
        CMPA    #$30
BYT4    SBCB    #$FF
BYT5    INCB
BYT6    INCB
BYT7    RTS

;;      COPY - COPY MEMORY ELSEWHERE
;
;       ENTRY:  NONE
;       EXIT:   BLOCK MOVED
;       USES:   ALL
;
;       COMMAND SYNTAX: (CNTL-D)D <FROM>,<TO>,<COUNT>

COPY    JSR     OUTIS
        ASC     "SLIDE"
        DB      0
        JSR     AHV             ; GET *FROM*
        BCC     COP3            ; NO HEX
        PSHA
        PSHB
        JSR     AHV             ; GET *TO*
        BCC     COP2            ; NO HEX
        PSHA
        PSHB
