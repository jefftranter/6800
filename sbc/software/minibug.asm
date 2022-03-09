        NAM     MINIB
        CPU     6800
        OUTPUT  HEX             ; For Intel hex output
;       OUTPUT  SCODE           ; For Motorola S record (RUN) output

; MINI-BUG
; COPYWRITE 1973, MOTOROLA INC
; REV 004 (USED WITH MIKBUG)
ACIACS  EQU     $8300           ; ACIA CONTROL/STATUS
ACIADA  EQU     ACIACS+1
        CODE
*       EQU     $FB00
; MINIB
; INPUT ONE CHAR INTO A-REGISTER
INCH    LDAA     ACIACS
        ASRA
        BCC      INCH           ; RECEIVE NOT READY
        LDAA     ACIADA         ; INPUT CHARACTER
        ANDA     #$7F           ; RESET PARITY BIT
        CMPA     #$7F
        BEQ      INCH           ; RUBOUT; IGNORE
        JMP      OUTCH          ; ECHO CHAR

; INPUT HEX CHAR
INHEX   BSR      INCH
        CMPA     #'0'
        BMI      C1             ; NOT HEX
        CMPA     #'9'
        BLE      IN1HG
        CMPA     #'A'
        BMI      C1             ; NOT HEX
        CMPA     #'F'
        BGT      C1             ; NOT HEX
        SUBA     #7
IN1HG   RTS

LOAD    LDAA    #$15            ; TURN READER ON
        STAA    ACIACS
        LDAA    #$11
        BSR     OUTCH

LOAD3   BSR     INCH
        CMPA    #'S'
        BNE     LOAD3           ; 1ST CHAR NOT (S)
        BSR     INCH            ; READ CHAR
        CMPA    #'9'
        BEQ     LOAD21
        CMPA    #'1'
        BNE     LOAD3           ; 2ND CHAR NOT (1)
        CLR     CKSM            ; ZERO CHECKSUM
        BSR     BYTE            ; READ BYTE
        SUBA    #2
        STAA    BYTECT          ; BYTE COUNT
; BUILD ADDRESS
        BSR     BADDR
;STORE DATA
LOAD11  BSR     BYTE
        DEC     BYTECT
        BEQ     LOAD15          ; ZERO BYTE COUNT
        STAA    0,X             ; STORE PATH
        INX
        BRA     LOAD11

LOAD15  INC     CKSM
        BEQ     LOAD3
LOAD19  LDAA    #'?'            ; PRINT QUESTION MARK
        BSR     OUTCH
LOAD21  LDAA    #$15            ; TURN READER OFF
        STAA    ACIACS
        LDAA    #$13
        BSR     OUTCH
C1      JMP     CONTRL

; BUILD ADDRESS
BADDR   BSR     BYTE            ; READ 2 FRAMES
        STAA    XHI
        BSR     BYTE
        STAA    XLOW
        LDX     XHI             ; (X) ADDRESS WE BUILT
        RTS

; INPUT BYTE (TWO FRAMES)
BYTE    BSR     INHEX           ; GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TAB
        BSR     INHEX
        ANDA    #$0F            ; MASK TO 4 BITS
        ABA
        TAB
        ADDB    CKSM
        STAB    CKSM
        RTS

; CHANGE MEMORY (M AAAA DD NN)
CHANGE  BSR     BADDR           ; BUILD ADDRESS
        BSR     OUTS            ; PRINT SPACE
        BSR     OUT2HS
        BSR     BYTE
        DEX
        STAA    0,X
        CMPA    0,X
        BNE     LOAD19          ; MEMORY DID NOT CHANGE
        BRA     CONTRL

OUTHL   LSRA                    ; OUT HEX LEFT BCD DIGIT
        LSRA
        LSRA
        LSRA

OUTHR   ANDA    #$0F            ; OUT HEX RIGHT BCD DIGIT
        ADDA    #'0'
        CMPA    #'9'
        BLS     OUTCH
        ADDA    #$7

; OUTPUT ONE    CHAR
OUTCH   PSHB                    ; SAVE B-REG
OUTC1   LDAB    ACIACS
        ASRB
        ASRB
        BCC     OUTC1           ; XMIT NOT READY
        STAA    ACIADA          ; OUTPUT CHARACTER
        PULB                    ; RESTORE B-REG
        RTS

OUT2H   LDAA    0,X             ; OUTPUT 2 HEX CHAR
        BSR     OUTHL           ; OUT LEFT HEX CHAR
        LDAA    0,X
        BSR     OUTHR           ; OUT RIGHT HEX CHAR
        INX
        RTS

OUT2HS  BSR     OUT2H           ; OUTPUT 2 HEX CHAR + SPACE
OUTS    LDAA    #' '            ; SPACE
        BRA     OUTCH           ; (BSR & RTS)

; PRINT CONTENTS OF STACK
PRINT   TSX
        STX     SP              ; SAVE STACK POINTER
        LDAB    #9
PRINT2  BSR     OUT2HS          ; OUT 2 HEX & SPACE
        DECB
        BNE     PRINT2

; ENTER POWER ON SEQUENCE
START   EQU     *
; INZ ACIA
        LDAA    #$15            ; SET SYSTEM PARAMETERS
        STAA    ACIACS

CONTRL  LDS     #STACK          ; SET STACK POINTER
        LDAA    #$0D            ; CARRIAGE RETURN
        BSR     OUTCH
        LDAA    #$0A            ; LINE FEED
        BSR     OUTCH

JSR     INCH                    ; READ CHARACTER
        TAB
        BSR     OUTS            ; PRINT SPACE
        CMPB    #'L'
        BNE     *+5
        JMP     LOAD
        CMPB    #'M'
        BEQ     CHANGE
        CMPB    #'P'
        BEQ     PRINT           ; STACK
        CMPB    #'G'
        BNE     CONTRL
        RTI                     ; GO

        DUMMY
*       EQU     $0100
        DS      40
STACK   DS      1               ; STACK POINTER
; REGISTERS FOR GO
        DS      1               ; CONDITION CODES
        DS      1               ; B ACCUMULATOR
        DS      1               ; A
        DS      1               ; X-HIGH
        DS      1               ; X-LOW
        DS      1               ; P-HIGH
        DS      1               ; P-LOW
SP      DS      1               ; S-HIGH
        DS      1               ; S-LOW
; END REGISTERS FOR GO
CKSM    DS      1               ; CHECKSUM
BYTECT  DS      1               ; BYTE COUNT
XHI     DS      1               ; XREG HIGH
XLOW    DS      1               ; XREG LOW
;       END
