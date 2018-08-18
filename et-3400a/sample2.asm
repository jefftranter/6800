        NAM Heathkit SAMPLE2
        PAGE 66,132

;                   SAMPLE 2
;      TURNS ALL DISPLAYS OFF AND ON
;      DISPLAYS HEX VALUE AT 0044
;      USES MONITOR SUBROUTINES REDIS, OUTCH AND OUTHEX

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        REDIS   EQU $FCBC
        OUTCH   EQU $FE3A
        DIGADD  EQU $F0
        OUTHEX  EQU $FE28

        * = $0030

START   JSR     REDIS           ; FIRST DISPLAY ADDRESS
CLEAR   CLRA
        JSR     OUTCH           ; TURN ALL SEGMENTS OFF
        LDX     DIGADD          ; NEXT DISPLAY
        CPX     #$C10F          ; LAST DISPLAY YET?
        BNE     CLEAR
        BSR     HOLD
        JSR     REDIS           ; FIRST DISPLAY ADDRESS
        LDAA    #$08            ; HEX VALUE TO DISPLAY
OUT     JSR     OUTHEX          ; OUTPUT CHARACTER
        LDX     DIGADD          ; NEXT DISPLAY
        CPX     #$C10F          ; LAST DISPLAY YET?
        BNE     OUT
        BSR     HOLD
        BRA     START           ; DO AGAIN
HOLD    LDX     #$FF00          ; TIME TO WAIT
WAIT    DEX
        BNE     WAIT            ; TIME OUT YET?
        RTS
