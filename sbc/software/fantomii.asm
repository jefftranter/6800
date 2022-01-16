        NAM HEATH KEYBOARD MONITOR
        PAGE 66,132

; Entered from listing in ETA-340A manual by Jeff Tranter <tranter@pobox.com>.
; Fixed some small errors in the listing.
; Adapted to the crasm assembler (https://github.com/colinbourassa/crasm).
; I have confirmed that it produces the same binary output as the Heathkit
; ROMs.

        CPU 6800
        OUTPUT  HEX             ; For Intel hex output
;       OUTPUT  SCODE           ; For Motorola S record (RUN) output

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

        DUMMY
*       EQU     $8200
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
T2      DS      0
SYSSWI  DS      3
UIRQ    DS      3
USWI    DS      3
UNMI    DS      3

        CODE
*       EQU     $C000

;; FILL UNUSED LOCATIONS WITH FF

        DS      $E400-*,$FF

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
        BNE     GO5             ; NO HIT HERE
        CMPB    2*NBR+4,X
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
        JSR     OUTIS
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
        BSR     TYPIN0          ; TYPE INSTRUCTION
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
        BEQ     OUT2HS
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
        ASC     "SLIDE "
        DB      0
        JSR     AHV             ; GET *FROM*
        BCC     COP3            ; NO HEX
        PSHA
        PSHB
        JSR     AHV             ; GET *TO*
        BCC     COP2            ; NO HEX
        PSHA
        PSHB
        JSR     AHV             ; GET *COUNT*
        BCC     COP1            ; NO HEX
        PSHA
        PSHB
        JSR     MOVE            ; MOVE DATA
        CLC                     ; NO ERRORS
        RTS

COP1    INS
        INS
COP2    INS
        INS
COP3    SEC
        RTS

;;      LOAD - LOAD DATA INTO MEMORY
;
;       ENTRY:  NONE
;       EXIT:   'C' SET IF ERROR
;       USES:   ALL,T0

LOAD    JSR     AHV             ; GET OPTIONAL PARAMETERS
        BCS     LOA00
        LDAA    #8              ; DEFAULT TO CASSETTE
LOA00   TAB
LOA0    DES
        DES                     ; SCRATCHPAD ON STACK
LOA1    JSR     ICT             ; INPUT CASSETTET/TERM
        ANDA    #$7F
        CMPA    #'S'
        BNE     LOA1
        JSR     ICT
        ANDA    #$7F
        CMPA    #'9'
        BEQ     LOA4            ; IS EOF
        DES
        CMPA    #'1'
        BNE     LOA1            ; NOT START-OF-RECORD
        STAA    $C16F           ; TURN ON D.P.
        CLRA
        TSX
        JSR     IHB             ; COUNT
        JSR     IHB             ; ADDRESS (2 BYTES)
        JSR     IHB
        TSX
        LDX     1,X             ; GET FWA OF BUFFER
        STAB    T0
        PULB
        SUBB    #3              ; ACCOUNT 3 BYTES
LOA2    PSHB
        LDAB    T0
        JSR     IHB
        STAB    T0
        PULB
        DECB
        BNE     LOA2
        CLR     $C16F           ; TURN OFF D.P.
        LDAB    T0
        LDX     #T0
        JSR     IHB
        INCA
        BEQ     LOA1
LOA3    SEC
LOA4    INS
        INS
        RTS

;;      TIME CRITICAL ROUTINES !!!!!
;       SINCE CASSETTE I/O IS DONE USING ONLY SOFTWARE
;        TIMING LOOPS, THE ROUTINE 'BIT' MUST BE CALLED
;        EVERY 208 US.  CRITICAL TIMES IN THESE ROUTINES
;        ARE LISTED IN THE COMMENT FIELDS OF CERTAIN
;        INSTRUCTIONS IN THE FORM 'NNN US'.  THESE TIMES
;        REPRESENT THE TIME REMAINING BEFORE THE NEXT
;        RETURN FROM 'BIT'.  THE TIME INCLUDES THE
;        LABELED INSTRUCTION AND INCLUDES THE EXECUTION
;        OF THE 'RTS' AT THE END OF 'BIT'.  SOME
;        ROUTINES HAVE 'NNN US USED' AS A COMMENT
;        ON THEIR LAST STATEMENT.  THIS REPRESENTS
;        THE TIME EXPIRED SINCE THE LAST RETURN
;        FROM 'BIT' INCLUDING THE LABLED INSTRUCTION.

;;      HIGH SPEED LOAD
;
;         ACCEPTS ADDITIONAL BIT/CELL PARAMETER
;
;       ENTRY:  (A) = COMMAND
;               (B) = 0
;       USES:   ALL,T0,T1,T2

CTLT    ADDA    #$40            ; DISPLACE TO PRINTING
        JSR     OUTCH           ; ECHO TO USER
        JSR     AHV
        TAB
        ANDB    #$7F
        BRA     PTAP

;;      RCRD - RECORD MEMORY DATA IN 'KCS' FORMAT
;
;       ENTRY:  (B) = 0
;       USES:   ALL,T0,T1,T2

RCRD    ADDB    #9

;;      DUMP - RAW MEMORY DUMP 16 BYTES PER LINE
;
;       ENTRY:  (B) = 0
;       USES:   T0,T1,T2

DUMP    DECB

;;      PTAP - PUNCH TO TAPE
;
;       ENTRY:  DEFAULT VALUES ON STACK
;                BELOW RETURN ADDRESS
;       EXIT:   'C' SET FOR ERROR
;       USES:   ALL,T0,T1,T2

PTAP    TSX
        PSHB                    ; CASSETTE/TERMINAL FLAG
        JSR     AHV             ; ACCUMULATE HEX
        BCC     PTAP1           ; USE DEFAULT
        STAA    3,X             ;   STORE FWA
        STAB    2,X
        JSR     AHV
        STAA    5,X
        STAB    4,X
PTAP1   LDAA    5,X
        LDAB    4,X             ; GET LWA, FWA
        LDX     2,X
        STX     T1
        STAA    T2+1
        STAB    T2
        PULB

;;      PUNCH - WRITE LOADER FILE TO TERMINAL OR CASSETTE
;
;       ENTRY:  (T1) = FWA BYTES TO PUNCH
;               (T2) = LWA BYTES TO PUNCH
;               (B) = CASSETTE TERMINAL FLAG:
;                   (B) > 0 THEN TO CASSETTE
;                       USING (B) CELLS PER BIT
;                   (B) = 0 THEN TO TERMINAL
;                   (B) < 0 THEN TO TERMINAL WITH
;                       IMBEDDED SPACES AND NO S1,ETC.
;       USES:   ALL,T0,T1

PUNCH   TSTB
        BLE     PNCH0
        JSR     OLT             ; OUTPUT LEADER
        LDAA    #7
        BRA     PNCH1

PNCH0   LDAA    #4              ; 186 US
PNCH1   DECA
        BNE     PNCH1
        PSHB                    ; SAVE FLAG; 160 US
        LDAB    T2              ; (B1) = END; 156 US
        LDAA    T2+1
        SUBA    T1+1
        SBCB    T1              ; (BA) = END - CURRENT
        BCS     PNCH9           ; DONE;   144 US
        CMPA    #15             ; 140 US
        SBCB    #0
        PULB                    ; RESTORE FLAG
        BCC     PNCH2           ; AT LEAST FULL RECORD
        BRA     PNCH3
 PNCH2  LDAA    #15
        NOP
 PNCH3  STAA    T0              ; COUNTER
        ADDA    #4
        STAA    T0+1            ; BYTE COUNT
        LDX     #S1STR          ; 114 US
        TSTB
        BPL     PNCH35
        LDX     #CRSTR
PNCH35  BSR     OAS             ; OUTPUT ASCII STRING
        LDX     #T0+2
        CLRA                    ; (A) = CHECKSUM
        NOP
        TSTB
        BMI     PNCH5
        DEX
        BITA    0,X             ; 5 CYCLE NUTHIN'
PNCH5   NOP
        NOP
        BSR     OCH             ; 182 US
        NOP
        BNE     PNCH5
        LDX     T1
PNCH6   BSR     OSH             ; 182 US
        DEC     T0
        BPL     PNCH6
        COMA
        PSHA
        NOP
        LDAA    #7
PNCH7   DECA
        BNE     PNCH7
        PULA
        TSTB
        BMI     PNCH75          ; NO CHECKSUM
        BSR     OHB
PNCH75  LDAA    TERM
        COMA
        ROLA
        STX     T1
        STX     T1
        BHI     PNCH0           ; NOT DONE; NO BREAK
        INX
        PSHB
        LDAA    #6
PNCH8   DECA
        BNE     PNCH8
PNCH9   PULB                    ; 140 US
        NOP
        LDAA    #3
PNCHA   DECA
        BNE     PNCHA
        LDX     #S9STR
        TSTB
        BMI     PNCHC           ; RETURN
        BSR     OAS
        TSTB
        BEQ     PNCHC           ; NOT CASSETTE
        LDAA    #19
PNCHB   DECA
        BNE     PNCHB
        BSR     OLT
        CLC                     ; NO ERRORS
PNCHC   RTS

S1STR   DB      CR,LF
        ASC     "S1"
        DB      0
S9STR   DB      CR,LF
        ASC     "S9"
        DB      0
CRSTR   DB      CR,LF,0

;;      OAS - OUTPUT ASCII STRING
;
;       ENTRY:  (X) = ADDRESS OF STRING IN FORM:
;                 'STRING',0
;               (B) = CASSETTE/TERM FLAG
;       EXIT:   X POINTS PAST END OF STRING ZERO
;       USES:   X,A,C

OAS     LDAA    0,X             ; 97 US
        INX
OAS1    BSR     OAB             ; 88 US
        NOP
        LDAA    #16             ; 208 US
OAS2    DECA
        BNE     OAS2
        LDAA    0,X
        INX
        TST     0,X
        BNE     OAS1            ; NOT LAST BYTE
        INX
        BRA     OAB             ; OUTPUT LAST AND RETURN

;;      OSH - OUTPUT OPTIONAL SPACE WITH HEX BYTE
;
;       ENTRY:  (X) = ADDRESS OF BYTE
;               (A) = CHECKSUM
;               (B) = CASSETTE/TERMINAL FLAG
;       EXIT:   (X) INCREMENTED, (A) UPDATED
;       USES:   X,A,C

OSH     ADDA    0,X             ; 174 US
        PSHA
        LDAA    #5
        TSTB
        BPL     OCH0            ; NO SPACE
        JSR     OUTSP           ; OUTPUT SPACE
        PULA

;;      OCH - OUTPUT AND CHECKSUM HEX BYTE
;
;       ENTRY:  (X) = ADDRESS OF BYTE
;               (A) = CHECKSUM
;               (B) = CASSETTE/TERMINAL FLAG
;       EXIT:   (X) INCREMENTED, (A) UPDATED
;               'Z' SET IF END OF HEADER INFO
;       USES:   X,A,C

OCH     ADDA    0,X             ; 174 US
        PSHA
        LDAA    #6
OCH0    NOP
OCH1    DECA
        BNE     OCH1
        LDAA    0,X
        BSR     OHB
        PULA
        INX
        CPX     #T1+2
        RTS                     ; 16 US USED

;;      OHB - OUTPUT HEX BYTE
;
;       ENTRY:  (A) = BYTE
;               (B) = CASSETTE TERMINAL FLAG
;       USES:   A,C

OHB     PSHA                    ; 112 US
        LSRA
        LSRA
        LSRA
        LSRA
        BSR     OHB2
        LDAA    #18             ; 208 US
OHB1    DECA
        BNE     OHB1
        PULA
        ANDA    #$0F
OHB2    CMPA    #10
        BCC     OHB3            ; IS A - F
        BRA     OHB4
OHB3    NOP
        ADDA    #7
OHB4    ADDA    #$30

;;      OAB - OUTPUT ASCII BYTE
;
;       ENTRY:  (A) = ASCII
;               (B) = CASSETTE/TERMINAL FLAG
;       EXIT:   (A) PRESERVED
;       USES:   C

OAB     TSTB                    ; 80 US
        BLE     OUTCH

;;      OCB - OUTPUT CASSETTE BYTE
;
;       ENTRY:  (B) = CELLS/BUT COUNT
;               (A) = CHARACTER
;       USES:   C

OCB     CLC                     ; START BIT; 74 US
        BSR     BIT1            ; 72 US
        PSHA                    ; 208 US
        SEC                     ; STOP BIT
        RORA
OCB1    BSR     BIT             ; 200 US
        NOP                     ; 208 US
        LSRA
        BNE     OCB1
        BSR     BIT
        PULA
        INX
        DEX                     ; 8 CYCLE PSEUDO-OP
        BRA     BIT

;;      OLT - OUTPUT LEADER TRAILER
;
;       ENTRY:  NONE
;       EXIT:   5 SECONDS MARKING WRITTEN
;       USES:   C

OLT     SEC                     ; 78 US
        PSHA
        BSR     BIT1
        PSHB
        LDAB    #110
        TBA
OLT1    BSR     BIT
        NOP
        DECA
        BNE     OLT1
        PULB
        PULA

;;      BIT - OUTPUT 'C' TO CASSETTE
;
;       ENTRY:  (B) = CELL/BIT COUNT
;               'C' = BIT
;       USES:   C EXCEPT 'C'

BIT     PSHA                    ; 192 US
        LDAA    #21
        NOP
        NOP
        BRA     BIT3            ; 182 US

BIT1    PSHA                    ; 64 US
        LDAA    #1
BIT3    PSHB
        DB      $8C             ; 3 CYCLE SKIP
BIT4    LDAA    #29
BIT5    DECA
        BNE     BIT5
        INCA
        BSR     FLIP            ; 43 US
        LDAA    #30
BIT6    DECA
        BNE     BIT6
        TPA
        ANDA    #1              ; MASK TO CARRY
        BSR     FLIP1
        DECB
        BNE     BIT4
        PULB
        PULA
        RTS                     ; ___ ALL TIMES REFERENCED HERE !!!

;;      FLIP - FLIP CASSETTE BIT
;
;       ENTRY:  (A) = 0 THEN NO FLIP
;               (A) = 1 THEN FLIP
;       USES:   A,C EXCEPT 'C'

FLIP    NOP                     ; 35 US
FLIP1   EORA    TAPE
        STAA    TAPE
        RTS                     ; 24 US

;;      OUTSP - OUTPUT SPACE TO TERMINAL
;
;       ENTRY:  NONE
;       EXIT:   (A) = ' '
;       USES:   A,C

OUTSP   LDAA    #' '

;;      OUTCH - OUTPUT CHARACTER TO TERMINAL
;
;       ENTRY:  (A) = CHARACTER
;       EXIT:   (A) PRESERVED UNLESS -LF-
;       USES:   C

OUTCH   PSHA
        PSHB
        BSR     BRD             ; BAUD RATE DETERMINE
        SEC                     ; STOP BIT
        BSR     WOB
        CLC                     ; START BIT
        BSR     WOB
        SEC
        RORA
OUTC1   BSR     WOB             ; WAIT - OUTPUT BIT
        LSRA
        BNE     OUTC1
        BSR     WOB             ; WAIT; OUTPUT STOP
        PULB
        PULA
        CMPA    #LF
        BNE     OUTC2
        PSHA
        CLRA
        BSR     OUTCH           ; OUTPUT FILL CHARACTER
        BSR     OUTCH
        BSR     OUTCH
        BSR     OUTCH
        PULA
OUTC2   RTS

;;      BRD - BAUD RATE DETERMINATION
;
;       ENTRY:  NONE
;       EXIT:   (B) = BAUD RATE DIVISOR
;                      (COMPENSATED FOR 5*13 EXTRA
;                        EXECUTION TIME!!)
;       USES:   B,C

BRD     PSHA
        LDAB    #1              ; ASSUME 110 BAUD
        LDAA    TERM            ;  BAUD SWITCH DATA
        COMA
        ANDA    #%00001110      ; MASK TO SWITCHES
        LSRA
        BEQ     BRD2            ; IS 110
BRD1    RORB
        DECA
        BNE     BRD1
        SUBB    #5              ; EXECUTION COMPENSATION
BRD2    PULA
        RTS

;;      WOB - WAIT AND OUTPUT BIT
;
;       ENTRY:  (B) = DELAY COUNT
;               'C' = BIT
;       EXIT:   (B), 'C' PRESERVED
;       USES:   C

WOB     PSHB
        BSR     DLB             ; DELAY ONE BIT
        BRA     WIB1

;;      IHD - INPUT HEX DIGIT FROM TERMINAL
;
;       ENTRY:  NONE
;       EXIT:   (A) = HEX VALUE IF VALID
;               'C' SET IF HEX
;               'Z' SET IF CR
;       USES:   A,C

IHD     BSR     INCH
        CMPA    #SPACE
        BEQ     IHD             ; IGNORE SPACES

;;      ASH - ASCII TO HEX TRANSLATOR
;
;       ENTRY:  (A) = ASCII
;       EXIT, USES: SEE "IHD"

ASH     SUBA  #'0'
        BCS   ASH1              ; NOT HEX
        CMPA  #10
        BCS   ASH3
        SUBA  #'A'-'0'
        CMPA  #6
        BCS   ASH2              ; IS HEX
        ADDA  #'A'-'0'          ; DISPLACE BACK
ASH1    ADDA  #'0'
        CMPA  #CR
        CLC
        RTS

ASH2    SUBA    #$F6            ; -10
ASH3    RTS

;;      IHB - INPUT HEX BYTE
;
;       ENTRY:  (B) = CASSETTE/TERMINAL FLAG
;               (X) = ADDRESS
;               (A) = CHECKSUM
;       EXIT:   A, X UPDATED
;               (B) PRESERVED

IHB     PSHA                    ; SAVE CHECKSUM
        BSR     ICT             ; INPUT CASSETTE/TERMINAL
        ANDA    #$7F
        BSR     ASH             ; ASCII - HEX
        ASLA
        ASLA
        ASLA
        ASLA
        STAA    T0
        BSR     ICT             ; INPUT CASSETTE/TERMINAL
        ANDA    #$7F
        BSR     ASH             ; ASCII - HEX
        ADDA    T0
        STAA    0,X             ; PLACE IN MEMORY
        PULA
        ADDA    0,X
        INX
IHB2    RTS

;;      ICT - INPUT FROM CASSETTE OR TERMINAL
;
;       ENTRY:  (B) = CASSETTE/TERMINAL FLAG
;       EXIT:   (A) = CHARACTER
;       USES:   A,C

ICT     TSTB
        BGT     ICC             ; IS CASSETTE

;;      INCH - INPUT TERMINAL CHARACTER
;
;       ENTRY:  NONE
;       EXIT:   (A) = CHARACTER
;       USES:   A,C

INCH    PSHB
        BSR     BRD             ; BAUD RATE DETERMINE
        TBA

; Official ROM has this code?
JMP     PATCH

; Source code in manual has three lines below?
;INC1    TAB
;        LSRB
;        INCB

INC2    TST     TERM
        BMI     INC2            ; WAIT FOR SPACING
        BSR     WIB             ; WAIT, INPUT START
        BCS     INC2            ; WAS NOISE
        TAB
        LDAA    #$80
INC3    BSR     WIB             ; WAIT; INPUT BIT
        RORA
        BCC     INC3
        BSR     WIB             ; GET STOP
        BCS     INC4            ; NO FRAME ERROR
        INC     TERM            ;   SEND STOP BIT
INC4    ANDA    #$7F            ; MASK TO SEVEN BITS
        PULB
        RTS

;;      WIB - WAIT AND INPUT BIT
;
;       ENTRY:  (B) = DELAY COUNT
;       EXIT:   'C' = BIT
;       USES:   C

WIB     PSHB
        BSR     DLB             ; WAIT ONE BIT TIME
        ADDB    #$80
        SUBB    #$80
WIB1    ADCB    #0              ; COPY BIT INTO LSB
        STAB    TERM
        RORB                    ; RESTORE SMASHED 'C'
        PULB
        RTS

;       DB - DELAY ONE BIT AND RETURN (TERM) IN B
;
;       ENTRY:  (B) = DELAY CONSTANT
;       EXIT:   (B) = (TERM) .AND. 11111110 B
;       USES:   C EXCEPT 'C'

DLB     BITB    #$FE
        BNE     DLB4            ; NOT 110 BAUD
        DECB
        BEQ     DLB1            ; 110 FULL BIT TIME
        LDAB    #56
DLB1    EORB    #49
        PSHA
DLB2    LDAA    #18
DLB3    DECA
        BNE     DLB3
        DECB
        BNE     DLB2
        PULA
DLB4    CPX     DLB             ; 5 CYCLE NUTHIN'
        NOP
        DECB
        BNE     DLB4
        LDAB    TERM
        ANDB    #$FE
        RTS

;;      ICC - INPUT CASSETTE CHARACTER
;
;       GETS BITS FROM CASSETTE IN SERIAL FASHION
;       EACH BIT CONSISTS OF SEVERAL 'CELLS'
;       EACH CELL IS EITHER 1/2 CYCLE OF 1200HZ
;                        OE 1/2 CYCLE OF 2400HZ
;       AT 8 CELLS/BIT THE ROUTINE IS 'KCS'
;         COMPATIBLE
;
;       ENTRY:  (B) = CELLS PER BIT
;       EXIT:   (A) = CHARACTER
;               'C' = STOP BIT
;       USES:   A,C

ICC     PSHB
        LSRB
ICC1    BSR     TNC             ; TAKE NEXT CELL
        BCS     ICC1            ; NOT START BIT
        DECB
        BPL     ICC1            ; NOT ENOUGH CELLS
        PULB
        LDAA    #%01111111      ; PRESET ASSEMBLY
ICC2    PSHB
        PSHA
ICC3    BSR     TNC             ; TAKE NEXT CELL
        DECB
        BNE     ICC3
        PULA
        PULB
        RORA
        BCS     ICC2
        PSHB
        PSHA
ICC4    BSR     TNC             ; GET STOP BIT
        DECB
        BNE     ICC4
        PULA
        PULB
        RTS

;;      TNC - TAKE NEXT CELL
;
;       WAIT FOR 1/2 CYCLE OF 1200 HZ OR
;                  1 CYCLE OF 2400 HZ
;       STRUCTURE ASSURES EXIT AT END OF
;        ZERO CELL
;
;       ENTRY:  NONE
;       EXIT:   'C' = NEW CELL VALUE
;               (A) = NEW CASSETTE DATA
;       USES:   A,C

TNC     LDAA    TAPE
        BSR     TNC1
        BCC     TNC3            ; WAS ZERO
TNC1    PSHB
        CLRB
TNC2    INCB
        CMPA    TAPE
        BEQ     TNC2           ; NO TRANSITION
        LDAA    TAPE
        CMPB    #29
        PULB
TNC3    RTS

;;      MOVE - REENTRANT MOVE MEMORY
;
;
;       ENTRY:  STACK>  RETURN (0,S)
;                       COUNT  (2,S)       
;                       TO     (4,S)
;                       FROM   (6,S)
;       EXIT:   STACK CLEANED
;       USES:   ALL

MOVE    TSX
        LDX     2,X             ; CHECK COUNT <> 0
        BEQ     MOV4            ; NO MOVE
MOVEA   TSX                     ; ** ALTERNATE ENTRY **
        LDAA    5,X             ; (BA) = TO
        LDAB    4,X
        SUBA    7,X             ; (BA) = TO - FROM
        SBCB    6,X
        BCS     MOV2            ; IS MOVE DOWN
        BNE     MOV1
        TSTA
        BEQ     MOV4            ; DISPLACEMENT = 0

;       HAVE MOVE UP - MUST START AT TOP
;          TO AVOID CONFLICT

MOV1    LDAA    #$FF            ; (BA) = -1
        TAB
        PSHA                    ; DELTA = -1
        PSHB
        ADDA    3,X             ; (BA) = COUNT - 1
        ADCB    2,X
        PSHA
        PSHB
        ADDA    5,X             ; TO = TO + COUNT - 1
        ADCb    4,X
        STAA    5,X
        STAB    4,X
        PULB
        PULA
        ADDA    7,X             ; FROM = FROM
        ADCB    6,X             ;   + COUNT = 1
        STAA    7,X
        STAB    6,X
        BRA     MOV3

;       HAVE MOVE DOWN - MAY START AT TOP

MOV2    LDAA    #1              ; DELTA = 1
        CLRB
        PSHA
        PSHB
        CLRA
        SUBA    3,X             ; (BA) = - COUNT
        SBCB    2,X
        STAA    3,X
        STAB    2,X             ; COUNT = - COUNT

;       ACTUAL MOVE LOOP FOLLOWS

MOV3    TSX
        LDX     8,X
        LDAA    0,X
        TSX
        LDX     6,X
        STAA    0,X
        TSX
        LDAA    1,X
        LDAB    0,X
        ADDA    9,X
        ADCB    8,X
        STAA    9,X
        STAB    8,X
        LDAA    1,X             ; BUMP *TO*
        LDAB    0,X
        ADDA    7,X
        ADCB    6,X
        STAA    7,X
        STAB    6,X
        LDAA    1,X             ; BUMP  *COUNT*
        LDAB    0,X
        ADDA    5,X
        ADCB    4,X
        STAA    5,X
        STAB    4,X
        BNE     MOV3            ; COUNT <> 0
        TSTA
        BNE     MOV3
        INS
        INS                     ; DISCARD DELTA
        TSX

MOV4    LDX     0,X
        INS
        INS
        INS
        INS
        INS
        INS
        INS
        INS
        JMP     0,X

;;      COMMAND TABLE

CMDTAB  DB     'T'             ; TAPE RECORD DATA
        DW      RCRD

        DB      'S'             ; SET USER CODE
        DW      STEP

        DB      'R'             ; DISPLAY USER REGISTERS
        DW      REGS

        DB      'P'             ; PUNCH TO PAPER TAPE
        DW      PTAP

        DB      'M'             ; DISPLAY MEMORY (BYTE)
        DW      MEM

        DB      'L'             ; LOAD FROM TAPE
        DW      LOAD

        DB      'I'             ; DISPLAY MEMORY (INST)
        DW      INST

        DB      'H'             ; HALTPOINT INSERT
        DW      BKPT

        DB      'G'             ; GO TO USER CODE
        DW      GO

        DB      'E'             ; MULTIPLE STEP
        DW      EXEC

        DB      'D'             ; DUMP MEMORY
        DW      DUMP

        DB      'C'             ; BREAKPOINT CLEAR
        DW      CLEAR

        DB      'B'             ; GO TO BASIC
        DW      $1C03           ; WARM START ENTRY

        DB      'X'-$40         ; DISPLAY INDEX
        DW      REGX

        DB      'T'-$40         ; HI SPEED TAPE
        DW      CTLT

        DB      'S'-$40         ; SLIVE MEMORY!!
        DW      COPY

        DB      'P'-$40         ; DISPLAY P.C.
        DW      REGP

        DB      'H'-$40         ; HALTPOINT LIST
        DW      DISB

        DB      'C'-$40         ; DISPLAY CONDX
        DW      REGC

        DB      'B'-$40         ; DISPLAY B ACC.
        DW      REGB

        DB      'A'-$40         ; DISPLAY A ACC.
        DW      REGA

        DB      '@'-$40         ; EXIT TO OLD MONITOR
        DW      $FC00

;;      MTST - MEMORY DIAGNOSTIC
;
;         DISPLAYS LWA IN 'ADDR' FIELD ON LEDS
;                  CURRENT TEST PATTERN IN 'DATA'
;       ENTRY:  NONE
;       EXIT:   FAILED ADDRESS/PATTERN DISPLAYED
;                PROCESSOR HALTED
;       USES:   ALL,T0,T1,DIGADD

MTST    SEI
        BSR     FTOP            ; FIND TOP OF MEMORY
        TXS                     ; STACK AT TOP
        INS
MTS2    CLR     0,X
        DEX
        BNE     MTS2            ; CLEAR ALL MEMORY
        CLR     0,X
        STS     T1              ; HOPE THIS IS GOOD!!
        LDS     #T0-1
        JSR     REDIS           ; RESET DISPLAYS
        LDX     #T1
        LDAB    #2
        JSR     DISPLAY         ; OUTPUT LWA FOUND
        CLRA
        DECB
MTS3    JSR     OUTBYT          ; OUTPUT PATTERN
        PSHA
        JSR     BKSP            ; BACKSPACE DISPLAYS
        PULA
        LDX     T1
MTS4    CMPA    0,X
        BNE     MTS6            ; FAILURE!
        INC     0,X
        DEX
        CPX     #DIGADD+1       ; SKIP CONTAMINATED AREA
        BNE     MTS5
        LDX     #T0-13
MTS5    CPX     #-1
        BNE     MTS4
        INCA
        BRA     MTS3

MTS6    STX     T1
        JSR     REDIS           ; RESET DISPLAYS
        LDX     #T1
        INCB
        JSR     DISPLAY
        WAI

;;      FTOP - FIND MEMORY TOP
;
;       SEARCHES DOWN FROM 1000H UNTIL FINDS
;         GOOD MEMORY
;
;       ENTRY:  NONE
;       EXIT:   (X) = LWA MEMORY
;       USES:   X

FTOP    PSHA
        LDX     #TERM           ; TOP OF MEMORY+1
        LDAA    #$55            ; TEST PATTERN
FTO1    DEX
        STAA    0,X
        CMPA    0,X
        BNE     FTO1
        PULA
        RTS

;;      CCD - CONSOLE CASSETTE DUMP
;
;       ENTRY: NONE
;       EXIT:  TO LED MONITOR
;       USES:  ALL,T0,T1,T2

CCD     LDAB   #8
        BSR    IN.PIA           ; INITIALIZE PIA
        LDS    #T0-1
        PSHB
        JSR     OUTSTA
        DB      $47,$05+$80     ; 'FR'
        LDX     #T1
        LDAB    #2
        JSR     REDIS           ; RESET DISPLAYS
        JSR     PROMPT          ; PROMPT FWA
        JSR     OUTSTA
        DB      $0E,$7d+$80     ; 'LA'
        JSR     REDIS           ; RESET DISPLAYS
        LDX     #T2
        JSR     PROMPT          ; PROMPT LWA
        PULB
        JSR     PUNCH
CCD1    JMP     $FC00           ; EXIT TO MONITOR

;;      CCL - CONSOLE CASSETTE LOAD
;
;       ENTRY:  NONE
;       EXIT:   TO CONSOLE MONITOR IF SUCESS
;       USES:   ALL,T0,HIGHEST MEMORY

CCL     LDAB    #8
        BSR     IN.PIA          ; INITIALIZE PIA
        BSR     FTOP            ; FIND MEMORY TOP
        TXS
        INS
        JSR     LOA0            ; LOAD MEMORY
        BCC     CCD1            ; NORMAL RETURN
        JSR     REDIS           ;   PRINT ERROR MESSAGE
        JSR     OUTSTR
        DB      $4F,$05,$05,$1D,$05+$80
        WAI

;       IN.PI - INITIALIZE PIA FOR LED MONITOR
;
;       INITIALIZE CASSETTE SIDE FOR LOAD OR DUMP
;        AND SET (TERM) SO THAT A BREAK IS NOT
;         SENSED.
;
;       ENTRY:  NONE
;       EXIT:   NONE
;       USES:   A,X

IN.PIA  LDX     #TERM
        CLR     1,X
        CLR     3,X
        LDAA    #%10000000
        STAA    0,X             ; INTO DDR
        COMA
        STAA    2,X             ; INITIALIZE CASSETTE
        LDAA    #4
        STAA    3,X
        RTS

;; Code below is in the ROM, but not in the source code in the manual.

RET     JSR     OUTIS
        DB      CR,LF
        ASC     "MEEGAN"
        DB      0
        BRA     RET

;;      TTST - TERMINAL TESTER
;
;       ENTRY:  NONE
;       EXIT:   NEVER

TTST    LDAA    #1
        STAA    TERM
        LDAB    #4
        STAB    TERM.C
TTS0    JSR     OUTIS
        DB      CR,LF
        ASC     "THIS IS A TERMINAL TEST"
        DB      0
        BRA     TTS0

;; Code below is in the ROM, but not in the source code in the manual.

        LDAA    TERM
        COMA
        ROLA
        BCC     X2
X1      TST     TERM
        BMI     X1
        SEC
X2      RTS
        LDAB    #08
        JSR     LOA0
        BCC     X3
        JMP     $144E
X3      RTS
        LDX     #0
        STX     T1
        LDX     $24
        STX     T2
        LDAB    #8
        JSR     PUNCH
        RTS

        DS      9,$FF

PATCH   TAB
        LSRB
        BEQ     P1
        INCB
P1      JMP     INC2

;; Fill the rest of the ROM with FFs.
        
        DS      $EC00-*,$FF
