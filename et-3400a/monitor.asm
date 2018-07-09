	cpu 6800
        * = $FC00

;; RESET - CLEAR BREAKPOINT TABLE AND INITIALIZE STACK
       
        code
RESET   LDS     #2*NBR+BKTBL-1
        JSR     OUTSTO
        FCC     HEXC,LTRP,LTRU,0,LTRU,LTRP+$80
        LDX     #USRSTLK
        STX     USERS
        LDAA    #$FF
        LDAB    #2*NBR
RESE1   PSHA
        DECB
        BNE     RESE1

;      MAIN - MAIN MONITOR LOOP
;
;       HANDLERS RETURN:

MAIN    STA A    T1
        LDA A    #-MAIN/256*256+MAIN

