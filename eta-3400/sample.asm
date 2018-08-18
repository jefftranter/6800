        NAM Heathkit SAMPLE1
        PAGE 66,132

;                   A SAMPLE PROGRAM
;
; The sample program provides you with a routine to test the operation
; of your ETA-3400 Microcomoputer Accessory. You can use the routine
; to gain proficiency with the FANTOM II Monitor. The routine is a
; duplicate (with minor changes) of a program listed in the ET-3400
; Manual.
;
; Use FANTOM II when you enter, verify, and execute the sample
; program. When the program is running the LED on the ET-3400 Trainer
; will sequentially turn each segment on and off and then return to
; the monitor.

; Entered from listing on page 22 of ETA-3400 manual by Jeff Tranter
; <tranter@pobox.com>.
; Added definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        REDIS   EQU $FCBC
        DIGADD  EQU $F0
        OUTCH   EQU $FE3A
        MAIN    EQU $1400

        * = $1000

START   JSR     REDIS           ; SET UP FIRST DISPLAY ADDRESS
        LDAA    #$01            ; FIRST SEGMENT CODE
        BRA     OUT
SAME    LDAB    DIGADD+1        ; FIX DISPLAY ADDRESS
        ADDB    #$10            ; FOR NEXT ADDRESS
        STAB    DIGADD+1
        ASLA                    ; NEXT SEGMENT CODE
OUT     JSR     OUTCH           ; OUTPUT SEGMENT
        LDX     #$2F00          ; TIME TO WAIT
WAIT    DEX
        BNE     WAIT            ; TIME OUT YET?
        TAB
        TSTB                    ; LAST SEGMENT THIS DISPLAY?
        BNE     SAME            ; NEXT SEGMENT
        LDAA    #$01            ; RESET SEGMENT CODE
        LDX     DIGADD          ; NEXT DISPLAY
        CPX     #$C10F          ; LAST DISPLAY YET?
        BNE     OUT
        JSR     MAIN            ; Go to monitor
