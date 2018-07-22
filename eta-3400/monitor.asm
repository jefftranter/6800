        NAM Heathkit ETA-3400 Monitor
        PAGE 132,66

; Entered from listing in ETA-340A manual by Jeff Tranter <tranter@pobox.com>.
; Fixed some small errors in the listing.
; Adapted to the crasm assembler (https://github.com/colinbourassa/crasm).
; Note that I do not own an ETA-3400 and have no way of testing it but I
; have confirmed that it produces the same binary output as the Heathkit
; ROMs.

        CPU 6800

;;;     HEATH/WINTEK TERMINAL MONITOR SYSTEM
;
;       BY JIM WILSON FOR WINTEK CORPORATION
;         COPYRIGHT 1978 BY WINTEK CORP.
;            ALL RIGHTS RESERVED
;

;;      CONDITIONAL ASSEMBLIES

DEBUG   EQU     0               ; DEBUG CODE OFF

;;      CHARACTER DEFINITIONS

CR      EQU     $0D
LF      EQU     $0A
SPACE   EQU     ' '

;;      PIA DEFINITION

*       EQU     $1000
TERM    DS      1
TERM.C  DS      1
TAPE    DS      1
TAPE.C  DS      1

;;      EXTERNALS

SSTEP   EQU     $FE6B
SWIVE1  EQU     $FEFC
OPTAB   EQU     $FF76
REDIS   EQU     $FCBC
DISPLAY EQU     $FD7B
OUTBYT  EQU     $FE20
BKSP    EQU     $FD43
PROMPT  EQU     $FD25
OUTSTA  EQU     $FC86
OUTSTR  EQU     $FE52

;;      RAM TEMPORARIES

*       EQU     $00CC
USERC   DS      1               ; CONDX CODES
USERB   DS      1
USERA   DS      1               ; ACCUMULATORS
USERX   DS      2               ; INDEX
USERP   DS      2               ; P.C.

*       EQU     $00E4
NBR     EQU     4               ; FOUR BREAKPOINTS ALLOWED
BKTBL   DS      2*NBR
T0      DS      2
T1      DS      2
DIGADD  DS      2
USERS   DS      2
T2      EQU     *
SYSSWI  DS      3
UIRQ    DS      3
USWI    DS      3
UNMI    DS      3

        IF      DEBUG
        ELSE
*       EQU     $1400
        ENDC


;;      MAIN MONITOR LOOP
;
;       1)  FEELS OUT MEMORY
;       2)  SEARCHES FOR PAST INCARNATIONS
;            A) CLEARS BREAKPOINTS IF REINCARNATED
;            B) CLEARS BREAKPOINT TABLE OTHERWISE
;       3)  SENDS PROMPT "MON>"
;       4)  ACCEPTS COMMAND CHARACTERS AND JUMPS
;             TO APPROPRIATE HANDLER

MAIN    SEI
        LDX     #TERM           ; TERMINAL PIA
        CLR     1,X             ; IN CASE IRREGULAR ENTRY
        CLR     3,X
        LDAA    #1
        STAA    0,X
        LDAA    #%01111111
        STAA    2,X
        LDAB    #4
        STAB    1,X
        STAB    3,X
        STAA    0,X             ; IDLE MARKING!!

;;      NOW FIND MEMORY EXTENT

MAIN1   DEX
        LDAA    0,X
        COM     0,X
        COMA
        CMPA    0,X
        BNE     MAIN1
        COM     0,X             ; RESTORE GOOD BYTE
        LDAA    #4*NBR+5
MAIN2   DEX                     ; GO TO MONITOR GRAVEYARD
        DECA
        BNE     MAIN2
        TXS
        LDAA    #2*NBR+4
        LDX     2*NBR,X         ; RETURN ADDRESS IF ANY
        CPX     #MAIN5
        BEQ     MAIN4           ; IS RE-INCARNATION
        LDAB    #$FF
        TSX
MAIN3   STAB    2*NBR+2,X
        INX
        DECA
        BNE     MAIN3
MAIN4   LDAA    #NBR            ; CLEAR BREAKPOINTS
