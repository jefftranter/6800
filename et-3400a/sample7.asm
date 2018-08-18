        NAM Heathkit SAMPLE7
        PAGE 66,132

;                  SAMPLE 7
;      THIS PROGRAM CALCULATES THE OP CODE VALUE
;      FOR BRANCH INSTRUCTIONS USING THE LAST TWO
;      DIGITS OF THE BRANCH AND DESTINATION ADDRESSES.
;      THE BRANCH ADDRESS IS ENTERED FIRST AND
;      DISPLAYED AT "H" AND "I". THE DESTINATION
;      ADDRESS IS THEN ENTERED AND DISPLAYED AT
;      "N" AND "Z". THE OP CODE IS THEN CALCULATED
;      AND DISPLAYED AT "V" AND "C". THE DISPLAY
;      IS HELD UNTIL NEW INFORMATION IS ENTERED.
;      SINCE ONLY TWO BYTES ARE ENTERED, IT IS
;      NECESSARY TO MAKE AN ADJUSTMENT IF THE
;      HUNDREDS DIGIT IN THE TWO ADDRESSES IS NOT
;      THE SAME. FOR EXAMPLE TO CALCULATE THE
;      OFFSET OF A BRANCH FROM 00CD TO 011B.
;      SUBTRACT A NUMBER FROM BOTH ADDRESSES THAT
;      WILL MAKE THE CALCULATION ADDRESS LESS THAN 100.
;      FOR EASE OF CALCULATION IN THIS CASE,
;      SUBTRACT C0 FROM BOTH ADDRESSES AND ENTER
;      THE RESULTS 0D AND 5B IN THE PROGRAM.
;      SINCE THE DIFFERENCES BETWEEN THE ADDRESSES
;      IS UNCHANGED THE CORRECT OPCODE (4C) WILL
;      BE DISPLAYED. IF THE DISTANCE IS TOO GREAT
;      FOR BRANCHING NO. WILL APPEAR AT "V" AND "C".
;      USES MONITOR SUB ROUTINES
;      REDIS IHB OUTBYT OUTSTR

; Entered from listing in ET-3400A manual by Jeff Tranter <tranter@pobox.com>
; Add definitions to get it to assemble and adapted to the crasm
; assembler (https://github.com/colinbourassa/crasm).

        CPU 6800

        REDIS   EQU $FCBC
        IHB     EQU $FE09
        OUTBYT  EQU $FE20
        OUTSTR  EQU $FE52

        * = $0000

START   JSR     REDIS           ; FIRST DISPLAY AT "H"
        JSR     IHB             ; INPUT BRANCH ADDRESS
        TAB                     ; PUT IT IN B
        JSR     IHB             ; INPUT DESTINATION ADDRESS
        CBA                     ; FORWARD OR BACK?
        BCS     BACK            ; IF BACK
FRWD    ADDB    #$02            ; ADJUST 2 BYTES
        SBA                     ; FIND DIFFERENCE
        CMPA    #$80            ; IS IT LEGAL?
        BCC     NO              ; IF NOT
OUT     JSR     OUTBYT          ; OUTPUT BRANCH OPCODE
        BRA     START           ; LOOK FOR NEW ENTRY
BACK    NEGA                    ; MAKE A MINUS
        ABA                     ; ADD A AND B
        ADDA    #$02            ; ADJUST 2 BYTES
        COMA                    ; GET COMPLEMENT
        ADDA    #$01            ; MAKE IT TWO'S
        CMPA    #$80            ; IS IT LEGAL?
        BCS     NO              ; IF NOT
        BRA     OUT             ; OUTPUT BRANCH OP CODE
NO      JSR     OUTSTR          ; OUTPUT STRING
        DB      $15,$9D         ; NO.
        BRA     START           ; LOOK FOR NEW ENTRY
