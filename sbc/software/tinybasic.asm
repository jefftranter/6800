; ETA-3400 Tiny BASIC ROM.
;
; Generated by disassembling ROM image using the f9dasm program.
; Adapted to the crasm assembler. I have confirmed that it produces
; the same binary output as the Heathkit ROMs.
;
; Tiny BASIC was implemented as a (target dependent) virtual machine
; running a (portable) interpreted language. The disassembled source
; code here does not reflect this and is not particularly meaningful
; (e.g. many of the instructions are actually data). Apparently the
; original source for the 6800 version of Tiny BASIC has been
; lost. Some of the source has been reverse engineered using the
; source code for the 6502 version of Tiny BASIC.
;
; See:
;   http://www.ittybittycomputers.com/IttyBitty/TinyBasic
;   https://github.com/Arakula/f9dasm
;   https://github.com/colinbourassa/crasm
;
; Jeff Tranter <tranter@pobox.com>

; LOCATION   SIGNIFICANCE
; 0000-000F  Not used by Tiny BASIC.
; 0010-001F  Temporaries.
; 0020-0021  Lowest address of user program space.
; 0022-0023  Highest address of user program space.
; 0024-0025  Program end + stack reserve.
; 0026-0027  Top of GOSUB stack.
; 0028-002F  Interpreter parameters.
; 0030-007F  Input line buffer and Computation stack.
; 0080-0081  Random Number generator workspace.
; 0082-00B5  Variables A,B,...Z.
; 00B6-00C7  Interpreter temporaries.
; 0100-0FFF  Tiny BASIC user program space.

; EC00       Cold start entry point.
; EC03       Warm start entry point.
; EC06       Character input routine.
; EC09       Character output routine.
; EC0C       Break test.
; EC0F       Backspace code.
; EC10       Line cancel code.
; EC11       Pad character.
; EC12       Tape mode enable flag. (HEX 80 = enabled)
; EC13       Spare stack size.
; EC14       Subroutine (PEEK) to read one byte from RAM to B and A.
;            (address in X)
; EC18       Subroutine (POKE) to store A and B into RAM at address X.

        CPU     6800
        OUTPUT  HEX                 ; For Intel hex output
;       OUTPUT  SCODE               ; For Motorola S record (RUN) output

;****************************************************
;* Used Labels                                      *
;****************************************************

start_prgm EQU  $0020               ; start of BASIC text (0x900)
end_ram EQU     $0022               ; end of available RAM
end_prgm EQU    $0024               ; end of BASIC text
top_of_stack EQU $0026              ; top of return stack pointer location
basic_lineno EQU $0028              ; save for current line number to be executed
il_pc   EQU     $002A               ; program counter for IL code
basic_ptr EQU   $002C               ; pointer to currently executed BASIC byte
basicptr_save EQU $002E             ; temporary save for basic_ptr
expr_stack EQU  $0030               ; lowest byte of expr_stack (0x30)
rnd_seed EQU    $0080               ; used as seed value for RND function
                                    ; note this is actually top of predecrementing expr_stack
var_tbl EQU     $0099               ; variables (A-Z), 26 words
LS_end  EQU     $00B6               ; used to store addr of end of LS listing,
                                    ; start of list is in basic_ptr
BP_save EQU     $00B8               ; another temporary save for basic_ptr
X_save  EQU     $00BA               ; temporary save for X
IL_temp EQU     $00BC               ; temporary for various IL operations
lead_zero EQU   $00BE               ; flag for number output and negative sign in DV
column_cnt EQU  $00BF               ; counter for output columns (required for TAB in PRINT)
                                    ; if bit 7 is set, suppress output (XOFF)
run_mode EQU    $00C0               ; run mode
                                    ; = 0 direct mode
                                    ; <> 0 running program
expr_stack_low EQU $00C1            ; low addr byte of expr_stack (should be 0x30)
expr_stack_x EQU $00C2              ; high byte of expr_stack_top (==0x00, used with X register)
expr_stack_top EQU $00C3            ; low byte of expr_stack_top (used in 8 bit comparisons)
il_pc_save EQU  $00C4; save of IL program counter
                                       ; unused area in zero page (starting with 0xc6)
M0100   EQU     $0100
MAIN    EQU     $E400
OUTIS   EQU     $E618
M1CFF   EQU     $ECFF
SNDCHR  EQU     $E865
RCCHR   EQU     $E8E1
FTOP    EQU     $EA80
BREAK   EQU     $EB1F
L1B2D   EQU     $EB2D
L1B38   EQU     $EB38

;****************************************************
;* Program Code / Data Areas                        *
;****************************************************

        * =     $EC00

CV      JMP     COLD_S          ; Cold start vector
WV      JMP     WARM_S          ; Warm start vector
L1C06   JMP     RCCHR           ; Input routine address
L1C09   JMP     SNDCHR          ; Output routine address
L1C0C   JMP     BREAK           ; Begin break routine

;
; Some codes
;
BSC     DB      $08             ; Backspace code
LSC     DB      $15             ; Line cancel code
PCC     DB      $00             ; CRLF padding characters
                                ; low 7 bits are number of NUL/0xFF
                                ; bit7=1: send 0xFF, =0, send NUL
TMC     DB      $80             ; Tape mode control
M1C13   DB      $20             ; Spare Stack size.
;
; Code fragment for 'PEEK' and 'POKE'
;
; Get the byte pointed to by X into B:A.
;
PEEK    LDAA    0,X
        CLRB
M1C17   RTS

; Put the byte in A into cell pointed to by X
;
POKE    STAA    0,X
        RTS
;
; The following table contains the addresses for the ML handlers for the IL opcodes.
;
SRVT    DW      IL_BBR                ; ($40-$5F) Backward Branch Relative
        DW      IL_FBR                ; ($60-$7F) Forward Branch Relative
        DW      IL__BC                ; ($80-$9F) String Match Branch
        DW      IL__BV                ; ($A0-$BF) Branch if not Variable
        DW      IL__BN                ; ($C0-$DF) Branch if not a Number
        DW      IL__BE                ; ($E0-$FF) Branch if not End of line
        DW      IL__NO                ; ($08) No Operation
        DW      IL__LB                ; ($09) Push Literal Byte onto Stack
        DW      IL__LN                ; ($0A) Push Literal Number
        DW      IL__DS                ; ($0B) Duplicate Top two bytes on Stack
        DW      IL__SP                ; ($0C) Stack Pop
;       DW       IL__NO               ; ($0D) (Reserved)
        DW      L1CA9
;       DW       IL__NO               ; ($0E) (Reserved)
        DW      L1C77
;       DW       IL__NO               ; ($0F) (Reserved)
        DW      L1C80
;       DW       IL__SB               ; ($10) Save Basic Pointer
        DW      L1FAB
;       DW       IL__RB               ; ($11) Restore Basic Pointer
        DW      L1FB0
;       DW       IL__FV               ; ($12) Fetch Variable
        DW      L1F00
;       DW       IL__SV               ; ($13) Store Variable
        DW      L1F10
;       DW       IL__GS               ; ($14) Save GOSUB line
        DW      L1FCE
;       DW       IL__RS               ; ($15) Restore saved line
        DW      L1F99
;       DW       IL__GO               ; ($16) GOTO
        DW      L1F8E
;       DW       IL__NE               ; ($17) Negate
        DW      L1EC2
;       DW       IL__AD               ; ($18) Add
        DW      L1ECF
;       DW       IL__SU               ; ($19) Subtract
        DW      L1ECD
;       DW       IL__MP               ; ($1A) Multiply
        DW      L1EE5
;       DW       IL__DV               ; ($1B) Divide
        DW      L1E6B
;       DW       IL__CP               ; ($1C) Compare
        DW      L1F23
;       DW       IL__NX               ; ($1D) Next BASIC statement
        DW      L1F49
;       DW       IL__NO               ; ($1E) (Reserved)
        DW      IL__NO
;       DW       IL__LS               ; ($1F) List the program
        DW      L20D7
;       DW       IL__PN               ; ($20) Print Number
        DW      L2045
;       DW       IL__PQ               ; ($21) Print BASIC string
        DW      L20BA
;       DW       IL__PT               ; ($22) Print Tab
        DW      L20C2
;       DW       IL__NL               ; ($23) New Line
        DW      Z2128
;       DW       IL__PC               ; ($24) Print Literal String
        DW      Z20AD
;       DW       IL__NO               ; ($25) (Reserved)
        DW      L20CB
;       DW       IL__NO               ; ($26) (Reserved)
        DW      MAIN
;       DW       IL__GL               ; ($27) Get input Line
        DW      L2159
;       DW       ILRES1               ; ($28) (Seems to be reserved - No IL opcode calls this)
        DW      L1B2D
;       DW       ILRES2               ; ($29) (Seems to be reserved - No IL opcode calls this)
        DW      L1B38
;       DW       IL__IL               ; ($2A) Insert BASIC Line
        DW      L21B1
;       DW       IL__MT               ; ($2B) Mark the BASIC program space Empty
        DW      L1D12
;       DW       IL__XQ               ; ($2C) Execute
        DW      L1F7E
;       DW       WARM_S               ; ($2D) Stop (Warm Start)
        DW      WARM_S
;       DW       IL__US               ; ($2E) Machine Language Subroutine Call
        DW      L1CB9
;       DW       IL__RT               ; ($2F) IL subroutine return
        DW      L1FA6

;
; Begin Cold Start
;
; Load start of free ram ($0200) into locations $20 and $21
; and initialize the address for end of free ram ($22 & $23)
;

L1C77   BSR     IL__SP
        STAA    IL_temp
        STAB    IL_temp+1
        JMP     L1FD7
L1C80   JSR     L1FFC
        LDAA    IL_temp
        LDAB    IL_temp+1
        BRA     L1C8D
IL__DS  BSR     IL__SP
        BSR     L1C8D
L1C8D   LDX     expr_stack_x
        DEX
        STAB    0,X
        BRA     L1C96
L1C94   LDX     expr_stack_x
L1C96   DEX
        STAA    0,X
        STX     expr_stack_x
        PSHA
        LDAA    expr_stack_low
        CMPA    expr_stack_top
        PULA
        BCS     IL__NO
L1CA3   JMP     L1D5C
IL__SP  BSR     L1CA9
        TBA
L1CA9   LDAB    #1
L1CAB   ADDB    expr_stack_top
        CMPB    #$80
        BHI     L1CA3
        LDX     expr_stack_x
        INC     expr_stack_top
        LDAB    0,X
        RTS
L1CB9   BSR     L1CC0
        BSR     L1C94
        TBA
        BRA     L1C94
L1CC0   LDAA    #6
        TAB
        ADDA    expr_stack_top
        CMPA    #$80
        BHI     L1CA3
        LDX     expr_stack_x
        STAA    expr_stack_top
L1CCD   LDAA    $05,X
        PSHA
        DEX
        DECB
        BNE     L1CCD
        TPA
        PSHA
        RTI
IL__LB  BSR     L1CF5
        BRA     L1C94
IL__LN  BSR     L1CF5
        PSHA
        BSR     L1CF5
        TAB
        PULA
        BRA     L1C8D
L1CE4   ADDA    expr_stack_top
        STAA    IL_temp+1
        CLR     IL_temp
        BSR     L1CA9
        LDX     IL_temp
        LDAA    0,X
        STAB    0,X
        BRA     L1C94
L1CF5   LDX     il_pc
        LDAA    0,X
        INX
        STX     il_pc
IL__NO  TSTA
        RTS
M1CFE   DW      ILTBL
COLD_S  LDX     #M0100
        STX     start_prgm
        JSR     FTOP
        STX     end_ram
        JSR     OUTIS
        ASC     "HTB1\0"              ; For Heathkit Tiny basic 1
L1D12   LDAA    start_prgm
        LDAB    start_prgm+1
L1D16   ADDB    M1C13
        ADCA    #0
        STAA    end_prgm
        STAB    end_prgm+1
        LDX     start_prgm
        CLR     0,X
        CLR     $01,X
WARM_S  LDS     end_ram
L1D27   JSR     L212C
L1D2A   LDX     M1CFE
        STX     il_pc
        LDX     #rnd_seed
        STX     expr_stack_x
        LDX     #expr_stack
        STX     run_mode
L1D39   STS     top_of_stack
L1D3B   BSR     L1CF5
        BSR     L1D46
        BRA     L1D3B
        CPX     #var_tbl
        BRA     L1D39
L1D46   LDX     #M1C17
        STX     IL_temp
        CMPA    #$30
        BCC     L1DA5
        CMPA    #8
        BCS     L1CE4
        ASLA
        STAA    IL_temp+1
        LDX     IL_temp
        LDX     $17,X
        JMP     0,X
L1D5C   JSR     L212C
        LDAA    #$21
        STAA    expr_stack_low
        JSR     L1C09
        LDAA    #$80
        STAA    expr_stack_top
        LDAB    il_pc+1
        LDAA    il_pc
        SUBB    M1CFF
        SBCA    M1CFE
        JSR     Z2042
        LDAA    run_mode
        BEQ     L1D8A
        LDX     #M1D93
        STX     il_pc
        JSR     Z20AD
        LDAA    basic_lineno
        LDAB    basic_lineno+1
        JSR     Z2042
L1D8A   LDAA    #7
        JSR     L1C09
        LDS     top_of_stack
        BRA     L1D27
M1D93   BRA     L1DD5+1
        LSRB
        BRA     L1D16+2
IL_BBR  DEC     IL_temp
IL_FBR  TST     IL_temp
        BEQ     L1D5C
L1DA0   LDX     IL_temp
        STX     il_pc
        RTS
L1DA5   CMPA    #$40
        BCC     L1DCC
        PSHA
        JSR     L1CF5
        ADDA    M1CFF
        STAA    IL_temp+1
        PULA
        TAB
        ANDA    #7
        ADCA    M1CFE
        STAA    IL_temp
        ANDB    #8
        BNE     L1DA0
        LDX     il_pc
        STAA    il_pc
        LDAB    IL_temp+1
        STAB    il_pc+1
        STX     IL_temp
        JMP     L1FD7
L1DCC   TAB
        LSRA
        LSRA
        LSRA
        LSRA
        ANDA    #$0E
        STAA    IL_temp+1
L1DD5   LDX     IL_temp
        LDX     $17,X
        CLRA
        CMPB    #$60
        ANDB    #$1F
        BCC     L1DE2
        ORAB    #$E0
L1DE2   BEQ     L1DEA
        ADDB    il_pc+1
        STAB    IL_temp+1
        ADCA    il_pc
L1DEA   STAA    IL_temp
        JMP     0,X
IL__BC  LDX     basic_ptr
        STX     BP_save
L1DF2   BSR     L1E2A
        BSR     L1E20
        TAB
        JSR     L1CF5
        BPL     L1DFE
        ORAB    #$80
L1DFE   CBA
        BNE     L1E05
        TSTA
        BPL     L1DF2
        RTS
L1E05   LDX     BP_save
        STX     basic_ptr
L1E09   BRA     IL_FBR
IL__BE  BSR     L1E2A
        CMPA    #$0D
        BNE     L1E09
        RTS
IL__BV  BSR     L1E2A
        CMPA    #$5A
        BGT     L1E09
        CMPA    #$41
        BLT     L1E09
        ASLA
        JSR     L1C94
L1E20   LDX     basic_ptr
        LDAA    0,X
        INX
        STX     basic_ptr
        CMPA    #$0D
        RTS
L1E2A   BSR     L1E20
        CMPA    #$20
        BEQ     L1E2A
        DEX
        STX     basic_ptr
        CMPA    #$30
        CLC
        BLT     L1E3A
        CMPA    #$3A
L1E3A   RTS
IL__BN  BSR     L1E2A
        BCC     L1E09
        LDX     #0
        STX     IL_temp
L1E44   BSR     L1E20
        PSHA
        LDAA    IL_temp
        LDAB    IL_temp+1
        ASLB
        ROLA
        ASLB
        ROLA
        ADDB    IL_temp+1
        ADCA    IL_temp
        ASLB
        ROLA
        STAB    IL_temp+1
        PULB
        ANDB    #$0F
        ADDB    IL_temp+1
        ADCA    #0
        STAA    IL_temp
        STAB    IL_temp+1
        BSR     L1E2A
        BCS     L1E44
        LDAA    IL_temp
        JMP     L1C8D
L1E6B   BSR     L1EE0
        LDAA    $02,X
        ASRA
        ROLA
        SBCA    $02,X
        STAA    IL_temp
        STAA    IL_temp+1
        TAB
        ADDB    $03,X
        STAB    $03,X
        TAB
        ADCB    $02,X
        STAB    $02,X
        EORA    0,X
        STAA    lead_zero
        BPL     L1E89
        BSR     L1EC4
L1E89   LDAB    #$11
        LDAA    0,X
        ORAA    $01,X
        BNE     L1E94
        JMP     L1D5C
L1E94   LDAA    IL_temp+1
        SUBA    $01,X
        PSHA
        LDAA    IL_temp
        SBCA    0,X
        PSHA
        EORA    IL_temp
        BMI     L1EAB
        PULA
        STAA    IL_temp
        PULA
        STAA    IL_temp+1
        SEC
        BRA     L1EAE
L1EAB   PULA
        PULA
        CLC
L1EAE   ROL     $03,X
        ROL     $02,X
        ROL     IL_temp+1
        ROL     IL_temp
        DECB
        BNE     L1E94
        BSR     L1EDD
        TST     lead_zero
        BPL     L1ECC
L1EC2   LDX     expr_stack_x
L1EC4   NEG     $01,X
        BNE     L1ECA
        DEC     0,X
L1ECA   COM     0,X
L1ECC   RTS
L1ECD   BSR     L1EC2
L1ECF   BSR     L1EE0
        LDAB    $03,X
        ADDB    $01,X
        LDAA    $02,X
        ADCA    0,X
L1ED9   STAA    $02,X
        STAB    $03,X
L1EDD   JMP     L1CA9
L1EE0   LDAB    #4
L1EE2   JMP     L1CAB
L1EE5   BSR     L1EE0
        LDAA    #$10
        STAA    IL_temp
        CLRA
        CLRB
L1EED   ASLB
        ROLA
        ASL     $01,X
        ROL     0,X
        BCC     L1EF9
        ADDB    $03,X
        ADCA    $02,X
L1EF9   DEC     IL_temp
        BNE     L1EED
        BRA     L1ED9
L1F00   BSR     L1EDD
        STAB    IL_temp+1
        CLR     IL_temp
        LDX     IL_temp
        LDAA    0,X
        LDAB    $01,X
        JMP     L1C8D
L1F10   LDAB    #3
        BSR     L1EE2
        LDAB    $01,X
        CLR     $01,X
        LDAA    0,X
        LDX     $01,X
        STAA    0,X
        STAB    $01,X
L1F20   JMP     IL__SP
L1F23   BSR     L1F20
        PSHB
        LDAB    #3
        BSR     L1EE2
        INC     expr_stack_top
        INC     expr_stack_top
        PULB
        SUBB    $02,X
        SBCA    $01,X
        BGT     L1F42
        BLT     L1F3E
        TSTB
        BEQ     L1F40
        BRA     L1F42
L1F3E   ASR     0,X
L1F40   ASR     0,X
L1F42   ASR     0,X
        BCC     L1F61
        JMP     L1CF5
L1F49   LDAA    run_mode
        BEQ     L1F6A
L1F4D   JSR     L1E20
        BNE     L1F4D
        BSR     L1F71
        BEQ     L1F67
L1F56   BSR     L1F8A
        JSR     L1C0C
        BCS     L1F62
        LDX     il_pc_save
        STX     il_pc
L1F61   RTS
L1F62   LDX     M1CFE
        STX     il_pc
L1F67   JMP     L1D5C
L1F6A   LDS     top_of_stack
        STAA    column_cnt
        JMP     L1D2A
L1F71   JSR     L1E20
        STAA    basic_lineno
        JSR     L1E20
        STAA    basic_lineno+1
        LDX     basic_lineno
        RTS
L1F7E   LDX     start_prgm
        STX     basic_ptr
        BSR     L1F71
        BEQ     L1F67
        LDX     il_pc
        STX     il_pc_save
L1F8A   TPA
        STAA    run_mode
        RTS
L1F8E   JSR     Z201A
        BEQ     L1F56
L1F93   LDX     IL_temp
        STX     basic_lineno
        BRA     L1F67
L1F99   BSR     L1FFC
        TSX
        INC     $01,X
        INC     $01,X
        JSR     Z2025
        BNE     L1F93
        RTS
L1FA6   BSR     L1FFC
        STX     il_pc
        RTS
L1FAB   LDX     #basic_ptr
        BRA     L1FB3
L1FB0   LDX     #basicptr_save
L1FB3   LDAA    $01,X
        CMPA    #$80
        BCC     L1FC1
        LDAA    0,X
        BNE     L1FC1
        LDX     basic_ptr
        BRA     MDB
L1FC1   LDX     basic_ptr
        LDAA    basicptr_save
        STAA    basic_ptr
        LDAA    basicptr_save+1
        STAA    basic_ptr+1
MDB     STX     basicptr_save
        RTS
L1FCE   TSX
        INC     $01,X
        INC     $01,X
        LDX     basic_lineno
        STX     IL_temp
L1FD7   DES
        DES
        TSX
        LDAA    $02,X
        STAA    0,X
        LDAA    $03,X
        STAA    $01,X
        LDAA    IL_temp
        STAA    $02,X
        LDAA    IL_temp+1
        STAA    $03,X
        LDX     #end_prgm
        STS     IL_temp
        LDAA    $01,X
        SUBA    IL_temp+1
        LDAA    0,X
        SBCA    IL_temp
        BCS     Z2019
L1FF9   JMP     L1D5C
L1FFC   TSX
        INX
        INX
        INX
        CPX     end_ram
        BEQ     L1FF9
        LDX     $01,X
        STX     IL_temp
        TSX
        PSHB
        LDAB    #4
Z200C   LDAA    $03,X
        STAA    $05,X
        DEX
        DECB
        BNE     Z200C
        PULB
        INS
        INS
        LDX     IL_temp
Z2019   RTS
Z201A   JSR     IL__SP
        STAB    IL_temp+1
        STAA    IL_temp
        ORAA    IL_temp+1
        BEQ     L1FF9
Z2025   LDX     start_prgm
        STX     basic_ptr
Z2029   JSR     L1F71
        BEQ     Z203F
        LDAB    basic_lineno+1
        LDAA    basic_lineno
        SUBB    IL_temp+1
        SBCA    IL_temp
        BCC     Z203F
Z2038   JSR     L1E20
        BNE     Z2038
        BRA     Z2029
Z203F   CPX     IL_temp
        RTS
Z2042   JSR     L1C8D
L2045   LDX     expr_stack_x
        TST     0,X
        BPL     Z2052
        JSR     L1EC2
        LDAA    #$2D
        BSR     Z2098
Z2052   CLRA
        PSHA
        LDAB    #$0F
        LDAA    #$1A
        PSHA
        PSHB
        PSHA
        PSHB
        JSR     IL__SP
        TSX
Z2060   INC     0,X
        SUBB    #$10
        SBCA    #$27
        BCC     Z2060
Z2068   DEC     $01,X
        ADDB    #$E8
        ADCA    #3
        BCC     Z2068
Z2070   INC     $02,X
        SUBB    #$64
        SBCA    #0
        BCC     Z2070
Z2078   DEC     $03,X
        ADDB    #$0A
        BCC     Z2078
        CLR     lead_zero
Z2081   PULA
        TSTA
        BEQ     Z2089
        BSR     Z208A
        BRA     Z2081
Z2089   TBA
Z208A   CMPA    #$10
        BNE     Z2093
        TST     lead_zero
        BEQ     Z20AA
Z2093   INC     lead_zero
        ORAA    #$30
Z2098   INC     column_cnt
        BMI     Z20A7
        STX     X_save
        PSHB
        JSR     L1C09
        PULB
        LDX     X_save
        RTS
Z20A7   DEC     column_cnt
Z20AA   RTS
Z20AB   BSR     Z2098
Z20AD   JSR     L1CF5
        BPL     Z20AB
        BRA     Z2098
Z20B4   CMPA    #$22
        BEQ     Z20AA
        BSR     Z2098
L20BA   JSR     L1E20
        BNE     Z20B4
        JMP     L1D5C
L20C2   LDAB    column_cnt
        BMI     Z20AA
        ORAB    #$F8
        NEGB
        BRA     Z20CE
L20CB   JSR     IL__SP
Z20CE   DECB
        BLT     Z20AA
        LDAA    #$20
        BSR     Z2098
        BRA     Z20CE
L20D7   LDX     basic_ptr
        STX     BP_save
        LDX     start_prgm
        STX     basic_ptr
        LDX     end_prgm
        BSR     Z210F
        BEQ     Z20E7
        BSR     Z210F
Z20E7   LDAA    basic_ptr
        LDAB    basic_ptr+1
        SUBB    LS_end+1
        SBCA    LS_end
        BCC     Z2123
        JSR     L1F71
        BEQ     Z2123
        LDAA    basic_lineno
        LDAB    basic_lineno+1
        JSR     Z2042
        LDAA    #$20
Z20FF   BSR     Z214C
        JSR     L1C0C
        BCS     Z2123
        JSR     L1E20
        BNE     Z20FF
        BSR     Z2128
        BRA     Z20E7
Z210F   INX
        STX     LS_end
        LDX     expr_stack_x
        CPX     #rnd_seed
        BEQ     Z2122
        JSR     Z201A
Z211C   LDX     basic_ptr
        DEX
        DEX
        STX     basic_ptr
Z2122   RTS
Z2123   LDX     BP_save
        STX     basic_ptr
        RTS
Z2128   LDAA    column_cnt
        BMI     Z2122
L212C   LDAA    #$0D
        BSR     Z2149
        LDAB    PCC
        ASLB
        BEQ     Z213E
Z2136   PSHB
        BSR     Z2142
        PULB
        DECB
        DECB
        BNE     Z2136
Z213E   LDAA    #$0A
        BSR     Z214C
Z2142   CLRA
        TST     PCC
        BPL     Z2149
        COMA
Z2149   CLR     column_cnt
Z214C   JMP     Z2098
Z214F   LDAA    TMC
        BRA     Z2155
Z2154   CLRA
Z2155   STAA    column_cnt
        BRA     Z2163
L2159   LDX     #expr_stack
        STX     basic_ptr
        STX     IL_temp
        JSR     L1C8D
Z2163   EORA    rnd_seed
        STAA    rnd_seed
        JSR     L1C06
        ANDA    #$7F
        BEQ     Z2163
        CMPA    #$7F
        BEQ     Z2163
        CMPA    #$0A
        BEQ     Z214F
        CMPA    #$13
        BEQ     Z2154
        LDX     IL_temp
        CMPA    LSC
        BEQ     Z218B
        CMPA    BSC
        BNE     Z2192
        CPX     #expr_stack
        BNE     Z21A0
Z218B   LDX     basic_ptr
        LDAA    #$0D
        CLR     column_cnt
Z2192   CPX     expr_stack_x
        BNE     Z219C
        LDAA    #7
        BSR     Z214C
        BRA     Z2163
Z219C   STAA    0,X
        INX
        INX
Z21A0   DEX
        STX     IL_temp
        CMPA    #$0D
        BNE     Z2163
        JSR     Z2128
        LDAA    IL_temp+1
        STAA    expr_stack_low
        JMP     IL__SP
L21B1   JSR     L1FC1
        JSR     Z201A
        TPA
        JSR     Z211C
        STX     BP_save
        LDX     IL_temp
        STX     LS_end
        CLRB
        TAP
        BNE     Z21D0
        JSR     L1F71
        LDAB    #$FE
Z21CA   DECB
        JSR     L1E20
        BNE     Z21CA
Z21D0   LDX     #0
        STX     basic_lineno
        JSR     L1FC1
        LDAA    #$0D
        LDX     basic_ptr
        CMPA    0,X
        BEQ     Z21EC
        ADDB    #3
Z21E2   INCB
        INX
        CMPA    0,X
        BNE     Z21E2
        LDX     LS_end
        STX     basic_lineno
Z21EC   LDX     BP_save
        STX     IL_temp
        TSTB
        BEQ     Z2248
        BPL     Z2218
        LDAA    basicptr_save+1
        ABA
        STAA    BP_save+1
        LDAA    basicptr_save
        ADCA    #$FF
        STAA    BP_save
Z2200   LDX     basicptr_save
        LDAB    0,X
        CPX     end_prgm
        BEQ     Z2244
        CPX     top_of_stack
        BEQ     Z2244
        INX
        STX     basicptr_save
        LDX     BP_save
        STAB    0,X
        INX
        STX     BP_save
        BRA     Z2200
Z2218   ADDB    end_prgm+1
        STAB    basicptr_save+1
        LDAA    #0
        ADCA    end_prgm
        STAA    basicptr_save
        SUBB    top_of_stack+1
        SBCA    top_of_stack
        BCS     Z222E
        DEC     il_pc+1
        JMP     L1D5C
Z222E   LDX     basicptr_save
        STX     BP_save
Z2232   LDX     end_prgm
        LDAA    0,X
        DEX
        STX     end_prgm
        LDX     basicptr_save
        STAA    0,X
        DEX
        STX     basicptr_save
        CPX     IL_temp
        BNE     Z2232
Z2244   LDX     BP_save
        STX     end_prgm
Z2248   LDX     basic_lineno
        BEQ     Z2265
        LDX     IL_temp
        LDAA    basic_lineno
        LDAB    basic_lineno+1
        STAA    0,X
        INX
        STAB    0,X
Z2257   INX
        STX     IL_temp
        JSR     L1E20
        LDX     IL_temp
        STAA    0,X
        CMPA    #$0D
        BNE     Z2257
Z2265   LDS     top_of_stack
        JMP     L1D2A

;
; TBIL program table
;
ILTBL   DB      $24, $3A, $91, $27, $10, $E1, $59, $C5, $2A, $56, $10, $11, $2C, $8B, $4C
        DB      $45, $D4, $A0, $80, $BD, $30, $BC, $E0, $13, $1D, $94, $47, $CF, $88, $54
        DB      $CF, $30, $BC, $E0, $10, $11, $16, $80, $53, $55, $C2, $30, $BC, $E0, $14
        DB      $16, $90, $50, $D2, $83, $49, $4E, $D4, $E5, $71, $88, $BB, $E1, $1D, $8F
        DB      $A2, $21, $58, $6F, $83, $AC, $22, $55, $83, $BA, $24, $93, $E0, $23, $1D
        DB      $30, $BC, $20, $48, $91, $49, $C6, $30, $BC, $31, $34, $30, $BC, $84, $54
        DB      $48, $45, $CE, $1C, $1D, $38, $0D, $9A, $49, $4E, $50, $55, $D4, $A0, $10
        DB      $E7, $24, $3F, $20, $91, $27, $E1, $59, $81, $AC, $30, $BC, $13, $11, $82
        DB      $AC, $4D, $E0, $1D, $89, $52, $45, $54, $55, $52, $CE, $E0, $15, $1D, $85
        DB      $45, $4E, $C4, $E0, $2D, $98, $4C, $49, $53, $D4, $EC, $24, $00, $00, $00
        DB      $00, $0A, $80, $1F, $24, $93, $23, $1D, $30, $BC, $E1, $50, $80, $AC, $59
        DB      $85, $52, $55, $CE, $38, $0A, $86, $43, $4C, $45, $41, $D2, $2B, $84, $52
        DB      $45, $CD, $1D, $39, $57, $00, $00, $00, $85, $AD, $30, $D3, $17, $64, $81
        DB      $AB, $30, $D3, $85, $AB, $30, $D3, $18, $5A, $85, $AD, $30, $D3, $19, $54
        DB      $2F, $30, $E2, $85, $AA, $30, $E2, $1A, $5A, $85, $AF, $30, $E2, $1B, $54
        DB      $2F, $97, $52, $4E, $C4, $0A, $80, $80, $12, $0A, $09, $29, $1A, $0A, $1A
        DB      $85, $18, $13, $09, $80, $12, $0B, $31, $30, $61, $73, $0B, $02, $04, $02
        DB      $03, $05, $03, $1B, $1A, $19, $0B, $09, $06, $0A, $00, $00, $1C, $17, $2F
        DB      $8F, $55, $53, $D2, $80, $A8, $30, $BC, $31, $2A, $31, $2A, $80, $A9, $2E
        DB      $2F, $A2, $12, $2F, $C1, $2F, $80, $A8, $30, $BC, $80, $A9, $2F, $83, $AC
        DB      $38, $BC, $0B, $2F, $80, $A8, $52, $2F, $84, $BD, $09, $02, $2F, $8E, $BC
        DB      $84, $BD, $09, $03, $2F, $84, $BE, $09, $05, $2F, $09, $01, $2F, $80, $BE
        DB      $84, $BD, $09, $06, $2F, $84, $BC, $09, $05, $2F, $09, $04, $2F, $84, $42
        DB      $59, $C5, $26, $86, $4C, $4F, $41, $C4, $28, $1D, $86, $53, $41, $56, $C5
        DB      $29, $1D, $A0, $80, $BD, $38, $14

; Fill rest of ROM with FFs.

        DS      $F400-*,$FF

;       END
