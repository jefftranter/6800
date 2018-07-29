        NAM Heathkit SAMPLE3
        PAGE 132,66

;                  SAMPLE 3
;      OUTPUTS MESSAGE BY DISPLAYING UP TO SIX
;      CHARACTER WORD ONE WORD AT A TIME
;      USES MONITOR SUB ROUTINE OUTSTO
;      NOTE: DP MUST BE LIT TO INDICATE END OF STRING
;      TO EXIT OUTSTR. DP IS PLACED IN THE
;      SEVENTH DISPLAY POSITION TO FULFILL THIS
;      REQUIREMENT WITHOUT ACTUALLY BEING DISPLAYED.

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        OUTSTO  EQU $FD8D
        
        * = $0060

START   JSR     OUTSTO          ; LEFT DISPLAY  OUT WORD
        DB      $00,$3B,$7E,$3E,$05,$00,$80 ; YOUR

        BSR     HOLD            ; HOLD DISPLAY
        JSR     OUTSTO          ; LEFT DISPLAY  OUT WORD
        DB      $00,$79,$33,$7E,$7E,$00,$80 ; 3400

        BSR     HOLD            ; HOLD DISPLAY
        JSR     OUTSTO          ; LEFT DISPLAY  OUT WORD
        DB      $00,$00,$30,$5B,$00,$00,$80 ; IS

        BSR     HOLD            ; HOLD DISPLAY
        JSR     OUTSTO          ; LEFT DISPLAY  OUT WORD
        DB      $00,$00,$3E,$67,$00,$00,$80 ; UP

        BSR     HOLD            ; HOLD DISPLAY
        JSR     OUTSTO          ; LEFT DISPLAY  OUT WORD
        DB      $00,$00,$7D,$15,$3D,$00,$80 ; AND

        BSR     HOLD            ; HOLD DISPLAY
        JSR     OUTSTO          ; LEFT DISPLAY  OUT WORD
        DB      $05,$1C,$15,$15, $10,$15,$80     ; RUNNIN

        BSR     HOLD            ; HOLD DISPLAY
        JMP     START           ; DO AGAIN
HOLD    LDX     #$FF00          ; TIME TO WAIT
WAIT    DEX
        BNE     WAIT            ; TIME OUT YET?
        RTS

