; Example of programmming real-time clock using a real-time clock
; module based on the Dallas Semiconductor DS1302 timekeeping chip
; connected to the 6821 PIA.
;
; Jeff Tranter <tranter@pobox.com>
;
; Hardware connections between 68210 PIA (via the parallel port
; connector) and DS1302 clock module:
;
; SBC  DS1302
; ---  ------
; VCC  VCC
; GND  GND
; PB0  RST
; PB1  CLK
; PB2  DAT
;
; You will also need a pullup resistor connected from PB1 to VCC;
; suggested value 10Kohms.
;
; Notes:
; 1. See the DS1302 datasheet for details.
; 2. No support yet for RAM functions.
; 3. No support yet for burst mode.

        CPU     6800
        OUTPUT  SCODE           ; For Motorola S record (RUN) output

; Constants

PIA     equ     $8200           ; 6821 VIA base address
DDRB    equ     PIA+2           ; Data Direction Register B
PRB     equ     PIA+2           ; Peripheral Register B
CRB     equ     PIA+3           ; Control Register B

RST     equ     $01             ; Reset bit in PIA
CLK     equ     $02             ; CLK bit in PIA
DAT     equ     $04             ; DAT bit in PIA

MONITOR equ     $F400           ; Start address of monitor
THB0    equ     $F580           ; Print A in hex
OUTCH   equ     $F569           ; Output char in A

        * EQU   $1000           ; Start address

; Variables

REGNUM  ds      1               ; Register to read/write
REGDATA ds      1               ; Register data to read/write
RAMCLK  ds      1               ; Set to 1 to read/write RAM, 0 for clock registers

; Code

        * EQU   $1010           ; Start address

        lds     #$7F00          ; Initialize stack

; Enable code below if you want to initially set the date.

if 0

START   ldaa    #$00            ; Select clock registers
        staa    RAMCLK
        ldaa    #$07            ; Select register 7 (control)
        staa    REGNUM
        ldaa    #$00            ; Turn off write protect
        staa    REGDATA
        jsr     WRITE           ; Call write routine
        ldaa    #$06            ; Select register 6 (year)
        staa    REGNUM
        LDAA    #$22            ; Year 2022
        staa    REGDATA
        jsr     WRITE           ; Call write routine
        ldaa    #$04            ; Select register 4 (month)
        staa    REGNUM
        LDAA    #$04            ; Month 04
        staa    REGDATA
        jsr     WRITE           ; Call write routine
        ldaa    #$03            ; Select register 3 (day)
        staa    REGNUM
        LDAA    #$10            ; Day 10
        staa    REGDATA
        jsr     WRITE           ; Call write routine

        ldaa    #$02            ; Select register 2 (hours)
        staa    REGNUM
        LDAA    #$22            ; Hour 22
        staa    REGDATA
        jsr     WRITE           ; Call write routine

        ldaa    #$01            ; Select register 1 (minutes)
        staa    REGNUM
        LDAA    #$30            ; Minutes 30
        staa    REGDATA
        jsr     WRITE           ; Call write routine

        ldaa    #$00            ; Select register 0 (seconds)
        staa    REGNUM
        LDAA    #$00            ; Seconds 0
        staa    REGDATA
        jsr     WRITE           ; Call write routine

endc

DISP    ldaa    #$02            ; Select register 2 (hours)
        staa    REGNUM
        jsr     READ            ; Call read routine
        ldaa    REGDATA         ; Get data read
        anda    #$3F            ; Mask out hours
        jsr     THB0            ; Print it
        ldaa    #':'
        jsr     OUTCH
        ldaa    #$01            ; Select register 1 (minutes)
        staa    REGNUM
        jsr     READ            ; Call read routine
        ldaa    REGDATA         ; Get data read
        jsr     THB0            ; Print it
        ldaa    #':'
        jsr     OUTCH
        ldaa    #$00            ; Select register 1 (seconds)
        staa    REGNUM
        jsr     READ            ; Call read routine
        ldaa    REGDATA         ; Get data read
        jsr     THB0            ; Print it
        ldaa    #' '
        jsr     OUTCH
        ldaa    #$03            ; Select register 3 (date)
        staa    REGNUM
        jsr     READ            ; Call read routine
        ldaa    REGDATA         ; Get data read
        jsr     THB0            ; Print it
        ldaa    #'/'
        jsr     OUTCH
        ldaa    #$04            ; Select register 4 (month)
        staa    REGNUM
        jsr     READ            ; Call read routine
        ldaa    REGDATA         ; Get data read
        jsr     THB0            ; Print it
        ldaa    #'/'
        jsr     OUTCH
        ldaa    #$06            ; Select register 6 (year)
        staa    REGNUM
        jsr     READ            ; Call read routine
        ldaa    REGDATA         ; Get data read
        jsr     THB0            ; Print it
        ldaa    #$0D            ; Print CR
        jsr     OUTCH
        ldaa    #$0A            ; Print LF
        jsr     OUTCH
        ldx     #$FFFF          ; Delay between reads
delay   dex
        bne     delay
        jmp     DISP
;       jmp     MONITOR         ; Go back to monitor

READ    ldaa    #$00            ; Select data direction register
        staa    CRB
        ldaa    #RST|CLK|DAT    ; Set RST, CLK, and DAT as outputs, others as inputs
        staa    DDRB            ; Write to DDRB
        ldaa    #$04            ; Select peripheral register
        staa    CRB
        ldaa    #$00            ; Set CLK and RST low
        staa    PRB
        nop                     ; Short delay
        ldaa    #RST            ; Set RST high
        staa    PRB
        nop                     ; Short delay
        oraa    #DAT            ; Set DAT line to 1 (read)
        staa    PRB
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        ldx     #5              ; Number of address bits to send
        ldab    REGNUM          ; Get register address
nxt     anda    #~DAT           ; Clear data bit
        lsrb                    ; Shift bit into carry
        bcc     s0              ; Branch to send 0, fall through to send 1
        oraa    #DAT            ; Set data bit to 1
s0      oraa    #RST            ; Always want RST high
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        dex                     ; Decrement bit count
        bne     nxt             ; Continue sending bits if not done
        ldaa    #$00            ; Set DAT line to 1 for RAM or 0 for clock register
        oraa    #RST
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        ldaa    #DAT            ; Set DAT line to 1
        oraa    #RST
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        ldaa    #$00            ; Select data direction register
        staa    CRB
        ldaa    #RST|CLK        ; Now set DAT as input
        staa    DDRB            ; Write to DDRB
        ldaa    #$04            ; Select peripheral register
        staa    CRB
        clrb                    ; Initially clear read data
        ldx     #8              ; Number of bits to read
rl      lsrb                    ; Shift previous value
        ldaa    #RST|CLK        ; Toggle CLK high
        staa    PRB
        ldaa    PRB             ; Read data bit 0 on DAT line
        bita    #DAT            ; Is data bit set?
        beq     r0              ; Branch if zero
        orab    #$80            ; Set bit
r0      ldaa    #RST            ; Toggle CLK low
        staa    PRB
        dex                     ; Decrement bit count
        bne     rl              ; Do next bit if not done
        stab    REGDATA         ; Save it
        ldaa    #CLK|RST        ; Toggle CLK high
        staa    PRB
        ldaa    #CLK            ; Set RST low
        staa    PRB
        rts                     ; Done
WRITE   ldaa    #$00            ; Select data direction register
        staa    CRB
        ldaa    #RST|CLK|DAT    ; Set RST, CLK, and DAT as outputs, others as inputs
        staa    DDRB            ; Write to DDRB
        ldaa    #$04            ; Select peripheral register
        staa    CRB
        ldaa    #$00            ; Set CLK and RST low
        staa    PRB
        nop                     ; Short delay
        ldaa    #RST            ; Set RST high
        staa    PRB             ; Note that DAT line is set to 0 (write)
        nop                     ; Short delay
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        ldx     #5              ; Number of address bits to send
        ldab    REGNUM          ; Get register address
wnxt    anda    #~DAT           ; Clear data bit
        lsrb                    ; Shift bit into carry
        bcc     ws0             ; Branch to send 0, fall through to send 1
        oraa    #DAT            ; Set data bit to 1
ws0     oraa    #RST            ; Always want RST high
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        dex                     ; Decrement bit count
        bne     wnxt            ; Continue sending bits if not done
        ldaa    #$00            ; Set DAT line to 1 for RAM or 0 for clock register
        oraa    #RST
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        ldaa    #DAT            ; Set DAT line to 1
        oraa    #RST
        oraa    #CLK            ; Toggle CLK high and then low
        staa    PRB
        eora    #CLK
        staa    PRB
        ldab    REGDATA         ; Get write data
        ldx     #8              ; Number of bits to write
wrl     ldaa    #RST|CLK        ; Toggle CLK high
        lsrb                    ; Shift bit into carry
        bcc     w0
        oraa    #DAT            ; Set data bit
w0      staa    PRB
        eora    #CLK            ; Toggle CLK low
        staa    PRB
        dex                     ; Decrement bit count
        bne     wrl             ; Do next bit if not done
        ldaa    #CLK|RST        ; Toggle CLK high
        staa    PRB
        ldaa    #CLK            ; Set RST low
        staa    PRB
        rts                     ; Done
