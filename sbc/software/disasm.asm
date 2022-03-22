;
; 6800 Disassembler
;
; Copyright (C) 2022 by Jeff Tranter <tranter@pobox.com>
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;
; TO DO:
; - Integrate with ROM monitor code
;
; Revision History
; Version Date         Comments
; 0.0     16-Mar-2022  First version started, based on 6502 version

        CPU     6800
;       OUTPUT  HEX             ; For Intel hex output
        OUTPUT  SCODE           ; For Motorola S record (RUN) output
        CODE

; *** CONSTANTS ***

; Characters:
 CR      = $0D ; Carriage return
 LF      = $0A ; Line feed
 SP      = $20 ; Space
 ESC     = $1B ; Escape

; External Routines:
; Uncomment desired version to work with.
 INCH    = $F520 ; Fantom II (ACIA) monitor input routine
 OUTCH   = $F569 ; Fantom II (ACIA) monitor output routine
;INCH    = $E8E1 ; Fantom II (PIA) monitor input routine
;OUTCH   = $E865 ; Fantom II (PIA) monitor output routine

; Instructions. Matches entries in table of MNEMONICS
 OP_INV  = $00
 OP_ABA  = $01
 OP_ADCA = $02
 OP_ADCB = $03
 OP_ADDA = $04
 OP_ADDB = $05
 OP_ANDA = $06
 OP_ANDB = $07
 OP_ASL  = $08
 OP_ASLA = $09
 OP_ASLB = $0A
 OP_ASR  = $0B
 OP_ASRA = $0C
 OP_ASRB = $0D
 OP_BCC  = $0E
 OP_BCS  = $0F
 OP_BEQ  = $10
 OP_BGE  = $11
 OP_BGT  = $12
 OP_BHI  = $13
 OP_BITA = $14
 OP_BITB = $15
 OP_BLE  = $16
 OP_BLS  = $17
 OP_BLT  = $18
 OP_BMI  = $19
 OP_BNE  = $1A
 OP_BPL  = $1B
 OP_BRA  = $1C
 OP_BSR  = $1D
 OP_BVC  = $1E
 OP_BVS  = $1F
 OP_CBA  = $20
 OP_CLC  = $21
 OP_CLI  = $22
 OP_CLR  = $23
 OP_CLRA = $24
 OP_CLRB = $25
 OP_CLV  = $26
 OP_CMPA = $27
 OP_CMPB = $28
 OP_COM  = $29
 OP_COMA = $2A
 OP_COMB = $2B
 OP_CPX  = $2C
 OP_DAA  = $2D
 OP_DEC  = $2E
 OP_DECA = $2F
 OP_DECB = $30
 OP_DES  = $31
 OP_DEX  = $32
 OP_EORA = $33
 OP_EORB = $34
 OP_INC  = $35
 OP_INCA = $36
 OP_INCB = $37
 OP_INS  = $38
 OP_INX  = $39
 OP_JMP  = $3A
 OP_JSR  = $3B
 OP_LDAA = $3C
 OP_LDAB = $3D
 OP_LDS  = $3E
 OP_LDX  = $3F
 OP_LSR  = $40
 OP_LSRA = $41
 OP_LSRB = $42
 OP_NEG  = $43
 OP_NEGA = $44
 OP_NEGB = $45
 OP_NOP  = $46
 OP_ORAA = $47
 OP_ORAB = $48
 OP_PSHA = $49
 OP_PSHB = $4A
 OP_PULA = $4B
 OP_PULB = $4C
 OP_ROL  = $4D
 OP_ROLA = $4E
 OP_ROLB = $4F
 OP_ROR  = $50
 OP_RORA = $51
 OP_RORB = $52
 OP_RTI  = $53
 OP_RTS  = $54
 OP_SBA  = $55
 OP_SBCA = $56
 OP_SBCB = $57
 OP_SEC  = $58
 OP_SEI  = $59
 OP_SEV  = $5A
 OP_STAA = $5B
 OP_STAB = $5C
 OP_STS  = $5D
 OP_STX  = $5E
 OP_SUBA = $5F
 OP_SUBB = $60
 OP_SWI  = $61
 OP_TAB  = $62
 OP_TAP  = $63
 OP_TBA  = $64
 OP_TPA  = $65
 OP_TST  = $66
 OP_TSTA = $67
 OP_TSTB = $68
 OP_TSX  = $69
 OP_TXS  = $6A
 OP_WAI  = $6B

; Addressing Modes. OPCODES table lists these for each instruction.
; LENGTHS lists the instruction length for each addressing mode.
 AM_INVALID = 0                 ; Example:
 AM_INHERENT = 1                ; RTS
 AM_IMMEDIATE = 2               ; LDAA #$12
 AM_IMMEDIATEX = 3              ; LDX #$1234
 AM_DIRECT = 4                  ; LDAA $12
 AM_INDEXED = 5                 ; LDAA $12,X
 AM_EXTENDED = 6                ; LDAA $1234
 AM_RELATIVE = 7                ; BNE $1234

; *** VARIABLES ***

; Variables
 * = $0100
 T1     DS 2                    ; Temp variable 1
 T2     DS 2                    ; Temp variable 2
 ADDR   DS 2                    ; Instruction address, 2 bytes (low/high)
 OPCODE DS 1                    ; Instruction opcode
 OP     DS 1                    ; Instruction type OP_*
 AM     DS 1                    ; Addressing mode AM_*
 LEN    DS 1                    ; Instruction length
 REL    DS 2                    ; Relative addressing branch offset (2 bytes)
 DEST   DS 2                    ; Relative address destination address (2 bytes)

; *** CODE ***

; Start address.
 * = $1000

; Main program disassembles starting from itself. Prompts user to hit
; key to continue after each screen.
START   JSR     PrintCR         ; Print newline
        LDX     #WelcomeString  ; Print welcome string
        JSR     PrintString
        LDX     #START          ; Start disassembling from START
        STX     ADDR
OUTER   JSR     PrintCR         ; Print newline
        LDAA    #23             ; Prompt every 23 lines
LOOP    PSHA                    ; Save line count
        JSR     DISASM          ; Disassemble one instruction
        PULA                    ; Restore line count
        DECA                    ; Decrement count
        BNE     LOOP            ; Go back if more lines to display
        LDX     #ContinueString ; Prompt to contnue
        JSR     PrintString
SpaceOrEscape JSR GetKey        ; Get a key
        CMPA    #' '            ; Space?
        BEQ     OUTER           ; If so, disassemble more lines
        CMPA    #ESC            ; Escape?
        BNE     SpaceOrEscape   ; If not, keep prompting
        RTS                     ; Escape pressed, so return

; Disassemble instruction at address ADDR (high) / ADDR+1 (low). On
; return ADDR/ADDR+1 points to next instruction so it can be called
; again.
DISASM  LDX     ADDR
        LDAA    0,X             ; Get instruction op code
        STAA    OPCODE          ; Save it

; Take opcode and double it by shifting (16-bits) since opcode table
; is two bytes per entry.
; Then add address of OPCODES table to get address in table.
; The instructions ASLB and ROLA together act as a 16-bit arithmetic
; left shift of the product in accumulators with MSB in A and LSB in B.

        CLRA                    ; Set MSB to zero
        LDAB    OPCODE          ; Set LSB to opcode
        ASLB                    ; Shift LSB
        ROLA                    ; Shift any carry into MSB
        STAA    T1              ; Save 16-bit value in T1
        STAB    T1+1

        LDX     #OPCODES        ; Start address of table
        STX     T2              ; Save 16-bit value in T2
        CLC                     ; 16-bit add: T1 = T1 + T2
        LDAA    T1+1            ; Low byte
        ADCA    T2+1
        STAA    T1+1
        LDAA    T1              ; High byte
        ADCA    T2              ; Includes possible carry
        STAA    T1

        LDX     T1              ; Get address of entry in table
        LDAA    0,X             ; Get the instruction type (e.g. OP_LDA)
        STAA    OP              ; Store it
        INX                     ; Advance to next field in table
        LDAA    0,X             ; Get addressing mode
        STAA    AM              ; Store it

        LDX     #LENGTHS        ; Get address of instruction lengths table
        STX     T1              ; Save it
        ADDA    T1+1            ; A contains length, add LSB of table address
        STAA    T1+1            ; And save

        LDX     T1              ; Get address of table entry
        LDAA    0,X             ; Get instruction length
        STAA    LEN             ; Save it

        LDX     ADDR
        JSR     PrintAddress    ; Print address
        LDX     #2
        JSR     PrintSpaces     ; Then two spaces
        LDAA    OPCODE          ; Get instruction op code
        JSR     PrintByte       ; Display the opcode byte
        JSR     PrintSpace

        LDAA    LEN             ; How many bytes in the instruction?
        CMPA    #3              ; Three?
        BEQ     THREE           ; If so, branch
        CMPA    #2              ; Two?
        BEQ     TWO             ; If so, branch
        LDX     #5              ; One byte instruction, print five padding spaces
        JSR     PrintSpaces
        BRA     MNEM

TWO     LDX     ADDR
        LDAA    1,X             ; Get 1st operand byte
        JSR     PrintByte       ; Display it
        LDX     #3              ; Three adding spaces
        JSR     PrintSpaces
        BRA     MNEM

THREE   LDX     ADDR
        LDAA    1,X             ; Get 1st operand byte
        JSR     PrintByte       ; Display it
        JSR     PrintSpace
        LDAA    2,X             ; Get 2nd operand byte
        JSR     PrintByte       ; Display it

MNEM    LDX     #2              ; print two padding spaces
        JSR     PrintSpaces

; Calculate entry in mnemonics table by taking opcode and multplying
; it by four (since entries are each 4 bytes long) and adding as
; offset to start of the table. Done by shifting to the left twice.

        CLRA                    ; Set MSB to zero
        LDAB    OP              ; Set LSB to opcode
        ASLB                    ; Shift LSB
        ROLA                    ; Shift any carry into MSB
        ASLB                    ; Shift LSB
        ROLA                    ; Shift any carry into MSB
        STAA    T1              ; Save 16-bit value in T1
        STAB    T1+1

        LDX     #MNEMONICS      ; Start address of table
        STX     T2              ; Save 16-bit value in T2
        CLC                     ; 16-bit add: T1 = T1 + T2
        LDAA    T1+1            ; Low byte
        ADCA    T2+1
        STAA    T1+1
        LDAA    T1              ; High byte
        ADCA    T2              ; Includes possible carry
        STAA    T1

        LDX     T1              ; Get entry in table
        LDAA    0,X             ; Get 1st character of mnemonic
        JSR     PrintChar       ; Any print it
        LDAA    1,X             ; Get 2nd character of mnemonic
        JSR     PrintChar       ; Any print it
        LDAA    2,X             ; Get 3rd character of mnemonic
        JSR     PrintChar       ; Any print it
        LDAA    3,X             ; Get 4th character of mnemonic
        JSR     PrintChar       ; Any print it
        JSR     PrintSpace

; Display any operands based on addressing mode

        LDX     ADDR            ; Set X to first address of instruction

        LDAA    AM              ; Get addressing mode
        CMPA    #AM_INVALID     ; Is it invalid?
        BNE     TRYINH          ; Branch if not
        JMP     DONEOPS         ; If so, then no operands

TRYINH  CMPA    #AM_INHERENT    ; Is it inherent?
        BNE     TRYIMM          ; Branch if not
        JMP     DONEOPS         ; If so, then no operands

TRYIMM  CMPA    #AM_IMMEDIATE   ; Is it immediate?
        BNE     TRYIMX          ; Branch if not
        LDAA    #'#'            ; Print "#"
        JSR     PrintChar
        JSR     PrintDollar     ; Print "$"
        LDAA    1,X             ; Get 1st operand byte (immediate data)
        JSR     PrintByte       ; Display it
        JMP     DONEOPS

TRYIMX  CMPA    #AM_IMMEDIATEX  ; Is it immediate indexed?
        BNE     TRYDIR          ; Branch if not
        LDAA    #'#'            ; Print "#"
        JSR     PrintChar
        JSR     PrintDollar     ; Print "$"
        LDAA    1,X             ; Get 1st operand byte of immediate data
        JSR     PrintByte       ; Display it
        LDAA    2,X             ; Get 2nd operand byte of immediate data
        JSR     PrintByte       ; Display it
        JMP DONEOPS

TRYDIR  CMPA    #AM_DIRECT      ; Is it direct?
        BNE     TRYIND          ; Branch if not
        JSR     PrintDollar     ; Print "$"
        LDAA    1,X             ; Get 1st operand byte
        JSR     PrintByte       ; Display it
        JMP DONEOPS

TRYIND  CMPA    #AM_INDEXED     ; Is it indexed?
        BNE     TRYEXT          ; Branch if not
        JSR     PrintDollar     ; Print "$"
        LDAA    1,X             ; Get 1st operand byte
        JSR     PrintByte       ; Display it
        JSR     PrintCommaX     ; Display ",X"
        JMP DONEOPS

TRYEXT  CMPA    #AM_EXTENDED    ; Is it extended?
        BNE     TRYREL          ; Branch if not
        JSR     PrintDollar     ; Print "$"
        LDAA    1,X             ; Get 1st operand byte of immediate data
        JSR     PrintByte       ; Display it
        LDAA    2,X             ; Get 2nd operand byte of immediate data
        JSR     PrintByte       ; Display it
        JMP     DONEOPS

TRYREL  CMPA    #AM_RELATIVE    ; Is it relative branch?
        BNE     DONEOPS         ; Branch if not
        JSR     PrintDollar

; Handle relative addressing
; Destination address is current address + relative (sign extended so upper byte is $00 or $FF) + 2

        LDAA    0,X             ; Get 1st operand byte (relative branch offset)
        STAA    REL+1           ; Save low byte of offset
        BMI     SNEG            ; If negative, need to sign extend
        LDAA    #0              ; High byte is zero
        BEQ     SADD
SNEG    LDAA    #$FF            ; Negative offset, high byte if $FF
SADD    STAA    REL             ; Save offset high byte
        LDAA    ADDR+1          ; Take adresss
        CLC
        ADCA    REL+1           ; Add offset
        STAA    DEST+1          ; And store
        LDAA    ADDR            ; Also high byte (including carry)
        ADCA    REL
        STAA    DEST
        LDAA    DEST+1          ; Now need to add 2 more to the address
        CLC
        ADCA    #2
        STAA    DEST+1
        LDAA    DEST
        ADCA    #0              ; Add any carry
        STAA    DEST
        JSR     PrintByte       ; Display high byte
        LDAA    DEST+1
        JSR     PrintByte       ; Display low byte

DONEOPS JSR     PrintCR         ; Print a final CR
        CLC
        LDAA    ADDR+1          ; Increment address to point to next instruction
        ADCA    LEN             ; by adding instruction length
        STAA    ADDR+1
        LDAA    ADDR            ; High byte
        ADCA    #0              ; Add any carry
        STAA    ADDR
        RTS

;------------------------------------------------------------------------
; Utility functions

; Print a dollar sign
; Registers changed: None
PrintDollar PSHA                ; Save A
        LDAA    #'$'
        JSR     PrintChar
        PULA                    ; Restore A
        RTS

; Print ",X"
; Registers changed: None
PrintCommaX PSHA                ; Save A
        LDAA    #','
        JSR     PrintChar
        LDAA    #'X'
        JSR     PrintChar
        PULA                    ; Restore A
        RTS

; Print a carriage return/linefeed
; Registers changed: None
PrintCR PSHA                    ; Save A
        LDAA    #CR
        JSR     PrintChar
        LDAA    #LF
        JSR     PrintChar
        PULA                    ; Restore A
        RTS

; Print a space
; Registers changed: None
PrintSpace PSHA                 ; Save A
        LDAA    #SP
        JSR     PrintChar
        PULA                    ; Restore A
        RTS

; Print number of spaces in X
; Registers changed: X
PrintSpaces PSHA
        LDAA    #SP
LOOP1   JSR     PrintChar
        DEX
        BNE     LOOP1
        PULA
        RTS

; Output character in A
; Registers changed: none
PrintChar JMP   OUTCH

; Get character from keyboard
; Returns in A
; Registers changed: A
GetKey  JMP     INCH

; Print 16-bit address in hex
; Pass byte in X
; Registers changed: None
PrintAddress STX T1             ; Save address
        LDAA    T1              ; Get high byte
        JSR     PrintByte       ; Print it
        LDAA    T1+1            ; Get low byte
        BRA     PrintByte       ; Print it

; Print byte as two hex chars.
; Pass byte in A
; Registers changed: None
PrintByte PSHA                  ; Save A for LSD.
        LSRA
        LSRA
        LSRA                    ; MSD to LSD position.
        LSRA
        JSR     PrintHex        ; Output hex digit
        PULA                    ; Restore A
                                ; Falls through into PrintHex routine

; Print nybble as one hex digit.
; Pass byte in A
; Registers changed: A
PrintHex ANDA   #$0F            ; Mask LSD for hex print
        ORAA    #'0'            ; Add "0"
        CMPA    #'9'            ; Digit?
        BLE     PrintChar       ; Yes, output it
        ADDA    #$07            ; Add offset for letter
        BRA     PrintChar       ; Print it

; Print a string
; Pass address of string in X.
; String must be terminated in a null.
; Registers changed: A, X
PrintString LDAA 0,X            ; Get character
        BEQ     done            ; Branch if null
        JSR     PrintChar       ; Print character
        INX                     ; Advance pointer
        BRA     PrintString     ; Go back
done    RTS                     ; Return

; DATA

; Table of instruction strings. 4 bytes per table entry
MNEMONICS ASC "??? " ; $00
 ASC "ABA " ; $01
 ASC "ADCA" ; $02
 ASC "ADCB" ; $03
 ASC "ADDA" ; $04
 ASC "ADDB" ; $05
 ASC "ANDA" ; $06
 ASC "ANDB" ; $07
 ASC "ASL " ; $08
 ASC "ASLA" ; $09
 ASC "ASLB" ; $0A
 ASC "ASR " ; $0B
 ASC "ASRA" ; $0C
 ASC "ASRB" ; $0D
 ASC "BCC " ; $0E
 ASC "BCS " ; $0F
 ASC "BEQ " ; $10
 ASC "BGE " ; $11
 ASC "BGT " ; $12
 ASC "BHI " ; $13
 ASC "BITA" ; $14
 ASC "BITB" ; $15
 ASC "BLE " ; $16
 ASC "BLS " ; $17
 ASC "BLT " ; $18
 ASC "BMI " ; $19
 ASC "BNE " ; $1A
 ASC "BPL " ; $1B
 ASC "BRA " ; $1C
 ASC "BSR " ; $1D
 ASC "BVC " ; $1E
 ASC "BVS " ; $1F
 ASC "CBA " ; $20
 ASC "CLC " ; $21
 ASC "CLI " ; $22
 ASC "CLR " ; $23
 ASC "CLRA" ; $24
 ASC "CLRB" ; $25
 ASC "CLV " ; $26
 ASC "CMPA" ; $27
 ASC "CMPB" ; $28
 ASC "COM " ; $29
 ASC "COMA" ; $2A
 ASC "COMB" ; $2B
 ASC "CPX " ; $2C
 ASC "DAA " ; $2D
 ASC "DEC " ; $2E
 ASC "DECA" ; $2F
 ASC "DECB" ; $30
 ASC "DES " ; $31
 ASC "DEX " ; $32
 ASC "EORA" ; $33
 ASC "EORB" ; $34
 ASC "INC " ; $35
 ASC "INCA" ; $36
 ASC "INCB" ; $37
 ASC "INS " ; $38
 ASC "INX " ; $39
 ASC "JMP " ; $3A
 ASC "JSR " ; $3B
 ASC "LDAA" ; $3C
 ASC "LDAB" ; $3D
 ASC "LDS " ; $3E
 ASC "LDX " ; $3F
 ASC "LSR " ; $40
 ASC "LSRA" ; $41
 ASC "LSRB" ; $42
 ASC "NEG " ; $43
 ASC "NEGA" ; $44
 ASC "NEGB" ; $45
 ASC "NOP " ; $46
 ASC "ORAA" ; $47
 ASC "ORAB" ; $48
 ASC "PSHA" ; $49
 ASC "PSHB" ; $4A
 ASC "PULA" ; $4B
 ASC "PULB" ; $4C
 ASC "ROL " ; $4D
 ASC "ROLA" ; $4E
 ASC "ROLB" ; $4F
 ASC "ROR " ; $50
 ASC "RORA" ; $51
 ASC "RORB" ; $52
 ASC "RTI " ; $53
 ASC "RTS " ; $54
 ASC "SBA " ; $55
 ASC "SBCA" ; $56
 ASC "SBCB" ; $57
 ASC "SEC " ; $58
 ASC "SEI " ; $59
 ASC "SEV " ; $5A
 ASC "STAA" ; $5B
 ASC "STAB" ; $5C
 ASC "STS " ; $5D
 ASC "STX " ; $5E
 ASC "SUBA" ; $5F
 ASC "SUBB" ; $60
 ASC "SWI " ; $61
 ASC "TAB " ; $62
 ASC "TAP " ; $63
 ASC "TBA " ; $64
 ASC "TPA " ; $65
 ASC "TST " ; $66
 ASC "TSTA" ; $67
 ASC "TSTB" ; $68
 ASC "TSX " ; $69
 ASC "TXS " ; $6A
 ASC "WAI " ; $6B

; Lengths of instructions given an addressing mode. Matches values of
; AM_* in the order INVALID, INHERENT, IMMEDIATE, IMMEDIATEX, DIRECT,
; INDEXED, EXTENDED, RELATIVE.
; Make sure this table does not cross a page boundary!
LENGTHS DB 1, 1, 2, 3, 2, 2, 3, 2

; Opcodes. Listed in order. Defines the mnemonic and addressing mode.
; 2 bytes per table entry
OPCODES DB OP_INV, AM_INVALID     ; $00
 DB OP_NOP, AM_INHERENT           ; $01
 DB OP_INV, AM_INVALID            ; $02
 DB OP_INV, AM_INVALID            ; $03
 DB OP_INV, AM_INVALID            ; $04
 DB OP_INV, AM_INVALID            ; $05
 DB OP_TAP, AM_INHERENT           ; $06
 DB OP_TPA, AM_INHERENT           ; $07
 DB OP_INX, AM_INHERENT           ; $08
 DB OP_DEX, AM_INHERENT           ; $09
 DB OP_CLV, AM_INHERENT           ; $0A
 DB OP_SEV, AM_INHERENT           ; $0B
 DB OP_CLC, AM_INHERENT           ; $0C
 DB OP_SEC, AM_INHERENT           ; $0D
 DB OP_CLI, AM_INHERENT           ; $0E
 DB OP_SEI, AM_INHERENT           ; $0F

 DB OP_SBA, AM_INHERENT           ; $10
 DB OP_CBA, AM_INHERENT           ; $11
 DB OP_INV, AM_INVALID            ; $12
 DB OP_INV, AM_INVALID            ; $13
 DB OP_INV, AM_INVALID            ; $14
 DB OP_INV, AM_INVALID            ; $15
 DB OP_TAB, AM_INHERENT           ; $16
 DB OP_TBA, AM_INHERENT           ; $17
 DB OP_INV, AM_INVALID            ; $18
 DB OP_DAA, AM_INHERENT           ; $19
 DB OP_INV, AM_INVALID            ; $1a
 DB OP_ABA, AM_INHERENT           ; $1B
 DB OP_INV, AM_INVALID            ; $1C
 DB OP_INV, AM_INVALID            ; $1D
 DB OP_INV, AM_INVALID            ; $1E
 DB OP_INV, AM_INVALID            ; $1F

 DB OP_BRA, AM_RELATIVE           ; $20
 DB OP_INV, AM_INHERENT           ; $21
 DB OP_BHI, AM_RELATIVE           ; $22
 DB OP_BLS, AM_RELATIVE           ; $23
 DB OP_BCC, AM_RELATIVE           ; $24
 DB OP_BCS, AM_RELATIVE           ; $25
 DB OP_BNE, AM_RELATIVE           ; $26
 DB OP_BEQ, AM_RELATIVE           ; $27
 DB OP_BVC, AM_RELATIVE           ; $28
 DB OP_BVS, AM_RELATIVE           ; $29
 DB OP_BPL, AM_RELATIVE           ; $2A
 DB OP_BMI, AM_RELATIVE           ; $2B
 DB OP_BGE, AM_RELATIVE           ; $2C
 DB OP_BLT, AM_RELATIVE           ; $2D
 DB OP_BGT, AM_RELATIVE           ; $2E
 DB OP_BLE, AM_RELATIVE           ; $2F

 DB OP_TSX, AM_INHERENT           ; $30
 DB OP_INS, AM_INHERENT           ; $31
 DB OP_PULA, AM_INHERENT          ; $32
 DB OP_PULB, AM_INHERENT          ; $33
 DB OP_DES, AM_INHERENT           ; $34
 DB OP_TXS, AM_INHERENT           ; $35
 DB OP_PSHA, AM_INHERENT          ; $36
 DB OP_PSHB, AM_INHERENT          ; $37
 DB OP_INV, AM_INVALID            ; $38
 DB OP_RTS, AM_INHERENT           ; $39
 DB OP_INV, AM_INHERENT           ; $3A
 DB OP_RTI, AM_INHERENT           ; $3B
 DB OP_INV, AM_INHERENT           ; $3C
 DB OP_INV, AM_INHERENT           ; $3D
 DB OP_WAI, AM_INHERENT           ; $3E
 DB OP_SWI, AM_INHERENT           ; $3F

 DB OP_NEGA, AM_INHERENT          ; $40
 DB OP_INV, AM_INHERENT           ; $41
 DB OP_INV, AM_INHERENT           ; $43
 DB OP_COMA, AM_INHERENT          ; $43
 DB OP_LSRA, AM_INHERENT          ; $44
 DB OP_INV, AM_INHERENT           ; $45
 DB OP_RORA, AM_INHERENT          ; $46
 DB OP_ASRA, AM_INHERENT          ; $47
 DB OP_ASLA, AM_INHERENT          ; $48
 DB OP_ROLA, AM_INHERENT          ; $49
 DB OP_DECA, AM_INHERENT          ; $4A
 DB OP_INV, AM_INHERENT           ; $4B
 DB OP_INCA, AM_INHERENT          ; $4C
 DB OP_TSTA, AM_INHERENT          ; $4D
 DB OP_INV, AM_INHERENT           ; $4E
 DB OP_CLRA, AM_INHERENT          ; $4F

 DB OP_NEGB, AM_INHERENT          ; $50
 DB OP_INV, AM_INHERENT           ; $51
 DB OP_INV, AM_INHERENT           ; $52
 DB OP_COMB, AM_INHERENT          ; $53
 DB OP_LSRB, AM_INHERENT          ; $54
 DB OP_INV, AM_INHERENT           ; $55
 DB OP_RORB, AM_INHERENT          ; $56
 DB OP_ASRB, AM_INHERENT          ; $57
 DB OP_ASLB, AM_INHERENT          ; $58
 DB OP_ROLB, AM_INHERENT          ; $59
 DB OP_DECB, AM_INHERENT          ; $5A
 DB OP_INV, AM_INHERENT           ; $5B
 DB OP_INCB, AM_INHERENT          ; $5C
 DB OP_TSTB, AM_INHERENT          ; $5D
 DB OP_INV, AM_INHERENT           ; $5E
 DB OP_CLRB, AM_INHERENT          ; $5F

 DB OP_NEG, AM_INDEXED            ; $60
 DB OP_INV, AM_INHERENT           ; $61
 DB OP_INV, AM_INHERENT           ; $62
 DB OP_COM, AM_INDEXED            ; $63
 DB OP_LSR, AM_INDEXED            ; $64
 DB OP_INV, AM_INHERENT           ; $65
 DB OP_ROR, AM_INDEXED            ; $66
 DB OP_ASR, AM_INDEXED            ; $67
 DB OP_ASL, AM_INDEXED            ; $68
 DB OP_ROL, AM_INDEXED            ; $69
 DB OP_DEC, AM_INDEXED            ; $6A
 DB OP_INV, AM_INHERENT           ; $6B
 DB OP_INC, AM_INDEXED            ; $6C
 DB OP_TST, AM_INDEXED            ; $6D
 DB OP_JMP, AM_INDEXED            ; $6E
 DB OP_CLR, AM_INDEXED            ; $6F

 DB OP_NEG, AM_EXTENDED           ; $70
 DB OP_INV, AM_INHERENT           ; $71
 DB OP_INV, AM_INHERENT           ; $72
 DB OP_COM, AM_EXTENDED           ; $73
 DB OP_LSR, AM_EXTENDED           ; $74
 DB OP_INV, AM_INHERENT           ; $75
 DB OP_ROR, AM_EXTENDED           ; $76
 DB OP_ASR, AM_EXTENDED           ; $77
 DB OP_ASL, AM_EXTENDED           ; $78
 DB OP_ROL, AM_EXTENDED           ; $79
 DB OP_DEC, AM_EXTENDED           ; $7A
 DB OP_INV, AM_INHERENT           ; $7B
 DB OP_INC, AM_EXTENDED           ; $7C
 DB OP_TST, AM_EXTENDED           ; $7D
 DB OP_JMP, AM_EXTENDED           ; $7E
 DB OP_CLR, AM_EXTENDED           ; $7F

 DB OP_SUBA, AM_IMMEDIATE         ; $80
 DB OP_CMPA, AM_IMMEDIATE         ; $81
 DB OP_SBCA, AM_IMMEDIATE         ; $82
 DB OP_INV, AM_INHERENT           ; $83
 DB OP_ANDA, AM_IMMEDIATE         ; $84
 DB OP_BITA, AM_IMMEDIATE         ; $85
 DB OP_LDAA, AM_IMMEDIATE         ; $86
 DB OP_INV, AM_INHERENT           ; $87
 DB OP_EORA, AM_IMMEDIATE         ; $88
 DB OP_ADCA, AM_IMMEDIATE         ; $89
 DB OP_ORAA, AM_IMMEDIATE         ; $8A
 DB OP_ADDA, AM_IMMEDIATE         ; $8B
 DB OP_CPX, AM_IMMEDIATEX         ; $8C
 DB OP_BSR, AM_RELATIVE           ; $8D
 DB OP_LDS, AM_IMMEDIATEX         ; $8E
 DB OP_INV, AM_INHERENT           ; $8F

 DB OP_SUBA, AM_DIRECT            ; $90
 DB OP_CMPA, AM_DIRECT            ; $91
 DB OP_SBCA, AM_DIRECT            ; $92
 DB OP_INV, AM_INHERENT           ; $93
 DB OP_ANDA, AM_DIRECT            ; $94
 DB OP_BITA, AM_DIRECT            ; $95
 DB OP_LDAA, AM_DIRECT            ; $96
 DB OP_STAA, AM_DIRECT            ; $97
 DB OP_EORA, AM_DIRECT            ; $98
 DB OP_ADCA, AM_DIRECT            ; $99
 DB OP_ORAA, AM_DIRECT            ; $9A
 DB OP_ADDA, AM_DIRECT            ; $9B
 DB OP_CPX, AM_DIRECT             ; $9C
 DB OP_INV, AM_INHERENT           ; $9D
 DB OP_LDS, AM_DIRECT             ; $9E
 DB OP_STS, AM_DIRECT             ; $9F

 DB OP_SUBA, AM_INDEXED           ; $A0
 DB OP_CMPA, AM_INDEXED           ; $A1
 DB OP_SBCA, AM_INDEXED           ; $A2
 DB OP_INV, AM_INHERENT           ; $A3
 DB OP_ANDA, AM_INDEXED           ; $A4
 DB OP_BITA, AM_INDEXED           ; $A5
 DB OP_LDAA, AM_INDEXED           ; $A6
 DB OP_STAA, AM_INDEXED           ; $A7
 DB OP_EORA, AM_INDEXED           ; $A8
 DB OP_ADCA, AM_INDEXED           ; $A9
 DB OP_ORAA, AM_INDEXED           ; $AA
 DB OP_ADDA, AM_INDEXED           ; $AB
 DB OP_CPX, AM_INDEXED            ; $AC
 DB OP_JSR, AM_INDEXED            ; $AD
 DB OP_LDS, AM_INDEXED            ; $AE
 DB OP_STS, AM_INDEXED            ; $AF

 DB OP_SUBA, AM_EXTENDED          ; $B0
 DB OP_CMPA, AM_EXTENDED          ; $B1
 DB OP_SBCA, AM_EXTENDED          ; $B2
 DB OP_INV, AM_INHERENT           ; $B3
 DB OP_ANDA, AM_EXTENDED          ; $B4
 DB OP_BITA, AM_EXTENDED          ; $B5
 DB OP_LDAA, AM_EXTENDED          ; $B6
 DB OP_STAA, AM_EXTENDED          ; $B7
 DB OP_EORA, AM_EXTENDED          ; $B8
 DB OP_ADCA, AM_EXTENDED          ; $B9
 DB OP_ORAA, AM_EXTENDED          ; $BA
 DB OP_ADDA, AM_EXTENDED          ; $BB
 DB OP_CPX, AM_EXTENDED           ; $BC
 DB OP_JSR, AM_EXTENDED           ; $BD
 DB OP_LDS, AM_EXTENDED           ; $BE
 DB OP_STS, AM_EXTENDED           ; $BF

 DB OP_SUBB, AM_IMMEDIATE         ; $C0
 DB OP_CMPB, AM_IMMEDIATE         ; $C1
 DB OP_SBCB, AM_IMMEDIATE         ; $C2
 DB OP_INV, AM_INHERENT           ; $C3
 DB OP_ANDB, AM_IMMEDIATE         ; $C4
 DB OP_BITB, AM_IMMEDIATE         ; $C5
 DB OP_LDAB, AM_IMMEDIATE         ; $C6
 DB OP_INV, AM_INHERENT           ; $C7
 DB OP_EORB, AM_IMMEDIATE         ; $C8
 DB OP_ADCB, AM_IMMEDIATE         ; $C9
 DB OP_ORAB, AM_IMMEDIATE         ; $CA
 DB OP_ADDB, AM_IMMEDIATE         ; $CB
 DB OP_INV, AM_INHERENT           ; $CC
 DB OP_INV, AM_INHERENT           ; $CD
 DB OP_LDX, AM_IMMEDIATEX         ; $CE
 DB OP_INV, AM_INHERENT           ; $CF

 DB OP_SUBB, AM_DIRECT            ; $D0
 DB OP_CMPB, AM_DIRECT            ; $D1
 DB OP_SBCB, AM_DIRECT            ; $D2
 DB OP_INV, AM_INHERENT           ; $D3
 DB OP_ANDB, AM_DIRECT            ; $D4
 DB OP_BITB, AM_DIRECT            ; $D5
 DB OP_LDAB, AM_DIRECT            ; $D6
 DB OP_STAB, AM_DIRECT            ; $D7
 DB OP_EORB, AM_DIRECT            ; $D8
 DB OP_ADCB, AM_DIRECT            ; $D9
 DB OP_ORAB, AM_DIRECT            ; $DA
 DB OP_ADDB, AM_DIRECT            ; $DB
 DB OP_INV, AM_INHERENT           ; $DC
 DB OP_INV, AM_INHERENT           ; $DD
 DB OP_LDX, AM_DIRECT             ; $DE
 DB OP_STX, AM_DIRECT             ; $DF

 DB OP_SUBB, AM_INDEXED           ; $E0
 DB OP_CMPB, AM_INDEXED           ; $E1
 DB OP_SBCB, AM_INDEXED           ; $E2
 DB OP_INV, AM_INHERENT           ; $E3
 DB OP_ANDB, AM_INDEXED           ; $E4
 DB OP_BITB, AM_INDEXED           ; $E5
 DB OP_LDAB, AM_INDEXED           ; $E6
 DB OP_STAB, AM_INDEXED           ; $E7
 DB OP_EORB, AM_INDEXED           ; $E8
 DB OP_ADCB, AM_INDEXED           ; $E9
 DB OP_ORAB, AM_INDEXED           ; $EA
 DB OP_ADDB, AM_INDEXED           ; $EB
 DB OP_INV, AM_INHERENT           ; $EC
 DB OP_INV, AM_INHERENT           ; $ED
 DB OP_LDX, AM_INDEXED            ; $EE
 DB OP_STX, AM_INDEXED            ; $EF

 DB OP_SUBB, AM_EXTENDED          ; $F0
 DB OP_CMPB, AM_EXTENDED          ; $F1
 DB OP_SBCB, AM_EXTENDED          ; $F2
 DB OP_INV, AM_INHERENT           ; $F3
 DB OP_ANDB, AM_EXTENDED          ; $F4
 DB OP_BITB, AM_EXTENDED          ; $F5
 DB OP_LDAB, AM_EXTENDED          ; $F6
 DB OP_STAB, AM_EXTENDED          ; $F7
 DB OP_EORB, AM_EXTENDED          ; $F8
 DB OP_ADCB, AM_EXTENDED          ; $F9
 DB OP_ORAB, AM_EXTENDED          ; $FA
 DB OP_INV, AM_INHERENT           ; $FB
 DB OP_INV, AM_INHERENT           ; $FC
 DB OP_ADDB, AM_EXTENDED          ; $FB
 DB OP_LDX, AM_EXTENDED           ; $FE
 DB OP_STX, AM_EXTENDED           ; $FF

; *** Strings ***

ContinueString ASC "  <SPACE> to continue, <ESC> to stop\0"
WelcomeString ASC "Disasm version 0.0 by Jeff Tranter\r\n\0"
