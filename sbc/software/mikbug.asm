; MIKBUG and MINIBUG are ROM monitors for the 6800 from Motorola. Mike
; Holley at swtpc.com,
; http://www.swtpc.com/mholley/MP_A/MIKBUG_Index.htm has a Motorola
; "Engineering Note 100 MCM6830L7 MIKBUG" PDF document and MIKBUG
; source. The Note has listings for MIKBUG and MINIBUG. I'm guessing
; "MIK" is Mike Wiles, an author of the Note. From Mike Lee in
; Feb-April 2019, I obtained a varient of MIKBUG, which replaces the
; PIA parallel keyboard input with an ACIA serial input.

        NAM     MIKBUG
        CPU     6800
        OUTPUT  HEX             ; For Intel hex output
;       OUTPUT  SCODE           ; For Motorola S record (RUN) output

; REV 009A
;
; L  LOAD
; G  GO TO TARGET PROGRAM
; M  MEMORY CHANGE
; P  PRINT/PUNCH DUMP
; R  DISPLAY CONTENTS OF TARGET STACK
;     CC   B   A   X   P   S
;
; ADDRESS
ACIACS  EQU     $8300
ACIADA  EQU     ACIACS+1
VAR     EQU     $0100
;
;       OPT     MEMORY
        CODE
*       EQU     $F900
;
; I/O INTERRUPT SEQUENCE
IO      LDX     IOV
        JMP     0,X
;
; NMI SEQUENCE
POWDWN   LDX    NIO             ; GET NMI VECTOR
         JMP    0,X
;
; L COMMAND
LOAD    EQU     *
        LDAA    #$0D
        BSR     OUTCH
        NOP
        LDAA    #$0A
        BSR     OUTCH
;
; CHECK TYPE
LOAD3   BSR     INCH
        CMPA    #'S'
        BNE     LOAD3           ; 1ST CHAR NOT (S)
        BSR     INCH            ; READ CHAR
        CMPA    #'9'
        BEQ     LOAD21          ; START ADDRESS
        CMPA    #'1'
        BNE     LOAD3           ; 2ND CHAR NOT (1)
        CLR     CKSM            ; ZERO CHECKSUM
        BSR     BYTE            ; READ BYTE
        SUBA    #2
        STAA    BYTECT          ; BYTE COUNT
;
; BUILD ADDRESS
        BSR     BADDR
;
; STORE DATA
LOAD11  BSR     BYTE
        DEC     BYTECT
        BEQ     LOAD15          ; ZERO BYTE COUNT
        STAA    0,X             ; STORE DATA
        INX
        BRA     LOAD11
;
; ZERO BYTE COUNT
LOAD15  INC     CKSM
        BEQ     LOAD3
LOAD19  LDAA    #'?'            ; PRINT QUESTION MARK
        BSR     OUTCH
LOAD21  EQU     *
C1      JMP     CONTRL
;
; BUILD ADDRESS
BADDR   BSR     BYTE            ; READ 2 FRAMES
        STAA    XHI
        BSR     BYTE
        STAA    XLOW
        LDX     XHI             ; (X) ADDRESS WE BUILT
        RTS
;
; INPUT BYTE (TWO FRAMES)
BYTE    BSR     INHEX           ; GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR     INHEX
        ABA
        TAB
        ADDB    CKSM
        STAB    CKSM
        RTS
;
; OUT HEX BCD DIGIT
OUTHL   LSRA                    ; OUT HEX LEFT BCD DIGIT
        LSRA
        LSRA
        LSRA
OUTHR   ANDA    #$F             ; OUT HEX RIGHT BCD DIGIT
        ADDA    #$30
        CMPA    #$39
        BLS     OUTCH
        ADDA    #$7
;
;  OUTPUT ONE CHAR
OUTCH   JMP     OUTEEE
INCH    JMP     INEEE
;
; PRINT DATA POINTED AT BY X-REG
PDATA2  BSR     OUTCH
        INX
PDATA1  LDAA    0,X
        CMPA    #4
        BNE     PDATA2
        RTS                     ; STOP ON EOT
;
; CHANGE MENORY (M AAAA DD NN)
CHANGE  BSR     BADDR           ; BUILD ADDRESS
CHA51   LDX     #MCL
        BSR     PDATA1          ; C/R L/F
        LDX     #XHI
        BSR     OUT4HS          ; PRINT ADDRESS
        LDX     XHI
        BSR     OUT2HS          ; PRINT DATA (OLD)
        STX     XHI             ; SAVE DATA ADDRESS
        BSR     INCH            ; INPUT ONE CHAR
        CMPA    #$20
        BNE     CHA51           ; NOT SPACE
        BSR     BYTE            ; INPUT NEW DATA
        DEX
        STAA    0,X             ; CHANGE MEMORY
        CMPA    0,X
        BEQ     CHA51           ; DID CHANGE
        BRA     LOAD19          ; NOT CHANGED
;
; INPUT HEX CHAR
INHEX   BSR     INCH
        SUBA    #$30
        BMI     C1              ; NOT HEX
        CMPA    #$09
        BLE     IN1HG
        CMPA    #$11
        BMI     C1              ; NOT HEX
        CMPA    #$16
        BGT     C1              ; NOT HEX
        SUBA    #7
IN1HG   RTS
;
; OUTPUT 2 HEX CHAR
OUT2H   LDAA    0,X             ; OUTPUT 2 HEX CHAR
OUT2HA  BSR     OUTHL           ; OUT LEFT HEX CHAR
        LDAA    0,X
        INX
        BRA     OUTHR           ; OUTPUT RIGHT HEX CHAR AND R
;
; OUTPUT 2-4 HEX CHAR + SPACE
OUT4HS  BSR     OUT2H           ; OUTPUT 4 HEX CHAR + SPACE
OUT2HS  BSR     OUT2H           ; OUTPUT 2 HEX CHAR + SPACE
;
; OUTPUT SPACE
OUTS    LDAA    #$20            ; SPACE
        BRA     OUTCH           ; (BSR & RTS)
;
;**************************************************************
; ENTER POWER  ON SEQUENCE
START   EQU     *
        LDS     #STACK
        STS     SP              ; INZ TARGET'S STACK PNTR
;
; ACIA INITIALIZE
        LDAA    #$03            ; RESET CODE
        STAA    ACIACS
        NOP
        NOP
        NOP
        LDAA    #$15            ; 8N1 NON-INTERRUPT
        STAA    ACIACS
;
; COMMAND CONTROL
CONTRL  LDS     #STACK          ; SET CONTRL STACK POINTER
        LDX     #MCL
        BSR     PDATA1          ; PRINT DATA STRING
        BSR     INCH            ; READ CHARACTER
        TAB
        BSR     OUTS            ; PRINT SPACE
        CMPB    #'L'
        BNE     *+5
        JMP     LOAD
        CMPB    #'M'
        BEQ     CHANGE
        CMPB    #'R'
        BEQ     PRINT           ; STACK
        CMPB    #'P'
        BEQ     PUNCH           ; PRINT/PUNCH
        CMPB    #'G'
        BNE     CONTRL
        LDS     SP              ; RESTORE PGM'S STACK PTR
        RTI                     ; GO
;
; ENTER FROM SOFTWARE INTERRUPT
SFE     EQU     *
        STS     SP              ; SAVE TARGET'S STACK POINTER
;
; DECREMENT P-COUNTER
        TSX
        TST     6,X
        BNE     *+4
        DEC     5,X
        DEC     6,X
;
; PRINT CONTENTS OF STACK
PRINT   LDX     SP
        INX
        BSR     OUT2HS          ; CONDITION CODES
        BSR     OUT2HS          ; ACC-B
        BSR     OUT2HS          ; ACC-A
        BSR     OUT4HS          ; X-REG
        BSR     OUT4HS          ; P-COUNTER
        LDX     #SP
        BSR     OUT4HS          ; STACK POINTER
C2      BRA     CONTRL
;
; PUNCH DUMP
; PUNCH FROM BEGINING ADDRESS (BEGA) THRU ENDI
; ADDRESS (ENDA)
MTAPE1  DB      $D,$A,'S','1',4 ; PUNCH FORMAT
        DB      1,1,1,1         ; GRUE
PUNCH   EQU     *
        LDX     BEGA
        STX     TW              ; TEMP BEGINING ADDRESS
PUN11   LDAA    ENDA+1
        SUBA    TW+1
        LDAB    ENDA
        SBCB    TW
        BNE     PUN22
        CMPA    #16
        BCS     PUN23
PUN22   LDAA    #15
PUN23   ADDA    #4
        STAA    MCONT           ; FRAME COUNT THIS RECORD
        SUBA    #3
        STAA    TEMP            ; BYTE COUNT THIS RECORD
;
; PUNCH C/R,L/F,NULL,S,1
        LDX     #MTAPE1
        JSR     PDATA1
        CLRB                    ; ZERO CHECKSUM
;
; PUNCH FRAME COUNT
        LDX     #MCONT
        BSR     PUNT2           ; PUNCH 2 HEX CHAR
;
; PUNCH ADDRESS
        LDX     #TW
        BSR     PUNT2
        BSR     PUNT2
;
; PUNCH DATA
        LDX     TW
PUN32   BSR     PUNT2           ; PUNCH ONE BYTE (2 FRAMES)
        DEC     TEMP            ; DEC BYTE COUNT
        BNE     PUN32
        STX     TW
        COMB
        PSHB
        TSX
        BSR     PUNT2           ; PUNCH CHECKSUM
        PULB                    ; RESTORE STACK
        LDX     TW
        DEX
        CPX     ENDA
        BNE     PUN11
        BRA     C2              ; JMP TO CONTRL
;
; PUNCH 2 HEX CHAR UPDATE CHECKSUM
PUNT2   ADDB    0,X             ; UPDATE CHECKSUM
        JMP     OUT2H           ; OUTPUT TWO HEX CHAR AND RTS
;
MCL     DB      $D,$A,'*',4
;
; SAVE X REGISTER
SAV     STX     XTEMP
        RTS
        DB      1,1,1           ; GRUE
;
; INPUT ONE CHAR INTO A-REGISTER
INEEE   BSR     SAV
IN1     LDAA    ACIACS
        ASRA
        BCC     IN1             ; RECEIVE NOT READY
        LDAA    ACIADA          ; INPUT CHARACTER
        ANDA    #$7F            ; RESET PARITY BIT
        CMPA    #$7F
        BEQ     IN1             ; IF RUBOUT, GET NEXT CHAR
        BSR     OUTEEE
        RTS
;
; OUTPUT ONE CHAR
OUTEEE  PSHA
OUTEEE1 LDAA    ACIACS
        ASRA
        ASRA
        BCC     OUTEEE1
        PULA
        STAA    ACIADA
        RTS

;; FILL UNUSED LOCATIONS WITH FF

        DS      $FB00-*,$FF

;
; VECTOR
;*     EQU     $FFF8
;       DW      IO
;       DW      SFE
;       DW      POWDWN
;       DW      START

        DUMMY
*       EQU     VAR
IOV     DS      2               ; IO INTERRUPT POINTER
BEGA    DS      2               ; BEGINNING ADDR PRINT/PUNCH
ENDA    DS      2               ; ENDING ADDR PRINT/PUNCH
NIO     DS      2               ; NMI INTERRUPT POINTER
SP      DS      1               ; S-HIGH
        DS      1               ; S-LOW
CKSM    DS      1               ; CHECKSUM
BYTECT  DS      1               ; BYTE COUNT
XHI     DS      1               ; XREG HIGH
XLOW    DS      1               ; XREG LOW
TEMP    DS      1               ; CHAR COUNT (INADD)
TW      DS      2               ; TEMP
MCONT   DS      1               ; TEMP
XTEMP   DS      2               ; X-REG TEMP STORAGE
        DS      46
STACK   DS      1               ; STACK POINTER

;       END
