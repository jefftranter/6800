        NAM Heathkit SAMPLE1
        PAGE 132,66

;                   SAMPLE 1
;      TURNS ON AND OFF EACH SEGMENT IN
;      SEQUENCE BEGINNING AT H DISPLAY
;      USES MONITOR SUBROUTINES REDIS AND OUTCH
;      NOTE: ONE DP IN EACH DISPLAY IS ACTIVE

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        REDIS   EQU $FCBC
        DIGADD  EQU $F0
        OUTCH   EQU $FE3A

        * = $0000

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
        BRA     START           ; DO AGAIN
