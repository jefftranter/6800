        NAM Heathkit SAMPLE6
        PAGE 66,132

;                  SAMPLE 6
;      THIS IS A TWELVE HOUR CLOCK PROGRAM
;      THE ACCURACY IS DEPENDENT UPON THE MPU CLOCK
;      FREQUENCY AND THE TIMING LOOP AT START.
;      CHANGING THE VALUE AT 0005/6 BY HEX 100
;      CHANGES THE ACCURACY APPROXIMATELY 1 SEC/MIN.
;      HOURS.MINUTE.SECOND RMB 0001/2/3 ARE LOADED
;      WITH THE STARTING TIME. THE FIRST DISPLAY
;      IS ONE SECOND AFTER START OF THE PROGRAM.
;      SECONDS WILL BE CONTENT OF SECOND RMB +1.
;      USES MONITOR SUBROUTINES REDIS,DISPLAY.
;      NOTE:START THE PROGRAM AT 0004.

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        REDIS   EQU $FCBC
        DSPLAY  EQU $FD7B

; Different code is used depending on whether running on an ET-3400 or
; ET-3400A (due to different clock speeds). Define one of the two
; symbols below to 1 depending on your system. Use ET3400A if running
; on an ET-3400 modified for a 4 MHz crystal clock (e.g. for use with
; the ETA-3400.

        ET3400 EQU 1
        ET3400A EQU 0

        * = $0001

HOURS   DS  1
MINUTE  DS  1
SECOND  DS  1

        if ET3400
START   LDX     #$B500          ; ADJUST FOR ACCURACY
        endc

        if ET3400A
START   LDX     #$CEB3          ; ADJUST FOR ACCURACY
        endc

DELAY   DEX
        BNE     DELAY           ; WAIT ONE SECOND

        if ET3400A
        LDX     #$FFFF          ; SET FIXED DELAY
SETDEL  DEX
        BNE     SETDEL
        endc

        LDAB    #$60            ; SIXTY SECONDS.SIXTY MINUTES
        SEC                     ; ALWAYS INCREMENT SECONDS
        BSR     INCS            ; INCREMENT SECONDS
        BSR     INCMH           ; INCREMENT MINUTES IF NEEDED
        LDAB    #$13            ; TWELVE HOUR CLOCK
        BSR     INCMH           ; INCREMENT HOURS IS NEEDED
        JSR     REDIS           ; RESET DISPLAY ADDRESS
        LDAB    #3              ; NUMBER OF BYTES TO DISPLAY
        BSR     PRINT           ; DISPLAY HOURS.MINUTES.SECONDS
        BRA     START           ; DO AGAIN

INCS    LDX     #SECOND         ; POINT X AT TIME RMB
INCMH   LDAA    0,X             ; GET CURRENT TIME
        ADCA    #0              ; INCREMENT IF NECESSARY
        DAA                     ; FIX TO DECIMAL
        CBA                     ; TIME TO CLEAR?
        BCS     STORE           ; NO
        CLRA
STORE   STAA    0,X             ; STORE NEW TIME
        DEX                     ; GET NEXT TIME
        TPA
        EORA    #1              ; COMPLEMENT CARRY BIT
        TAP
        RTS

PRINT   LDAA    HOURS           ; WHAT'S IN HOURS?
        BNE     CONTIN          ; IF NOT ZERO
        INC     HOURS           ; MAKE HOURS ONE
CONTIN  INX                     ; POINT X AT HOURS
        JMP     DSPLAY          ; OUTPUT TO DISPLAYS

