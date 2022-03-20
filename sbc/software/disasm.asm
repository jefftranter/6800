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
; Revision History
; Version Date         Comments
; 0.0     16-Mar-2022  First version started, based on 6502 version

        CPU    6800
        OUTPUT  HEX             ; For Intel hex output
;       OUTPUT  SCODE           ; For Motorola S record (RUN) output
        CODE

; *** ASSEMBLY TIME OPTIONS ***

; Uncomment this if you want the output to include source code only
; and not the data bytes in memory. This allows the output to be fed
; back to an assembler.
; SOURCEONLY = 1

; Start address.
*     = $1000

; *** CONSTANTS ***

; Characters
  CR  = $0D ; Carriage Return
  SP  = $20 ; Space
  ESC = $1B ; Escape

; External Routines
  ECHO     = $FFEF ; Woz monitor ECHO routine
  PRBYTE   = $FFDC ; Woz monitor print byte as two hex chars
  PRHEX    = $FFE5 ; Woz monitor print nybble as hex digit

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
 OP_WAI  = $6A

; Addressing Modes. OPCODES1/OPCODES2 tables list these for each instruction. LENGTHS lists the instruction length for each addressing mode.
 AM_INVALID = 0                    ; example:
 AM_INHERENT = 1                   ; RTS
 AM_IMMEDIATE = 2                  ; LDAA #$12
 AM_IMMEDIATEX = 3                 ; LDX #$1234
 AM_DIRECT = 4                     ; LDAA $12
 AM_INDEXED = 5                    ; LDAA $12,X
 AM_EXTENDED = 6                   ; LDAA $1234
 AM_RELATIVE = 7                   ; BNE $FD

; *** VARIABLES ***

; Page zero variables
 T1     = $35     ; temp variable 1
 T2     = $36     ; temp variable 2
 ADDR   = $37     ; instruction address, 2 bytes (low/high)
 OPCODE = $39     ; instruction opcode
 OP     = $3A     ; instruction type OP_*
 AM     = $41     ; addressing mode AM_*
 LEN    = $42     ; instruction length
 REL    = $43     ; relative addressing branch offset (2 bytes)
 DEST   = $45     ; relative address destination address (2 bytes)

; *** CODE ***

; Main program disassembles starting from itself. Prompts user to hit
; key to continue after each screen.
START JSR PRINTCR

  LDX #WelcomeString
  JSR PrintString
  JSR PRINTCR
  LDAA #START
  STAA ADDR
  LDAA #START
  STAA ADDR+1
OUTER JSR PRINTCR
  LDAA #23
LOOP PSHA
  JSR DISASM
  PULA
  SEC
  SBCA #1
  BNE LOOP
  LDX #ContinueString
  JSR PrintString
SpaceOrEscape JSR GetKey
  CMPA #' '
  BEQ OUTER
  CMPA #ESC
  BNE SpaceOrEscape
  RTS

; Disassemble instruction at address ADDR (low) / ADDR+1 (high). On
; return ADDR/ADDR+1 points to next instruction so it can be called
; again.
DISASM LDX #0
  LDAA (ADDR,X)          ; get instruction op code
  STAA OPCODE
  BMI UPPER              ; if bit 7 set, in upper half of table
  ASLA                   ; double it since table is two bytes per entry
  TAX
  LDAA OPCODES1,X        ; get the instruction type (e.g. OP_LDA)
  STAA OP                ; store it
  INX
  LDAA OPCODES1,X        ; get addressing mode
  STAA AM                ; store it
  JMP AROUND
UPPER ASLA                 ; double it since table is two bytes per entry
  TAX
  LDAA OPCODES2,X        ; get the instruction type (e.g. OP_LDA)
  STAA OP                ; store it
  INX
  LDAA OPCODES2,X        ; get addressing mode
  STAA AM                ; store it
AROUND
  TAX                   ; put addressing mode in X
  LDAA LENGTHS,X         ; get instruction length given addressing mode
  STAA LEN               ; store it
  LDX ADDR
;  .ifndef SOURCEONLY
  JSR PrintAddress      ; print address
  LDX #3
  JSR PrintSpaces       ; then three spaces
  LDAA OPCODE            ; get instruction op code
  JSR PrintByte         ; display the opcode byte
  JSR PrintSpace
  LDAA LEN               ; how many bytes in the instruction?
  CMPA #3
  BEQ THREE
  CMPA #2
  BEQ TWO
  LDX #5
  JSR PrintSpaces
  JMP ONE
TWO
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte
  JSR PrintByte         ; display it
  LDX #3
  JSR PrintSpaces
  JMP ONE
THREE
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte
  JSR PrintByte         ; display it
  JSR PrintSpace
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte
  JSR PrintByte         ; display it
ONE
;  .endif                ; .ifndef SOURCEONLY
  LDX #4
  JSR PrintSpaces
  LDAA OP                ; get the op code
  ASLA                   ; multiply by 2
  CLC
  ADCA OP                ; add one more to multiply by 3 since table is three bytes per entry
  TAX
  LDY #3
MNEM
  LDAA MNEMONICS,X       ; print three chars of mnemonic
  JSR PrintChar
  INX
  DEY
  BNE MNEM
; Display any operands based on addressing mode
  LDAA OP                ; is it RMB or SMB?
  CMPA #OP_RMB
  BEQ DOMB
  CMPA #OP_SMB
  BNE TRYBB
DOMB
  LDAA OPCODE            ; get the op code
  ANDA #$70              ; Upper 3 bits is the bit number
  LSRA                   
  LSRA
  LSRA
  LSRA
  JSR PRHEX
  LDX #2
  JSR PrintSpaces
  JSR PrintDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JMP DONEOPS
TRYBB
  LDAA OP                ; is it BBR or BBS?
  CMPA #OP_BBR
  BEQ DOBB
  CMPA #OP_BBS
  BNE TRYIMP
DOBB                   ; handle special BBRn and BBSn instructions
  LDAA OPCODE            ; get the op code
  AND #$70              ; Upper 3 bits is the bit number
  LSRA                   
  LSRA
  LSRA
  LSRA
  JSR PRHEX
  LDX #2
  JSR PrintSpaces
  JSR PrintDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (address)
  JSR PrintByte         ; display it
  LDAA #','
  JSR PrintChar
  JSR PrintDollar
; Handle relative addressing
; Destination address is Current address + relative (sign extended so upper byte is $00 or $FF) + 3
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte (relative branch offset)
  STAA REL               ; save low byte of offset
  BMI @NEG              ; if negative, need to sign extend
  LDAA #0                ; high byte is zero
  BEQ @ADD
@NEG
  LDAA #$FF              ; negative offset, high byte if $FF
@ADD
  STAA REL+1             ; save offset high byte
  LDAA ADDR              ; take adresss
  CLC
  ADCA REL               ; add offset
  STAA DEST              ; and store
  LDAA ADDR+1            ; also high byte (including carry)
  ADCA REL+1
  STAA DEST+1
  LDAA DEST              ; now need to add 3 more to the address
  CLC
  ADCA #3
  STAA DEST
  LDAA DEST+1
  ADCA #0                ; add any carry
  STAA DEST+1
  JSR PrintByte         ; display high byte
  LDAA DEST
  JSR PrintByte         ; display low byte
  JMP DONEOPS
TRYIMP
  LDAA AM
  CMPA #AM_IMPLICIT
  BNE TRYINV
  JMP DONEOPS           ; no operands
TRYINV 
  CMPA #AM_INVALID
  BNE TRYACC
  JMP DONEOPS           ; no operands
TRYACC
  LDX #3
  JSR PrintSpaces
  CMPA #AM_ACCUMULATOR
  BNE TRYIMM
; .ifndef NOACCUMULATOR
  LDAA #'A'
  JSR PrintChar
; .endif                 ; .ifndef NOACCUMULATOR
  JMP DONEOPS
TRYIMM
  CMPA #AM_IMMEDIATE
  BNE TRYZP
  LDAA #'#'
  JSR PrintChar
  JSR PrintDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JMP DONEOPS
TRYZP
  CMPA #AM_ZEROPAGE
  BNE TRYZPX
  JSR PrintDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JMP DONEOPS
TRYZPX
  CMPA #AM_ZEROPAGE_X
  BNE TRYZPY
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (address)
  JSR PrintDollar
  JSR PrintByte         ; display it
  JSR PrintCommaX
  JMP DONEOPS       
TRYZPY
  CMPA #AM_ZEROPAGE_Y
  BNE TRYREL
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (address)
  JSR PrintByte         ; display it
  JSR PrintCommaY
  JMP DONEOPS       
TRYREL
  CMPA #AM_RELATIVE
  BNE TRYABS
  JSR PrintDollar
; Handle relative addressing
; Destination address is Current address + relative (sign extended so upper byte is $00 or $FF) + 2
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (relative branch offset)
  STAA REL               ; save low byte of offset
  BMI  SNEG              ; if negative, need to sign extend
  LDAA #0                ; high byte is zero
  BEQ SADD
SNEG
  LDAA #$FF              ; negative offset, high byte if $FF
SADD
  STAA REL+1             ; save offset high byte
  LDAA ADDR              ; take adresss
  CLC
  ADCA REL               ; add offset
  STAA DEST              ; and store
  LDAA ADDR+1            ; also high byte (including carry)
  ADCA REL+1
  STAA DEST+1
  LDAA DEST              ; now need to add 2 more to the address
  CLC
  ADCA #2
  STAA DEST
  LDAA DEST+1
  ADCA #0                ; add any carry
  STAA DEST+1
  JSR PrintByte         ; display high byte
  LDAA DEST
  JSR PrintByte         ; display low byte
  JMP DONEOPS
TRYABS
  CMPA #AM_ABSOLUTE
  BNE TRYABSX
  JSR PrintDollar
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte (high address)
  JSR PrintByte         ; display it
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JMP DONEOPS
TRYABSX
  CMPA #AM_ABSOLUTE_X
  BNE TRYABSY
  JSR PrintDollar
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte (high address)
  JSR PrintByte         ; display it
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintCommaX
  JMP DONEOPS
TRYABSY
  CMPA #AM_ABSOLUTE_Y
  BNE TRYIND
  JSR PrintDollar
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte (high address)
  JSR PrintByte         ; display it
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintCommaY
  JMP DONEOPS
TRYIND
  CMPA #AM_INDIRECT
  BNE TRYINDXIND
  JSR PrintLParenDollar
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte (high address)
  JSR PrintByte         ; display it
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintRParen
  JMP DONEOPS
TRYINDXIND
  CMPA #AM_INDEXED_INDIRECT
  BNE TRYINDINDX
  JSR PrintLParenDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintCommaX
  JSR PrintRParen
  JMP DONEOPS
TRYINDINDX
  CMPA #AM_INDIRECT_INDEXED
  BNE TRYINDZ
  JSR PrintLParenDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintRParen
  JSR PrintCommaY
  JMP DONEOPS
TRYINDZ
  CMPA #AM_INDIRECT_ZEROPAGE ; [65C02 only]
  BNE TRYABINDIND
  JSR PrintLParenDollar
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintRParen
  JMP DONEOPS
TRYABINDIND
  CMPA #AM_ABSOLUTE_INDEXED_INDIRECT ; [65C02 only]
  BNE DONEOPS
  JSR PrintLParenDollar
  LDY #2
  LDAA (ADDR),Y          ; get 2nd operand byte (high address)
  JSR PrintByte         ; display it
  LDY #1
  LDAA (ADDR),Y          ; get 1st operand byte (low address)
  JSR PrintByte         ; display it
  JSR PrintCommaX
  JSR PrintRParen
  JMP DONEOPS
DONEOPS
  JSR PRINTCR           ; print a final CR
  LDAA ADDR              ; update address to next instruction
  CLC
  ADCA LEN
  STAA ADDR
  LDAA ADDR+1
  ADCA #0                ; to add carry
  STAA ADDR+1
  RTS

;------------------------------------------------------------------------
; Utility functions

; Print a dollar sign
; Registers changed: None
PrintDollar PSHA
  LDAA #'$'
  JSR PrintChar
  PULA
  RTS

; Print ",X"
; Registers changed: None
PrintCommaX PSHA
  LDAA #','
  JSR PrintChar
  LDAA #'X'
  JSR PrintChar
  PULA
  RTS

; Print ",Y"
; Registers changed: None
PrintCommaY PSHA
  LDAA #','
  JSR PrintChar
  LDAA #'Y'
  JSR PrintChar
  PULA
  RTS

; Print "($"
; Registers changed: None
PrintLParenDollar PSHA
  LDAA #'('
  JSR PrintChar
  LDAA #'$'
  JSR PrintChar
  PULA
  RTS

; Print a right parenthesis
; Registers changed: None
PrintRParen PSHA
  LDAA #')'
  JSR PrintChar
  PULA
  RTS

; Print a carriage return
; Registers changed: None
PRINTCR PSHA
  LDAA #CR
  JSR PrintChar
  PULA
  RTS

; Print a space
; Registers changed: None
PrintSpace PSHA
  LDAA #SP
  JSR PrintChar
  PULA
  RTS

; Print number of spaces in X
; Registers changed: X
PrintSpaces PSHA
  LDAA #SP
@LOOP
  JSR ECHO
  DEX
  BNE @LOOP
  PULA
  RTS

; Output a character
; Calls Woz monitor ECHO routine
; Registers changed: none
PrintChar JSR ECHO
  RTS

; Get character from keyboard
; Returns in A
; Clears high bit to be valid ASCII
; Registers changed: A
GetKey LDAA $D011 ; Keyboard CR
  BPL GetKey
  LDAA $D010 ; Keyboard data
  AND #%01111111
  RTS

; Print 16-bit address in hex
; Pass byte in X (low) and Y (high)
; Registers changed: None
PrintAddress PSHA
  TYA
  JSR PRBYTE
  TXA
  JSR PRBYTE
  PULA
  RTS

; Print byte in hex
; Pass byte in A
; Registers changed: None
PrintByte JSR PRBYTE
  RTS

; Print a string
; Pass address of string in X (low) and Y (high).
; String must be terminated in a null.
; Cannot be longer than 256 characters.
; Registers changed: A, Y
;
PrintString STX T1
  STY T1+1
  LDY #0
@loop
  LDAA (T1),Y
  BEQ done
  JSR PrintChar
  INY
  BNE @loop       ; if doesn't branch, string is too long
done
  RTS

;  get opcode
;  get mnemonic, addressing mode, instruction length
;  display opcode string
;  display arguments based on addressing mode
;  increment instruction pointer based on instruction length
;  loop back

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
 ASC "WAI " ; $6A

; Lengths of instructions given an addressing mode. Matches values of AM_*
LENGTHS 
 DB 1, 1, 2, 3, 2, 2, 3, 2

; Opcodes. Listed in order. Defines the mnemonic and addressing mode.
; 2 bytes per table entry
OPCODES1
 DB OP_INV, AM_INVALID            ; $00
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

; *** Strings ***

ContinueString  ASC "  <SPACE> TO CONTINUE, <ESC> TO STOP\0"
WelcomeString ASC "DISASM VERSION 0.0 by JEFF TRANTER\0"
