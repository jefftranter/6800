; This is a version of the 6800 Fantom II monitor that uses an ACIA for the serial interface.
; Adapted to the crasm assembler and modified for my 6800 Single Board
; Computer by Jeff Tranter <tranter@pobox.com>.

; Motorola Compiler options
; note: OPT line, one entry per line, padded with ' ' space at end of line
;       OPT    cre
;       OPT    l
;       OPT    s
;       OPT    c
;***    OPT    S,O      SYMBOL TABLE;OBJECT TAPE
;***    PAGE
;**Keywords for A09 compiler (arakula from Github)
; https://github.com/Arakula/A09
; compiles under Motorola compiler as well - see options above
;      *      *        *
;23456789012345678901234567890
;       SETLI 132
        NAM    FANTOMII
        CPU    6800
        OUTPUT  HEX             ; For Intel hex output
;       OUTPUT  SCODE           ; For Motorola S record (RUN) output
        CODE
;
; FANTOM-II is a 1-K byte loader/monitor/debugger program for the 6800.
; It can be supplied in a ROM or 2708 EPROM, or as firmware
; on the WINCE Control Module.
; FANTOM-II supports commands below entered from a teletype or equivalent
; terminal such as the WINTEK Model BRB video terminal or
; Texas Instrument ASR 700 (Silent 700)
;
; Note: To relocate - specify scratch pad RAM area, ACIA, and ROM start address
;
; Commands:
;      M - Display/Change Memory
;      R - Display/Change Instruction
; CNTL-A - DISPLAY/Change Accumulator A
; CNTL-B - DISPLAY/Change Accumulator B
; CNTL-C - DISPLAY/Change Condition Codes Register
; CNTL-P - DISPLAY/Change Program Counter
; CNTL-X - DISPLAY/Change Index Register
;      G - Go To User Program
;      S - Single Step User Program
;      D - Dump Memory
;      P - Punch Loader Compatible Tape
;      L - Load Memory
;
; WINTEK Copyright 1976
; WINTEK CORP.
; 902 N. 9 St.
; LAFAYETTE, IN 47904
; 317-742-6802
; Orig Author Jim Wilson, WINTEK
;
; WINCE 6800 Module RAM $ED80-$EDFF
;                       $0000-$017F
; FANTOM II
; RAM DECLARATIONS
*      EQU   $EDBE
USRSTK EQU    *-1      ;INITIAL VALUE OF USER S.P.
USRCCR DS     1        ;INITIAL LOCATIONS OF USER
USRACB DS     1        ; REGISTERS - VALID ON POWER
USRACA DS     1        ;  UP ONLY!!! USER MAY
USRIND DS     2        ;  CHANGE SUBSEQUENTLY
USRPCT DS     2
       DS     37       ;MONITOR STACK ARES
MONSTK EQU    *-1      ;INITIAL MONITOR S.P.
END    DS     2        ;PUNCH END ADDRESS
BEG    DS     2        ;PUNCH BEG ADDRESS
TEMP   DS     2        ;PUNCH BEG ADDRESS
USERS  DS     2        ;TEMP WORK AREA
TEM1   DS     2        ;MONITOR STACK POINT STORE
SYSSWI DS     3        ;SYSTEM SWI VECTOR
UIRQ   DS     3        ;USER IRQ VECTOR
USWI   DS     3        ;USER SWI VECTOR
UNMI   DS     3        ;USER NMI VECTOR


;*      ACIA ADDRESSES.

ACIACR EQU    $EE08
ACIASR EQU    $EE08
ACIADR EQU    $EE09

;*     FANTOM COMMAND HANDLES RULES:
;*     ALL FANTOM COMMAND HANDLERS MUST HAVE THEIR
;      ENTRY POINTS INSIDE THE SAME 256 BYTE PAGE
;      OF ROM SO THAT THEIR ENTRY POINT ADDRESS
;      MAY BE STORED IN A SINGLE BYTE.
;
;      ALL HANDLERS ARE CALLED WITH AN EFFECTIVE
;      -JSR- AND HAVE THE FOLLOWING ADDITIONAL
;      REQUIREMENTS:
;
;        ENTRY:  (B) = 0
;                (X) = (USER STACK POINTER)
;                (A) = ASCII COMMAND CHARACTER

*      EQU    $FC00
ROMBAS EQU    *

;*     GO--GO TO USER PROGRAM
;
;        ACCEPTS HEX ADDRESSES, INSERTS BREAKPOINTS,
;         SETS UP SWI RETURN AND
;          BEGINS EXECUTION OF USER CODE
;
;        ENTRY--(B) = 0
;                  ROM (RETURN) ADDRESS ONTO STACK
;                   WE WILL TRY TO CLEAR THIS LOCATION
;
;        EXIT--REMOVES BREAKPOINTS AND RETURNS TO
;                 THE MAIN MONITOR LOOP
;
;        USES--ALL REGISTERS

GO     LDX    #USWI    ;INCASE NO BREAKPOINTS
       BRA    GO2
GO1    PSHA
       PSHB
       TSX
       LDX    0,X
       LDAB   0,X
       LDAA   #$3F     ;REPLACE OPCODE WITH SWI
       STAA   0,X
       LDX    #GO5     ;BREAKPOINTS ARE ALIVE
GO2    PSHB
       BSR    AHV
       BCS    GO1
       JMP    GO4      ;GIVES CONTROL TO USER CODE

;*     PUNCH--PROCESS PUNCH COMMAND
;        ENTRY--DEFAULT VALUES ON STACK BELOW RET. ADDRESS
;
;                 RETURN ADDRESS
;                 RETURN ADDRESS
;                 END ADDRESS
;                 END ADDRESS (LO)
;                 BEG ADDRESS
;                 BEG ADDRESS (LO)
;
;        EXIT--AFTER ACCEPTING USER SPECIFIED BEGINNING
;                AND ENDING ADDRESSES, THIS SUBROUTINE
;                   PUNCHES OR DUMPS, AND THEN RETURNS
;                      TO THE CALLING ROUTINE. IT IS
;                          CALLERS RESPONSIBILITY TO
;                              CLEAN UP STACK
;

PUNCH  CLRA            ;DUMP WITH SPACES
PNCH1  INCB            ;NORMAL DUMP
       PSHA
       PSHB
       TSX
       BSR    AHV      ;GET BEGINNING ADDRESS
       BCC    PNCH2    ;USE DEFAULT INSTEAD
       STAA   7,X      ;STORE BEGINNING ADDRESS
       STAB   6,X
       BSR    AHV      ;END ADDRESS
       STAA   5,X
       STAB   4,X
PNCH2  PULA            ;NOW SET UP ACIA
       TST    1,X
       BEQ    PNCH3
       STAA   ACIACR
       LDAA   #$12     ;TAPE ON
       JSR    OUTCH
PNCH3  LDAA   7,X
       PSHA
       LDAA   6,X      ;CURRENT ADDRESS ONTO STACK
       PSHA
       JMP    PNCH4
MEM    DECB            ;BYTE DISPLAY
INST   PSHB            ;INSTRUCTION DISPLAY
       LDX    6,X
       BSR    AHV
       BCC    MEM1
       PSHA
       PSHB
       TSX
       LDX    0,X
       INS
       INS
MEM1   CLC             ;INSURES WE BRANCH
MEM2   PULB            ;RETRIEVE MODE FLAG
       BCC    MEM3
       BSR    STORE0
       INX
MEM3   JSR    TYPINS   ;TYPE THE DATA
       PSHB
       BSR    AHV      ;GET REPLACEMENT VALUE
       BLS    MEM2     ;IF CR OR VALID ENTRY
MEM4   PULB
       RTS

;*     AHV - ACCUMULATE HEX VALUE
;
;        READS HEX DIGITS FROM THE KEYBOARD; ACCUMULATES
;        THEM INTO A 16 BIT VALUE.
;
;        ENTRY:  NONE
;
;        EXIT    (BA) = ACCUMULATED VALUE IF VALID ENTRY
;                 (A) = ASCII VALUE OTHERWISE
;                'C' CLEAR IF NO VALID ENTRY
;                'Z' SET IF LAST CHARACTER TYPED WAS 'CR'
;
;        USES:   A,B,C

AHV    CLRB
       BSR    IHD      ;GET FIRST DIGIT
       BCC    AHV3
AHV1   PSHA
       PSHB
       ASLA
       ROLB
       ASLA
       ROLB
       ASLA
       ROLB
       ASLA
       ROLB
       PSHB
       PSHA            ;MAKE WAY FOR NEXT DIGIT
       BSR    IHD
       BCC    AHV2     ;THAT'S ALL FOLKS
       PULB
       ABA
       PULB
       INS             ;SKIP PREVIOUS VALUE
       INS
       BRA    AHV1
AHV2   INS             ;SKIP LATEST VALUE
       INS
       PULB
       PULA            ;GET OLD VALUE
       SEC
AHV3   RTS

;*     REG - REGISTER DISPLAY COMMANDS
;
;        ENTRY:   (X) = USER STACK POINTER
;                 (B) = 0
;
;        EXIT:    REGISTER CHANGED IF VALID HEX
;                    UNCHANGED OTHERWISE

REGP   INX
       INX
REGX   INX
       INCB
REGA   INX
REGB   INX
REGC   ADDA   #$40
       BSR    PTREGA
       PSHB
       BSR    AHV      ;GET REPLACEMENT VALUE
       BCC    MEM4     ;NO REPLACE - PUL B, RTS
       BSR    STORE0
       TBA
       PULB
       DECB
       BEQ    STORE1

;*     STORE - STORE AND CHECK BYTE
;
;        ENTRY: (X) = ADDRESS TO STORE
;
;        EXIT:  (A) STORED AT ADDRESS
;                  ERROR RETURNS TO MAIN MONITOR LOOP
;
;        USES:  C

STORE0 DEX
STORE  STAA   0,X
       CMPA   0,X
       BNE    LOAD7
STORE1 RTS

;*     EXEC - PROCESS 'EXEC' COMMAND.
;
;        HERE WE CALL 'SSTEP' TO EXECUTE ONE INSTRUCTION
;         FROM THE USER CODE AND THEN RETURN TO PRINT
;          HIS REGISTERS

EXEC   JSR    SSTEP

;**    REGS - DISPLAY ALL REGISTERS.
;
;        PRINTS REGISTERS IN THE FORM:
;
;        'C=__ B=__ A=__ X=____ P=____ S=____'

REGS   JSR    CLBLDX
       LDAA   #'C'
       BSR    PTREGA
       LDAA   #'B'
       BSR    PTREG
       LDAA   #'A'
       BSR    PTREG
       LDAA   #'X'
       BSR    PTREGB
       LDAA   #'P'
       BSR    PTREG
       LDAA   #'S'
       DEX
       STX    TEMP
       LDX    #TEMP-1

;*     OUTPUT ROUTINES
;
;        ENTRY: (A) = REGISTER NAME
;               (X) = ADDRESS OF STORED REG
;               (B) = NUMBER BYTES TO PRINT
;
;        EXIT:  REGISTER PRINTED
;               (X) = ADDRESS OF NEXT REGISTER
;
;        USERS: A,X

PTREGA INX             ;SKIP A BYTE FIRST
PTREGB INCB            ;PRINT MORE BYTES
PTREG  BSR    OUTCHA   ;ENTRY CONDITIONS APPLY HERE
       LDAA   #'='
       BSR    OUTCHA
       JMP    OUTREG

;*     IHD - INPUT HEX DIGIT
;
;        INPUTS A DIGIT FROM THE CONSOLE; CHECKS TO SEE
;        IF IT IS A VALID HEX DIGIT
;
;        ENTRY: NONE
;
;        EXIT:  (A) = HEX VALUE IF VALID ENTRY
;                   = ASCII VALUE OTHERWISE
;               'C' SET IF HEX
;               'Z' SET IF CR

IHD    BSR    INCH
       CMPA   #' '
       BEQ    IHD
       SUBA   #'0'
       BCS    IHD1     ;LESS THAN ZERO
       CMPA   #10
       BCS    IHD3     ;ZERO THRU NINE
       SUBA   #'A'-'0' ;DISLACE A TO ZERO
       CMPA   #6
       BCS    IHD2     ;A THRU F
       ADDA   #'A'-'0'
IHD1   ADDA   #'0'     ;DISPLACE BACK
       CMPA   #$D      ;SET 'Z' IF CR
       CLC
       RTS

;*     LOAD - PROCESS *LOAD* COMMAND.
;
;        LOADS MEMORY FROM CASSETTE OR PAPER TAPE
;            IN THE MIKBUG(TM) FORMAT
;
;        ENTRY: (B) = 0
;
;        EXIT:  VIA RTS EXCEPT ON ERROR - THEN TO
;               MAIN MONITOR LOOP.
;
;        USES:  ALL
;
;        ALL DONE - CHECK CHECKSUM

LOAD5  INCA
       BEQ    LOAD3
;      ERROR RETURN JUMPS HERE
LOAD7  JSR CRLF
       LDAA   #'?'
       JMP    MAIN1
;      NORMAL ENTRY IS AT 'LOAD'
;      OPTIONAL CASSETTE ENTRY IS 'LOAD1'

LOAD1  DECB            ;CASSETTE ENTRY
       STAB   ACIACR   ;RESET ACIA
LOAD   ADDB   #$9      ;NORMAL ENTRY
       STAB   ACIACR   ;FIX ACIA
       LDAA   #$11     ;READER-ON
       BSR    OUTCHA
LOAD3  BSR    INCH
       CMPA   #'S'
       BNE    LOAD3
       BSR    INCH
       SUBA   #'9'
       BEQ    IHD3     ;RETURN TO CALLER
       SUBA   #'1'-'9' ;CLEARS A IF S1
       BNE    LOAD3

;      WE HAVE 'S1' -- A WILL BE CHECKSUM

       BSR    IHB      ;GET BYTE COUNT
       SUBB   #2
       STAB   TEM1
       BSR    IHB      ;GET ADDRESS
       PSHB
       PSHB
       BSR    IHB
       TSX
       STAB   1,X
       LDX    0,X
       INS
       INS              ;PLACE INTO X REG
LOAD4  BSR    IHB       ;GET NEXT BYTE
       DEC    TEM1
       BEQ    LOAD5
       STAB   0,X
       INX
       BRA    LOAD4

;*     INCH - INPUT CHARACTER FROM CONSOLE
;
;        ENTRY: NONE
;        EXIT:  (A) = ASCII VALUE; RUBOUTS MASKED
;
;        USES   A,C

INCH   LDAA   ACIASR   ;GET RX STATUS
       LSRA            ;ROTATE RX BIT INTO C
       BCC    INCH
       LDAA   ACIADR   ;GET DATA
       CMPA   #$7F     ;IGNORE RUBOUTS
       BEQ    INCH
OUTCHA BRA    OUTCH    ;SHORT JUMP EXTENSION

;*     IHB - INPUT HEX BYTES
;
;        ENTRY: (A) = CHECKSUM
;
;        EXIT:  (A) = CHECKSUM + NEW DIGIT
;               (B) = NEW DIGIT

IHB    PSHA            ;CHECKSUM ONTO STACK
       BSR    IHD      ;GET FIRST DIGIT
       BCC    LOAD7    ;ERROR RETURN
       ASLA
       ASLA
       ASLA
       ASLA
       TAB
       BSR    IHD      ;GET SECOND DIGIT
       BCC    LOAD7
       ABA             ;COMBINE TWO DIGITS
       TAB
       PULA            ;GET CHECKSUM
       ABA             ;UPDATE CHECKSUM
       RTS

;      INPUT HEX DIGIT CONTINUED

IHD2   SUBA   #-10
IHD3   RTS             ;HEX RETURN

;*     TYPINS - TYPE ONE INSTRUCTION OR BYTE
;
;        ENTRY:   (X) = FWA INSTRUCTION OR BYTE
;                 (B) = < 0 THEN BYTE
;                       > 0  THEN INSTRUCTION
;
;        EXIT:    BYTE/INSTRUCTION TYPED ON NEW LINE
;                 (X) = ADDRES OF NEXT BYTE/INSTRUCTION
;
;        USES:    ALL, 'TEMP'

TYPINS LDAA   0,X      ;GET MEMORY BYTE
       PSHA            ;OPCODE ONTO STACK
       BSR    CRLF
       LDX    #TEMP
       BSR    OUT4HS
       PULA
       TSTB            ;IS THIS INSTRUCTION MODE?
       BMI    TYPIN1   ;NO IT ISN'T
       JSR    BYTCNT
       DECB
       BMI    LOAD7    ;NOT AN INSTRUCTION
TYPIN1 LDX    TEMP
       BSR    OUT2HS

;*     OUTREG - OUTPUT BYTE OR REGISTER
;
;        ENTRY: (X) = ADDRESS OF BYTE OR STORED REGISTER
;               (B) < 1 THEN NO BYTES TYPED
;                   = 1 THEN ONE BYTE TYPED
;                   > 2 THEN TWO BYTES TYPED
;
;        EXIT:  X INCREMENTED PAST BYTES(S)
;               (A) = ' '
;
;        USES:  A,B,C,X

OUTREG CMPB   #1       ;HOW MANY MORE BYTES?
       BMI    OUT2
       BEQ    OUT2HS

;*     OUT4HS - OUTPUT FOUR HEX DIGITS AND SPACE
;
;        ENTRY:   (X) = ADDRESS OF BYTES
;
;        EXIT:     X INCREMENTED PAST BYTES
;                 (A) = ' '
;        USES:    A,X

OUT4HS BSR    THB

;*     OUT2HS - OUTPUT TWO HEX DIGITS AND SPACE

OUT2HS BSR    THB

;*     OUTSP - OUTPUT SPACE CODE
;
;        ENTRY:  NONE
;
;        EXIT:   (A) = SPACE
;
;        USES:   A,C

OUTSP  LDAA   #' '

;*     OUTCH - OUTPUT CHARACTER TO CONSOLE
;
;        ENTRY: - (A) = ASCII VALUE OF CHARACTER
;
;        EXIT:  - (A) = ASCII VALUE
;
;        USES:    CCR EXCEPT 'C' BIT

OUTCH  PSHB
       LDAB   #2       ;MASK FOR ACIACR
OUT1   BITB   ACIASR
       BEQ    OUT1
       STAA   ACIADR   ;SEND (A) TO CONSOLE
       PULB
OUT2   RTS

;*     PUNT2 - PUNCH TWO DIGITS AND UPDATE CHECKSUM
;
;        ENTRY: (B) = CHECKSUM
;               (X) = ADDRESS
;
;        EXIT:  X INCREMENTED; CHECKSUM UPDATED
;
;        USES:  A,B,C,X

PUNT2  ADDB   0,X      ;UPDATE CHECKSUM

;*     THB - TYPE HEX BYTES.
;
;        ENTRY: (X) = ADDRESS OF BYTE TO OUTPUT IN HEX
;
;        EXIT:  (X) = OLDVALUE+1
;
;        USES:  A,X,C

THB    LDAA  0,X
       INX

;*     THB0 - TYPE (A) IN HEX
;
;        ENTRY: (A) = VALUE
;        EXIT:  VALUE TYPED
;        USES:  A,C

THB0   PSHA
       LSRA
       LSRA
       LSRA
       LSRA
       BSR    THB1
       PULA
       ANDA   #$F
THB1   CMPA   #10
       BCS    THB2
       ADDA   #7
THB2   ADDA   #$30
OUTCHB BRA    OUTCH    ;SHORT JUMP EXTENSION

;*     CRLF - TYPE CARRIAGE RETURN/LINEFEED
;
;        ENTRY: - NONE
;
;        EXIT:  - X POINTS PAST CR?LF STRING TO 'S1' STRING
;                 IF ENTERED AT CRLF, X STORED IN 'TEMP'

CRLF   STX    TEMP
CRLF1  LDX    #CRSTR
       BRA    OUTSTR

;      REST OF PUNCH ROUTINE

PNCH6  CMPB   #15
       BCS    PNCH8
PNCH7  LDAB   #15
PNCH8  PSHB            ;BYTE COUNT ON STACK
       LDAB   2,X      ;GET PUNCH FLAG
       BSR    CRLF1
       TSTB            ;PUNCH S1, BYTECOUNT?
       BEQ    PNCH9
       BSR    OUTSTR
       PULB
       PSHB            ;GET BYTE COUNT
       ADDB   #4       ;FRAME COUNT
       TBA
       BSR    THB0
PNCH9  TSX
       INX
       BSR    PUNT2
       BSR    PUNT2
PNCH85 TSX
       TST    3,X      ;SPACES REQUIRED?
       BNE    PNCH10
       BSR    OUTSP
PNCH10 LDX    1,X
       BSR    PUNT2
       TSX
       INC    2,X      ;INCREMENT ADDRESS POINTER ON STACK
       BNE    PNCH11
       INC    1,X
PNCH11 DEC    0,X
       BPL    PNCH85
       PULA            ;$FF INTO A
       TST    3,X      ;CHECKSUM?
       BEQ    PNCH4
       SBA             ;B-BAR INTO A
       BSR    THB0
PNCH4  TSX
       LDAB   6,X      ;END INTO (AB)
       LDAA   5,X
       SUBB   1,X      ;END - CURRENT INTO (AB)
       SBCA   0,X
       BHI    PNCH7    ;MORE THAN 256
       BCC    PNCH6    ;MORE THAN ZERO
       PULA
       PULA
       PULA
       TSTA
       BEQ    OUTST3
       LDX    #S9MSG

;*     OUTSTR -- OUTPUT CHARACTER STRING TO CONSOLE
;
;        ENTRY: -- (X) = ADDRESS OF STRING
;
;        EXIT:  -- (X) = INCREMENTED PAST END OF STRING
;                          END OF STRING MARKER IS NEGATIVE
;
;        USES:  -- A,X,C
OUTSTR LDAA   0,X
       INX
OUTST2 BSR    OUTCHB
       BPL    OUTSTR
OUTST3 RTS

;*     RESET -- POWER ON/USER CRASH RESET ROUTINE
;
;            SET UP ACIA, CHECK IF BREAKPOINTS ALIVE
;               AND ATTEMPT TO CLEAR THEM

RESET  LDX    #ACIACR-1
       STX    0,X      ;RESET ACIA
RESET1 DEX             ;RESET DELAY
       BNE RESET1

;      NOW TRY TO CLEAR ALL BREAKPOINTS

       LDS    #USRSTK
       STS    USERS    ;INITIALIZE FOR USER
       LDS    TEM1
RESET2 LDX    SYSSWI+1 ;SEE IF BREAKPOINTS ACTIVE
       CLR    SYSSWI+1
       CPX    #GO5
       BNE    MAINLP
RESET3 PULA
       TSX
       LDX    0,X
       INS
       INS
       STAA   0,X      ;LAST ONE IS ZERO
       BNE    RESET3   ;  BUT IT'S PLACED INTO ROM

;*     MAIN MONITOR LOOP - SENDS PROMPT AND ACCEPTS
;        COMMANDS;   ENTRY 'MAIN' IS ERROR RETURN

MAINLP CLRA            ;(A) SENT BEFORE PROMPT
MAIN1  LDS    #MONSTK  ;  ENTER HERE FOR ERROR
       LDAB   #$41     ; 7+E+2, 1/16, RTS FALSE
       STAB   ACIACR
       LDX    #PMTMSG
       BSR    CMDEX
       BRA    MAINLP

;*     BREAKPOINT RETURN
;
;        'GO' COMMAND HANDLER HAS SETUP UP SYSTEM
;          SWIVECTOR TO HERE IF THERE ARE ANY
;            BREAKPOINTS. WE MUST EXAMINE BREAKPOINT
;              TABLE TO SEE IF SWI IS BREAKPOINT OR
;                USER CODE. THE SWI MUST BE INTERPRETED
;                  IF IT IS PART OF USER CODE

GO3    INX
       INX
       INX
       TST    0,X      ;LOOK FOR LAST BREAKPOINT
       BNE    GO7
       BSR    SSTEP    ;STEP PAST USER SWI
       LDX    #GO5
GO4    STS    TEM1
       JMP    SWIVE1
GO5    TSX             ;RETURN HERE ON BREAKPOINT
       STS    USERS
       LDS    TEM1
       LDAA   6,X      ;DECREMENT USER PC
       BNE    GO6      ;  AND SAVE A COPY IN (BA)
       DEC    5,X
GO6    LDAB   5,X
       DECA
       STAA   6,X
       TSX
GO7    CMPB   1,X      ;SEARCH STACK FOR BREAKPOINT
       BNE    GO3
       CMPA   2,X
       BNE    GO3
       JSR CRLF
       JSR    REGS     ;PRINT USER REGISTERS
       BRA    RESET2

;*     CMDEX - COMMAND EXECUTE SUBROUTINE
;
;        COMPUTES AN ADDRESS BASED ON COMMAND INPUT
;          AND JUMPS TO CORRESPONDING HANDLER
;
;        ENTRY:  RETURN ADDRESS ON STACK
;
;        EXIT:   TO COMMAND HANDLER
;                (B) = 0
;                (X) = USER STACK POINTER
;
;        USES:   ALL,TEMP,TEM1

CMDEX  BSR    OUTST2   ;SEND PROMPT
       JSR    INCH     ;GET COMMAND
       PSHA
       DECA
CMDE1  INX
       CMPA   CMDDSP,X
       BCS    CMDE1
       BNE    MAINLP   ;ILLEGAL COMMAND
       JSR    OUTSP
       PULA
       LDAB   CMDTBL+CMDDSP,X
       PSHB
       LDAB   #ROMBAS/256
       PSHB            ;HANDLER ADDRESS ON STACK

;*     CLBLDX - SET B = 0; X = USERS

CLBLDX CLRB

;*     LDXU - SET (X) = USER S.P.

LDXU   LDX   USERS
       RTS             ;EXIT TO COMMAND HANDLER

;*     BYTCNT - DETERMINE NUMBER OF BYTES IN AN INSTRUCTION
;
;        ENTRY: -- OPCODE IN A
;
;        EXIT: -- (B) = NUMBER OF BYTES IN INSTRUCTION
;
;        USES: -- A,B,C,X
BYTCNT PSHA
       TAB
       LDX    #OPTAB-1
BYT1   INX
       SUBB   #8
       BCC    BYT1
       LDAA   0,X
BYT2   RORA
       INCB
       BNE    BYT2
       PULA
       BCS    BYT7
       CMPA   #$30     ;CHECK FOR BRANCH
       BCC    BYT3
       CMPA   #$20
       BCC    BYT5     ;IT IS A BRANCH
BYT3   CMPA   #$60
       BCS    BYT6     ;IT IS ONE BYTE
       CMPA   #$8D
       BEQ    BYT5     ;IT IS BSR
       ANDA   #$BD
       CMPA   #$8C
       BEQ    BYT4     ;IS X OR SP IMMEDIATE
       ANDA   #$30     ;CHECK FOR THREE BYTES
       CMPA   #$30
BYT4   SBCB   #$FF
BYT5   INCB
BYT6   INCB
BYT7   RTS

;*     SSTEP - PERFORM SINGLE STEP
;
;        THIS SUBROUTINE MAY BE CALLED TO EXECUTE A
;          SINGLE INSTRUCTION FROM THE USER CODE. ILLEGAL
;          INSTRUCTIONS ARE CHECKED AND THE STEP ROUTINE
;          REFUSES TO EXECUTE THEM.
;
;        MOST INSTRUCTIONS ARE EXECUTED OUT-OF-PLACE;
;          SOME INSTRUCTIONS (THOSE WHICH INVOLVE THE
;          P.C.) MUST BE INTERPRESTED. A SET OF HANDLERS
;          IS INCLUDED  FOR THIS SET OF INSTRUCTIONS

SSTEP  STS    TEMP     ;WE'LL USE THIS TO RETURN
       BSR    LDXU
       LDAA   7,X      ;PUSH USER PC ONTO STACK
       PSHA
       LDAA   6,X
       PSHA
       LDX    6,X      ;NOW GET USER PC INTO X
       LDAA   #$3F     ;SWI'S ARE NORMAL EXIT FROM
       PSHA            ;  SCRATCH PAD EXECUTE
       PSHA
       LDAA   2,X      ;COPY 3 BYTES OF PROGRAM
       PSHA
       LDAA   1,X
       PSHA
       LDAA   0,X      ;OP CODE SO
       PSHA            ;  SO SCRUTINIZE CAREFULLY
       BSR    BYTCNT
       BEQ    BSTRD
       TSX
       BCS    STEP1
       STAB   1,X      ;BRANCH OFFSET TO 2
STEP1  LDAA   #1
       CMPB   #2
       BGT    STEP3
       BEQ    STEP2    ;TWO BYTES
       STAA   1,X      ;FOR ONE BYTERS
STEP2  STAA   2,X      ;NOT FOR THREE BYTERS
STEP3  CLRA            ;NOW ADD BYTE COUNT TO PC
       ADDB   6,X
       ADCA   5,X
       STAA   5,X
       STAB   6,X

;      DOES THE INSTRUCTION INVOLVE THE PC?
;        IF SO THEN IT MUST BE INTERPRET

STEP4  BSR    LDXU
       STAA   6,X
       STAB   7,X      ;UPDATE PC ON USER STACK
       LDAB #6
       PULA
       PSHA            ;GET COPY OF OPCODE
       ANDA   #$CF     ;IS THIS A SUBROUTINE CALL?
       CMPA   #$8D
       PULA
       BEQ    BSRH
       CMPA   #$6E
       BEQ    JPXH     ;IT IS INDEXED JUMP
       CMPA   #$7E
       BEQ    JMPH     ;IT IS EXTENDED JUMP
       CMPA   #$39
       BEQ    RTSH     ;IT IS RTS
       CMPA   #$3B
       BEQ    RTIH     ;IT IS RTI
       CMPA   #$3F
       BEQ    SWIH     ;IT IS SWI
       STS    6,X      ;AIM USER PC AT SCRATCH AREA
       PSHA            ;REPLACE OPCODE
       LDX    #SSRET

;*     SWIVE1--SET UP SWI RETURN; JUMP TO USER CODE
;
;        ENTRY:--(X) = SWI VECTOR
;
;        EXIT: --TO USER PROGRAM

SWIVE1 LDAA   #$7E     ;JUMP OP CODE
       STAA   SYSSWI
       STX    SYSSWI+1
       LDS    USERS
       RTI

;      THE FOLLOWING CODE IS EXECUTED AFTER EXECUTION
;        OF AN OUT-OF-PLACE INSTRUCTION.  HERE WE CHECK
;          TO SEE IF A BRANCH HAS OCCURRED AND MODIFY
;            USER'S P.C. ACCORDINGLY

SSRET  TSX             ;GET SWI HIT LOCATION INTO X
       LDX   5,X
       INX
       CLRA
       CLRB
       CPX   TEMP
       BNE   BCHNTK

;      ADD THE BRANCH OFFSET TO THE USER PC

       DEX             ;X WILL NOW POINT AT USERPC
       LDX   0,X       ;SAVED VALUE OF PC INTO X
       DEX             ;FETCH BRANCH OFFSET
       LDAB  0,X
       BPL   PLUS
       COMA            ;A IS SIGN EXTENSION OF B
PLUS   TSX             ;POINT TO USERPC
       LDX   5,X
BCHNTK ADDB  1,X       ;ADD BRANCH OFFSET OR 0
       ADCA  0,X
       TSX             ;PLACE NEW USERPC ONTO STACK
       STAA  5,X
       STAB  6,X
       DEX             ;NOW X AND SP ARE EQUAL
STOX   STX   USERS
BSTRD  LDS   TEMP
       RTS             ;RETURN TO CALLING ROUTINE

;*     SPECIAL HANDLERS
;*     BSRH, JSRH - SUBROUTINE CALL HANDLERS

BSRH   CMPA  #$8D      ;IS IT BSR
       BNE   JSRH
       LDAA  #$5F      ;THIS CONVERTS BSR'S TO BRA'S
JSRH   SUBA  #$3F      ; JSR'S TO JUMPS
       PSHA            ;CORRECTED OPCODE ONTO STACK
       DEX
       DEX
       STX   USERS
JSRH1  LDAA  3,X
       STAA  1,X       ;MOVE USER REGISTERS
       INX
       DECB
       BPL   JSRH1
       BRA   STEP4     ;NOW EXECUTE JUMP INSTRUCT

;*     JPXH - INDEXED JUMP HANDLER

JPXH   PULB            ;GET OFFSET
       CLRA
       ADDB  5,X
       ADCA  4,X
       DB    $8C       ;CPX#: ONE BYTE BRA NEWPC
JMPH   PULA
       PULB
NEWPC  STAA  6,X
       STAB  7,X
       BRA   BSTRD     ;RETURN TO CALLER

;*     RTSH - SUBROUTINE RETURN HANDLER

RTSH   INX
       INX
       STX   USERS     ;NET PULL OF TWO BYTES
RTS1   LDAA  3,X       ;MOVE FIVE BYTES
       STAA  5,X
       DEX
       DECB
       BGT   RTS1
       BRA   BSTRD

;*     RTIH - RETURN FROM INTERRUPT HANDLER

RTIH   INX
       DECB
       BPL    RTIH
       BRA    STOX

;*     SWIH - SOFTWARE INTERRUPT HANDLER

SWIH   LDAA   7,X
       STAA   0,X
       DEX
       DECB
       BPL    SWIH
       ORAA   #%00010000  ;SET INTERUPT MASK
       STAA   1,X
       STX    USERS
       LDAB   #-USWI/256*256+USWI  ;USWI LO ORDER
       LDAA   #USWI/256
       BRA    NEWPC     ;PATCH IN USER IRQ ADDRESS

;*     STRING TABLES
PMTMSG DB     $D,$A,$13,$14,0,0,' ','*',' '+$80
PMTMSGL EQU   *-PMTMSG
S9MSG  DB     'S','9'
CRSTR  DB     $D,$A,0,0,0,$80
S1MSG  DB     'S','1'+$80

;*     COMMAND TABLE

CMDTAB EQU    *

CMDDSP EQU    CMDTAB-PMTMSG-PMTMSGL-1
       DB     'S'-1    ;SINGLE STEP
       DB     'R'-1    ;PRINT REGISTERS
       DB     'P'-1    ;PUNCH MEMORY
       DB     'M'-1    ;DISPLAY/ALTER MEMORY
       DB     'L'-1    ;LOAD MEMORY
       DB     'I'-1    ;DISPLAY INSTRUCTIONS
       DB     'G'-1    ;GO TO USERS PROGRAM
       DB     'D'-1    ;DUMP MEMORY
       DB     $18-1    ;CTL-X - DISPLAY X REGISTER
       DB     $10-1    ;CTL-P - DISPLAY P REGISTER
       DB     $C-1     ;CTL-L - CASSETTE LOAD
       DB     3-1      ;CTL-C - DISPLAY C REGISTER
       DB     2-1      ;CTL-B - DISPLAY B REGISTER
       DB     1-1      ;CTL-A - DISPLAY A REGISTER
CMDTBL EQU    *-CMDTAB

;      PROCESSOR ADDRESSES FOR ABOVE COMMANDS

       DB     EXEC-ROMBAS
       DB     REGS-ROMBAS
       DB     PNCH1-ROMBAS
       DB     MEM-ROMBAS
       DB     LOAD-ROMBAS
       DB     INST-ROMBAS
       DB     GO-ROMBAS
       DB     PUNCH-ROMBAS
       DB     REGX-ROMBAS
       DB     REGP-ROMBAS
       DB     LOAD1-ROMBAS
       DB     REGC-ROMBAS
       DB     REGB-ROMBAS
       DB     REGA-ROMBAS

;*     OPCODE TABLE - ONE BIT PER INSTRUCTION

OPTAB  DW     $9C00,$3CAF,$4000,$00AC
       DW     $6412,$6412,$6410,$6410
       DW     $1101,$1004,$1000,$1000
       DW     $110D,$100C,$100C,$100C

*      EQU $FFF8

;*     INTERRUPT VECTORS

       DW     UIRQ     ;USER IRQ HANDLER
       DW     SYSSWI   ;SYSTEM SWI HANDLER
       DW     UNMI     ;USER NMI HANDLER
       DW     RESET
;      END
