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
; Notes:
; 1. See DS1302 datsheet for details.
; 2. No Support here for burst mode.
;
; Pseudocode to read a register, given regNum and data:
;
; - Set RST, CLK, and DAT as outputs, others as inputs
; - Select PIA peripheral regsister
;
; - set SCLK and RST low
;
; - set RST high
;
; - set DAT line to 1 (read)
; - toggle SCLK high and then low
;
; - set DAT line to bit 0 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 1 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 2 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 3 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 4 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to 1 for RAM or 0 for clock register
; - toggle SCLK high and then low
;
; - set DAT line to 1
; - toggle SCLK high and then low
;
; - Set DAT as input
;
; - toggle SCLK high
; - Read data bit 0 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 1 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 2 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 3 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 4 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 5 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 6 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - Read data bit 7 on DAT line
; - toggle SCLK low
;
; - toggle SCLK high
; - set RST low
;
; Pseudocode to write a register:
;
; - Set RST, CLK, and DAT as outputs, others as inputs
; - Select PIA peripheral regsister
;
; - set SCLK and RST low
;
; - set RST high
;
; - set DAT line to 0 (write)
; - toggle SCLK high and then low
;
; - set DAT line to bit 0 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 1 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 2 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 3 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to bit 4 of regNum
; - toggle SCLK high and then low
;
; - set DAT line to 1 for RAM or 0 for clock register
; - toggle SCLK high and then low
;
; - set DAT line to 1
; - toggle SCLK high and then low
;
; - Write data bit 0 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 1 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 2 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 3 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 4 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 5 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 6 on DAT line
; - toggle SCLK high and then low
;
; - Write data bit 7 on DAT line
; - toggle SCLK high and then low
;
; - set SCLK high
; - set RST low

        CPU     6800
        OUTPUT  SCODE           ; For Motorola S record (RUN) output

; Constants

PIA     equ     $8100           ; 6821 VIA
DDRB    equ     PIA+2           ; Data Direction Register B
PRB     equ     PIA+2           ; Peripheral Register B
CRB     equ     PIA+3           ; Control Register B

RST     equ     $01             ; Reset bit in PIA
CLK     equ     $02             ; CLK bit in PIA
DAT     equ     $04             ; DAT bit in PIA

MONITOR equ     $F400           ; Start address of monitor

        * EQU   $1000           ; Start address

; Variables

REGNUM  ds      1               ; Register to read/write
REGDATA ds      1               ; Register data to read/write
RAMCLK  ds      1               ; Set to 1 to read/write RAM, 0 for clock registers

; Code

START   ldaa    #$00            ; Select clock registers
        staa    RAMCLK
        ldaa    #$00            ; Select register 0
        staa    REGNUM
        jsr     READ            ; Call read routine
        jmp     MONITOR         ; Go back to monitor

READ    rts

WRITE   rts


