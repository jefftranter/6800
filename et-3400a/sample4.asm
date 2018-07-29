        NAM Heathkit SAMPLE4
        PAGE 132,66

;                  SAMPLE 4
;      OUTPUTS SAME MESSAGE AS PROGRAM 3
;      IN TICKER TAPE FASHION
;      USES MONITOR SUB ROUTINES REDIS and OUTSTR


; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        REDIS   EQU $FCBC
        OUTSTR  EQU $FE52
        MORE    EQU $06         ; MUST MATCH ADDRESS OF LABEL LMORE BELOW

        * = $0000

START   CLR     MORE+1          ; CLEAR POINTER
NEXT    LDX     #MESSA          ; MESSAGE ADDRESS
LMORE   LDAA    0,X             ; GET CHARACTER
        STAA    OUT+3-MESSA,X   ; STORE CHAR. AT OUT PLUS
        INX                     ; NEXT CHARACTER
        CPX     #$30            ; FULL STRING YET?
        BNE     MORE
        BSR     HOLD            ; HOLD DISPLAY
        JSR     REDIS           ; FIRST CHAR TO "H" DISPLAY
        JSR     OUT
        LDAA    MORE+1          ; FIRST CHARACTER NUMBER
        INCA                    ; MOVE STRING UP ONE CHARACTER
        STAA    MORE+1          ; NEW FIRST CHARACTER
        CMPA    #$25            ; LAST CHARACTER TO "H" YET?
        BNE     NEXT            ; BUILD NEXT STRING
        BRA     START           ; DO AGAIN
HOLD    LDX     #$6000          ; TIME TO WAIT
WAIT    DEX
        BNE     WAIT            ; TIME OUT YET?
        RTS

MESSA   DB      $08,$08,$08,$08,$08,$08     ; ---

        DB      $3B,$7E,$3E,$05,$00,$00     ; YOUR

        DB      $79,$33,$7E,$7E,$00,$00     ; 3400

        DB      $30,$5B,$00,$00,$3E,$67     ; IS UP

        DB      $00,$00,$7D,$15,$3D,$00,$00 ; AND

        DB      $05,$1C,$15,$15,$10,$15     ; RUNNIN

        DB      $08,$08,$08,$08,$08         ; ---

OUT     JSR     OUTSTR          ; OUTPUT CHARACTER STRING
        ; OUTPUT STRING STORED HERE
        DB      $00,$00,$00,$00,$00,$00,$80
        RTS                     ; NOTE: MISSING FROM LISTING IN MANUAL
