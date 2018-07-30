        NAM Heathkit SAMPLE5
        PAGE 132,66

;                  SAMPLE 5
;      THIS PROGRAM CONTINOUSLY CHANGES THE HEX
;      VALUE STORED AT KEY+1 UNTIL ANY HEX
;      KEY IS DEPRESSED. THE RIGHT DP IS LIT
;      TO INDICATE A VALUE HAS BEEN SET.
;      THE USER THEN DEPRESSES THE VARIOUS
;      HEX KEYS TO LOOK FOR THE SELECTED VALUE.
;      THE RELATIONSHIP OF DEPRESSED TO CORRECT KEY
;      IS MOMENTARILY DISPLAYED AS HI OR LO.
;      DP AGAIN LIGHTS INDICATING TRY AGAIN.
;      DEPRESSING THE CORRECT KEY DISPLAYS YES!
;      WHICH REMAINS UNTIL ANY KEY DEPRESSED
;      SETTING A NEW VALUE TO FIND.
;      USES MONITOR SUB ROUTINES ENCODE,OUTSTO,INCH

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        ENCODE  EQU $FDBB
        OUTSTO  EQU $FD8D
        INCH    EQU $FDF4
        KEY     EQU $0085       ; MUST MATCH ADDRESS OF LKEY BELOW

        * = $0060

START   CLR     KEY+1           ; CLEAR KEY POINTER
ILL     LDAB    #$20            ; VIOLATION COUNT
ILL1    JSR     ENCODE          ; WAIT FOR ILLEGAL INTERVAL
        BCS     ILL             ; STILL LEGAL?
        DECB
        BNE     ILL1            ; NOT A FELONY
LEGAL   LDAB    #$20            ; TIME UNTIL PAROLE
        BSR     LCODE           ; CHANGE KEY TO FIND
LEGAL1  JSR     ENCODE          ; SET KEY TO FIND
        BCC     LEGAL           ; KEY TO FIND SET?
        DECB
        BNE     LEGAL1          ; GOOD KEY?
OUTDP   JSR     OUTSTO          ; OUTPUT STRING
        DB      $00,$00,$00,$00,$00,$80 ; DP TO "C"

; DP LIT FIND SELECTED KEY
        JSR     INCH            ; LOOK FOR KEY
LKEY    LDAB    #KEY+1          ; GET KEY VALUE
        CBA                     ; IS IT RIGHT KEY?
        BEQ     YES             ; IF CORRECT
        BHI     HIGH            ; IF GREATER THAN KEY+1 VALUE
        JSR     OUTSTO          ; OUTPUT STRING
        DB      $00,$00,$00,$00,$0E,$7E,$80 ; LO
HOLD    LDX     #$6000          ; TIME TO HOLD DISPLAY
WAIT    DEX
        BNE     WAIT            ; LONG ENOUGH YET?
        BRA     OUTDP           ; TRY AGAIN
YES     JSR     OUTSTO          ; OUTPUT STRING
        DB      $00,$00,$3B,$4F,$5B,$A0 ; YES!
BRA     START                   ; DO AGAIN
LCODE   LDAA    KEY+1           ; CURRENT KEY VALUE
        INCA                    ; NEXT KEY
        STAA    KEY+1           ; KEY TO FIND
        CMPA    #$10            ; CAN'T BE GREATER THAN F
        BNE     GOOD
        CLR     KEY+1           ; MAKE IT 0
GOOD    RTS
HIGH    JSR     OUTSTO          ; OUTPUT STRING
        DB      $37,$30,$00,$00,$00,$00,$80 ; HI
        JMP     HOLD
