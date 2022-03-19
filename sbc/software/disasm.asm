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
 OP_ANDA = $00
 OP_ANDB = $06
 OP_ASL  = $00
 OP_ASLA = $07
 OP_ASR  = $08
 OP_ASRA = $09
 OP_ASRB = $0A
 OP_BCC  = $0B
 OP_BCS  = $0C
 OP_BEQ  = $0D
 OP_BGE  = $0E
 OP_BGT  = $0F
 OP_BHI  = $10
 OP_BITA = $11
 OP_BITB = $12
 OP_BLE  = $13
 OP_BLS  = $14
 OP_BLT  = $15
 OP_BMI  = $16
 OP_BNE  = $17
 OP_BPL  = $18
 OP_BRA  = $19
 OP_BSR  = $1A
 OP_BVC  = $1B
 OP_BVS  = $1C
 OP_CBA  = $1D
 OP_CLC  = $1E
 OP_CLI  = $1D
 OP_CLR  = $20
 OP_CLRA = $21
 OP_CLRB = $22
 OP_CLV  = $23
 OP_CMPA = $24
 OP_CMPB = $25
 OP_COM  = $26
 OP_COMA = $27
 OP_COMB = $28
 OP_CPX  = $29
 OP_DAA  = $2A
 OP_DEC  = $2B
 OP_DECA = $2C
 OP_DECB = $2D
 OP_DES  = $2E
 OP_DEX  = $2F
 OP_EORA = $30
 OP_EORB = $31
 OP_INC  = $32
 OP_INCA = $33
 OP_INCB = $34
 OP_INS  = $35
 OP_INX  = $36
 OP_JMP  = $37
 OP_JSR  = $38
 OP_LDAA = $39
 OP_LDAB = $3A
 OP_LDS  = $3B
 OP_LDX  = $3C
 OP_LSR  = $3D
 OP_LSRA = $3E
 OP_LSRB = $3F
 OP_NEG  = $40
 OP_NEGA = $41
 OP_NEGB = $42
 OP_NOP  = $43
 OP_ORAA = $44
 OP_ORAB = $45
 OP_PSHA = $46
 OP_PSHB = $47
 OP_PULA = $48
 OP_PULB = $49
 OP_ROL  = $4A
 OP_ROLA = $4B
 OP_ROLB = $4C
 OP_ROR  = $4D
 OP_RORA = $4E
 OP_RORB = $4F
 OP_RTI  = $50
 OP_RTS  = $51
 OP_SBA  = $52
 OP_SBCA = $53
 OP_SBCB = $54
 OP_SEC  = $55
 OP_SEI  = $56
 OP_SEV  = $57
 OP_STAA = $58
 OP_STAB = $59
 OP_STS  = $5A
 OP_STX  = $5B
 OP_SUBA = $5C
 OP_SUBB = $5D
 OP_SWI  = $5E
 OP_TAB  = $5F
 OP_TAP  = $60
 OP_TBA  = $61
 OP_TPA  = $62
 OP_TST  = $63
 OP_TSTA = $64
 OP_TSTB = $65
 OP_TSX  = $66
 OP_WAI  = $67

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

; Table of instruction strings. 3 bytes per table entry
 .export MNEMONICS
MNEMONICS
 DB "???" ; $00
 DB "ADC" ; $01
 DB "AND" ; $02
 DB "ASL" ; $03
 DB "BCC" ; $04
 DB "BCS" ; $05
 DB "BEQ" ; $06
 DB "BIT" ; $07
 DB "BMI" ; $08
 DB "BNE" ; $09
 DB "BPL" ; $0A
 DB "BRK" ; $0B
 DB "BVC" ; $0C
 DB "BVS" ; $0D
 DB "CLC" ; $0E
 DB "CLD" ; $0F
 DB "CLI" ; $10
 DB "CLV" ; $11
 DB "CMP" ; $12
 DB "CPX" ; $13
 DB "CPY" ; $14
 DB "DEC" ; $15
 DB "DEX" ; $16
 DB "DEY" ; $17
 DB "EOR" ; $18
 DB "INC" ; $19
 DB "INX" ; $1A
 DB "INY" ; $1B
 DB "JMP" ; $1C
 DB "JSR" ; $1D
 DB "LDA" ; $1E
 DB "LDX" ; $1F
 DB "LDY" ; $20
 DB "LSR" ; $21
 DB "NOP" ; $22
 DB "ORA" ; $23
 DB "PHA" ; $24
 DB "PHP" ; $25
 DB "PLA" ; $26
 DB "PLP" ; $27
 DB "ROL" ; $28
 DB "ROR" ; $29
 DB "RTI" ; $2A
 DB "RTS" ; $2B
 DB "SBC" ; $2C
 DB "SEC" ; $2D
 DB "SED" ; $2E
 DB "SEI" ; $2F
 DB "STA" ; $30
 DB "STX" ; $31
 DB "STY" ; $32
 DB "TAX" ; $33
 DB "TAY" ; $34
 DB "TSX" ; $35
 DB "TXA" ; $36
 DB "TXS" ; $37
 DB "TYA" ; $38
 DB "BBR" ; $39 [65C02 only]
 DB "BBS" ; $3A [65C02 only]
 DB "BRA" ; $3B [65C02 only]
 DB "PHX" ; $3C [65C02 only]
 DB "PHY" ; $3D [65C02 only]
 DB "PLX" ; $3E [65C02 only]
 DB "PLY" ; $3F [65C02 only]
 DB "RMB" ; $40 [65C02 only]
 DB "SMB" ; $41 [65C02 only]
 DB "STZ" ; $42 [65C02 only]
 DB "TRB" ; $43 [65C02 only]
 DB "TSB" ; $44 [65C02 only]
 DB "STP" ; $45 [WDC 65C02 only]
 DB "WAI" ; $46 [WDC 65C02 only]

; Lengths of instructions given an addressing mode. Matches values of AM_*
LENGTHS 
DB 1, 1, 2, 3, 2, 2, 3, 2

; Opcodes. Listed in order. Defines the mnemonic and addressing mode.
; 2 bytes per table entry
 .export OPCODES1
OPCODES1
 DB OP_BRK, AM_IMPLICIT           ; $00
 DB OP_ORA, AM_INDEXED_INDIRECT   ; $01
 DB OP_INV, AM_INVALID            ; $02
 DB OP_INV, AM_INVALID            ; $03
 DB OP_TSB, AM_ZEROPAGE           ; $04 [65C02 only]
 DB OP_ORA, AM_ZEROPAGE           ; $05
 DB OP_ASL, AM_ZEROPAGE           ; $06
 DB OP_RMB, AM_ZEROPAGE           ; $07 [65C02 only]
 DB OP_PHP, AM_IMPLICIT           ; $08
 DB OP_ORA, AM_IMMEDIATE          ; $09
 DB OP_ASL, AM_ACCUMULATOR        ; $0A
 DB OP_INV, AM_INVALID            ; $0B
 DB OP_TSB, AM_ABSOLUTE           ; $0C [65C02 only]
 DB OP_ORA, AM_ABSOLUTE           ; $0D
 DB OP_ASL, AM_ABSOLUTE           ; $0E
 DB OP_BBR, AM_ABSOLUTE           ; $0F [65C02 only]

 DB OP_BPL, AM_RELATIVE           ; $10
 DB OP_ORA, AM_INDIRECT_INDEXED   ; $11
 DB OP_ORA, AM_INDIRECT_ZEROPAGE  ; $12 [65C02 only]
 DB OP_INV, AM_INVALID            ; $13
 DB OP_TRB, AM_ZEROPAGE           ; $14 [65C02 only]
 DB OP_ORA, AM_ZEROPAGE_X         ; $15
 DB OP_ASL, AM_ZEROPAGE_X         ; $16
 DB OP_RMB, AM_ZEROPAGE           ; $17 [65C02 only]
 DB OP_CLC, AM_IMPLICIT           ; $18
 DB OP_ORA, AM_ABSOLUTE_Y         ; $19
 DB OP_INC, AM_ACCUMULATOR        ; $1A [65C02 only]
 DB OP_INV, AM_INVALID            ; $1B
 DB OP_TRB, AM_ABSOLUTE           ; $1C [65C02 only]
 DB OP_ORA, AM_ABSOLUTE_X         ; $1D
 DB OP_ASL, AM_ABSOLUTE_X         ; $1E
 DB OP_BBR, AM_ABSOLUTE           ; $1F [65C02 only]

 DB OP_JSR, AM_ABSOLUTE           ; $20
 DB OP_AND, AM_INDEXED_INDIRECT   ; $21
 DB OP_INV, AM_INVALID            ; $22
 DB OP_INV, AM_INVALID            ; $23
 DB OP_BIT, AM_ZEROPAGE           ; $24
 DB OP_AND, AM_ZEROPAGE           ; $25
 DB OP_ROL, AM_ZEROPAGE           ; $26
 DB OP_RMB, AM_ZEROPAGE           ; $27 [65C02 only]
 DB OP_PLP, AM_IMPLICIT           ; $28
 DB OP_AND, AM_IMMEDIATE          ; $29
 DB OP_ROL, AM_ACCUMULATOR        ; $2A
 DB OP_INV, AM_INVALID            ; $2B
 DB OP_BIT, AM_ABSOLUTE           ; $2C
 DB OP_AND, AM_ABSOLUTE           ; $2D
 DB OP_ROL, AM_ABSOLUTE           ; $2E
 DB OP_BBR, AM_ABSOLUTE           ; $2F [65C02 only]

 DB OP_BMI, AM_RELATIVE           ; $30
 DB OP_AND, AM_INDIRECT_INDEXED   ; $31 [65C02 only]
 DB OP_AND, AM_INDIRECT_ZEROPAGE  ; $32 [65C02 only]
 DB OP_INV, AM_INVALID            ; $33
 DB OP_BIT, AM_ZEROPAGE_X         ; $34 [65C02 only]
 DB OP_AND, AM_ZEROPAGE_X         ; $35
 DB OP_ROL, AM_ZEROPAGE_X         ; $36
 DB OP_RMB, AM_ZEROPAGE           ; $37 [65C02 only]
 DB OP_SEC, AM_IMPLICIT           ; $38
 DB OP_AND, AM_ABSOLUTE_Y         ; $39
 DB OP_DEC, AM_ACCUMULATOR        ; $3A [65C02 only]
 DB OP_INV, AM_INVALID            ; $3B
 DB OP_BIT, AM_ABSOLUTE_X         ; $3C [65C02 only]
 DB OP_AND, AM_ABSOLUTE_X         ; $3D
 DB OP_ROL, AM_ABSOLUTE_X         ; $3E
 DB OP_BBR, AM_ABSOLUTE           ; $3F [65C02 only]

 DB OP_RTI, AM_IMPLICIT           ; $40
 DB OP_EOR, AM_INDEXED_INDIRECT   ; $41
 DB OP_INV, AM_INVALID            ; $42
 DB OP_INV, AM_INVALID            ; $43
 DB OP_INV, AM_INVALID            ; $44
 DB OP_EOR, AM_ZEROPAGE           ; $45
 DB OP_LSR, AM_ZEROPAGE           ; $46
 DB OP_RMB, AM_ZEROPAGE           ; $47 [65C02 only]
 DB OP_PHA, AM_IMPLICIT           ; $48
 DB OP_EOR, AM_IMMEDIATE          ; $49
 DB OP_LSR, AM_ACCUMULATOR        ; $4A
 DB OP_INV, AM_INVALID            ; $4B
 DB OP_JMP, AM_ABSOLUTE           ; $4C
 DB OP_EOR, AM_ABSOLUTE           ; $4D
 DB OP_LSR, AM_ABSOLUTE           ; $4E
 DB OP_BBR, AM_ABSOLUTE           ; $4F [65C02 only]

 DB OP_BVC, AM_RELATIVE           ; $50
 DB OP_EOR, AM_INDIRECT_INDEXED   ; $51
 DB OP_EOR, AM_INDIRECT_ZEROPAGE  ; $52 [65C02 only]
 DB OP_INV, AM_INVALID            ; $53
 DB OP_INV, AM_INVALID            ; $54
 DB OP_EOR, AM_ZEROPAGE_X         ; $55
 DB OP_LSR, AM_ZEROPAGE_X         ; $56
 DB OP_RMB, AM_ZEROPAGE           ; $57 [65C02 only]
 DB OP_CLI, AM_IMPLICIT           ; $58
 DB OP_EOR, AM_ABSOLUTE_Y         ; $59
 DB OP_PHY, AM_IMPLICIT           ; $5A [65C02 only]
 DB OP_INV, AM_INVALID            ; $5B
 DB OP_INV, AM_INVALID            ; $5C
 DB OP_EOR, AM_ABSOLUTE_X         ; $5D
 DB OP_LSR, AM_ABSOLUTE_X         ; $5E
 DB OP_BBR, AM_ABSOLUTE           ; $5F [65C02 only]

 DB OP_RTS, AM_IMPLICIT           ; $60
 DB OP_ADC, AM_INDEXED_INDIRECT   ; $61
 DB OP_INV, AM_INVALID            ; $62
 DB OP_INV, AM_INVALID            ; $63
 DB OP_STZ, AM_ZEROPAGE           ; $64 [65C02 only]
 DB OP_ADC, AM_ZEROPAGE           ; $65
 DB OP_ROR, AM_ZEROPAGE           ; $66
 DB OP_RMB, AM_ZEROPAGE           ; $67 [65C02 only]
 DB OP_PLA, AM_IMPLICIT           ; $68
 DB OP_ADC, AM_IMMEDIATE          ; $69
 DB OP_ROR, AM_ACCUMULATOR        ; $6A
 DB OP_INV, AM_INVALID            ; $6B
 DB OP_JMP, AM_INDIRECT           ; $6C
 DB OP_ADC, AM_ABSOLUTE           ; $6D
 DB OP_ROR, AM_ABSOLUTE           ; $6E
 DB OP_BBR, AM_ABSOLUTE           ; $6F [65C02 only]

 DB OP_BVS, AM_RELATIVE           ; $70
 DB OP_ADC, AM_INDIRECT_INDEXED   ; $71
 DB OP_ADC, AM_INDIRECT_ZEROPAGE  ; $72 [65C02 only]
 DB OP_INV, AM_INVALID            ; $73
 DB OP_STZ, AM_ZEROPAGE_X         ; $74 [65C02 only]
 DB OP_ADC, AM_ZEROPAGE_X         ; $75
 DB OP_ROR, AM_ZEROPAGE_X         ; $76
 DB OP_RMB, AM_ZEROPAGE           ; $77 [65C02 only]
 DB OP_SEI, AM_IMPLICIT           ; $78
 DB OP_ADC, AM_ABSOLUTE_Y         ; $79
 DB OP_PLY, AM_IMPLICIT           ; $7A [65C02 only]
 DB OP_INV, AM_INVALID            ; $7B
 DB OP_JMP, AM_ABSOLUTE_INDEXED_INDIRECT ; $7C [65C02 only]
 DB OP_ADC, AM_ABSOLUTE_X         ; $7D
 DB OP_ROR, AM_ABSOLUTE_X         ; $7E
 DB OP_BBR, AM_ABSOLUTE           ; $7F [65C02 only]
 .export OPCODES2
OPCODES2
 DB OP_BRA, AM_RELATIVE           ; $80 [65C02 only]
 DB OP_STA, AM_INDEXED_INDIRECT   ; $81
 DB OP_INV, AM_INVALID            ; $82
 DB OP_INV, AM_INVALID            ; $83
 DB OP_STY, AM_ZEROPAGE           ; $84
 DB OP_STA, AM_ZEROPAGE           ; $85
 DB OP_STX, AM_ZEROPAGE           ; $86
 DB OP_SMB, AM_ZEROPAGE           ; $87 [65C02 only]
 DB OP_DEY, AM_IMPLICIT           ; $88
 DB OP_BIT, AM_IMMEDIATE          ; $89 [65C02 only]
 DB OP_TXA, AM_IMPLICIT           ; $8A
 DB OP_INV, AM_INVALID            ; $8B
 DB OP_STY, AM_ABSOLUTE           ; $8C
 DB OP_STA, AM_ABSOLUTE           ; $8D
 DB OP_STX, AM_ABSOLUTE           ; $8E
 DB OP_BBS, AM_ABSOLUTE           ; $8F [65C02 only]

 DB OP_BCC, AM_RELATIVE           ; $90
 DB OP_STA, AM_INDIRECT_INDEXED   ; $91
 DB OP_STA, AM_INDIRECT_ZEROPAGE  ; $92 [65C02 only]
 DB OP_INV, AM_INVALID            ; $93
 DB OP_STY, AM_ZEROPAGE_X         ; $94
 DB OP_STA, AM_ZEROPAGE_X         ; $95
 DB OP_STX, AM_ZEROPAGE_Y         ; $96
 DB OP_SMB, AM_ZEROPAGE           ; $97 [65C02 only]
 DB OP_TYA, AM_IMPLICIT           ; $98
 DB OP_STA, AM_ABSOLUTE_Y         ; $99
 DB OP_TXS, AM_IMPLICIT           ; $9A
 DB OP_INV, AM_INVALID            ; $9B
 DB OP_STZ, AM_ABSOLUTE           ; $9C [65C02 only]
 DB OP_STA, AM_ABSOLUTE_X         ; $9D
 DB OP_STZ, AM_ABSOLUTE_X         ; $9E [65C02 only]
 DB OP_BBS, AM_ABSOLUTE           ; $9F [65C02 only]

 DB OP_LDY, AM_IMMEDIATE          ; $A0
 DB OP_LDA, AM_INDEXED_INDIRECT   ; $A1
 DB OP_LDX, AM_IMMEDIATE          ; $A2
 DB OP_INV, AM_INVALID            ; $A3
 DB OP_LDY, AM_ZEROPAGE           ; $A4
 DB OP_LDA, AM_ZEROPAGE           ; $A5
 DB OP_LDX, AM_ZEROPAGE           ; $A6
 DB OP_SMB, AM_ZEROPAGE           ; $A7 [65C02 only]
 DB OP_TAY, AM_IMPLICIT           ; $A8
 DB OP_LDA, AM_IMMEDIATE          ; $A9
 DB OP_TAX, AM_IMPLICIT           ; $AA
 DB OP_INV, AM_INVALID            ; $AB
 DB OP_LDY, AM_ABSOLUTE           ; $AC
 DB OP_LDA, AM_ABSOLUTE           ; $AD
 DB OP_LDX, AM_ABSOLUTE           ; $AE
 DB OP_BBS, AM_ABSOLUTE           ; $AF [65C02 only]

 DB OP_BCS, AM_RELATIVE           ; $B0
 DB OP_LDA, AM_INDIRECT_INDEXED   ; $B1
 DB OP_LDA, AM_INDIRECT_ZEROPAGE  ; $B2 [65C02 only]
 DB OP_INV, AM_INVALID            ; $B3
 DB OP_LDY, AM_ZEROPAGE_X         ; $B4
 DB OP_LDA, AM_ZEROPAGE_X         ; $B5
 DB OP_LDX, AM_ZEROPAGE_Y         ; $B6
 DB OP_SMB, AM_ZEROPAGE           ; $B7 [65C02 only]
 DB OP_CLV, AM_IMPLICIT           ; $B8
 DB OP_LDA, AM_ABSOLUTE_Y         ; $B9
 DB OP_TSX, AM_IMPLICIT           ; $BA
 DB OP_INV, AM_INVALID            ; $BB
 DB OP_LDY, AM_ABSOLUTE_X         ; $BC
 DB OP_LDA, AM_ABSOLUTE_X         ; $BD
 DB OP_LDX, AM_ABSOLUTE_Y         ; $BE
 DB OP_BBS, AM_ABSOLUTE           ; $BF [65C02 only]

 DB OP_CPY, AM_IMMEDIATE          ; $C0
 DB OP_CMP, AM_INDEXED_INDIRECT   ; $C1
 DB OP_INV, AM_INVALID            ; $C2
 DB OP_INV, AM_INVALID            ; $C3
 DB OP_CPY, AM_ZEROPAGE           ; $C4
 DB OP_CMP, AM_ZEROPAGE           ; $C5
 DB OP_DEC, AM_ZEROPAGE           ; $C6
 DB OP_SMB, AM_ZEROPAGE           ; $C7 [65C02 only]
 DB OP_INY, AM_IMPLICIT           ; $C8
 DB OP_CMP, AM_IMMEDIATE          ; $C9
 DB OP_DEX, AM_IMPLICIT           ; $CA
 DB OP_WAI, AM_IMPLICIT           ; $CB [WDC 65C02 only]
 DB OP_CPY, AM_ABSOLUTE           ; $CC
 DB OP_CMP, AM_ABSOLUTE           ; $CD
 DB OP_DEC, AM_ABSOLUTE           ; $CE
 DB OP_BBS, AM_ABSOLUTE           ; $CF [65C02 only]

 DB OP_BNE, AM_RELATIVE           ; $D0
 DB OP_CMP, AM_INDIRECT_INDEXED   ; $D1
 DB OP_CMP, AM_INDIRECT_ZEROPAGE  ; $D2 [65C02 only]
 DB OP_INV, AM_INVALID            ; $D3
 DB OP_INV, AM_INVALID            ; $D4
 DB OP_CMP, AM_ZEROPAGE_X         ; $D5
 DB OP_DEC, AM_ZEROPAGE_X         ; $D6
 DB OP_SMB, AM_ZEROPAGE           ; $D7 [65C02 only]
 DB OP_CLD, AM_IMPLICIT           ; $D8
 DB OP_CMP, AM_ABSOLUTE_Y         ; $D9
 DB OP_PHX, AM_IMPLICIT           ; $DA [65C02 only]
 DB OP_STP, AM_IMPLICIT           ; $DB [WDC 65C02 only]
 DB OP_INV, AM_INVALID            ; $DC
 DB OP_CMP, AM_ABSOLUTE_X         ; $DD
 DB OP_DEC, AM_ABSOLUTE_X         ; $DE
 DB OP_BBS, AM_ABSOLUTE           ; $DF [65C02 only]

 DB OP_CPX, AM_IMMEDIATE          ; $E0
 DB OP_SBC, AM_INDEXED_INDIRECT   ; $E1
 DB OP_INV, AM_INVALID            ; $E2
 DB OP_INV, AM_INVALID            ; $E3
 DB OP_CPX, AM_ZEROPAGE           ; $E4
 DB OP_SBC, AM_ZEROPAGE           ; $E5
 DB OP_INC, AM_ZEROPAGE           ; $E6
 DB OP_SMB, AM_ZEROPAGE           ; $E7 [65C02 only]
 DB OP_INX, AM_IMPLICIT           ; $E8
 DB OP_SBC, AM_IMMEDIATE          ; $E9
 DB OP_NOP, AM_IMPLICIT           ; $EA
 DB OP_INV, AM_INVALID            ; $EB
 DB OP_CPX, AM_ABSOLUTE           ; $EC
 DB OP_SBC, AM_ABSOLUTE           ; $ED
 DB OP_INC, AM_ABSOLUTE           ; $EE
 DB OP_BBS, AM_ABSOLUTE           ; $EF [65C02 only]

 DB OP_BEQ, AM_RELATIVE           ; $F0
 DB OP_SBC, AM_INDIRECT_INDEXED   ; $F1
 DB OP_SBC, AM_INDIRECT_ZEROPAGE  ; $F2 [65C02 only]
 DB OP_INV, AM_INVALID            ; $F3
 DB OP_INV, AM_INVALID            ; $F4
 DB OP_SBC, AM_ZEROPAGE_X         ; $F5
 DB OP_INC, AM_ZEROPAGE_X         ; $F6
 DB OP_SMB, AM_ZEROPAGE           ; $F7 [65C02 only]
 DB OP_SED, AM_IMPLICIT           ; $F8
 DB OP_SBC, AM_ABSOLUTE_Y         ; $F9
 DB OP_PLX, AM_IMPLICIT           ; $FA [65C02 only]
 DB OP_INV, AM_INVALID            ; $FB
 DB OP_INV, AM_INVALID            ; $FC
 DB OP_SBC, AM_ABSOLUTE_X         ; $FD
 DB OP_INC, AM_ABSOLUTE_X         ; $FE
 DB OP_BBS, AM_ABSOLUTE           ; $FF [65C02 only]

; *** Strings ***

ContinueString  ASC "  <SPACE> TO CONTINUE, <ESC> TO STOP\0"
WelcomeString ASC "DISASM VERSION 0.0 by JEFF TRANTER\0"
