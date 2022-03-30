; Program to copy Microsoft Basic 680 from ROM to RAM. As it uses a
; lot of self-modifying code, it must run from RAM. This program
; copies the code from ROM (addresses $C000 to $DEFF) to RAM
; (addresses $0000 to $1EFFF) and then executes it starting at address
; $0000. It also contains the hardware platform-specific initialiasation
; and i/o routines
;
; Jeff Tranter <tranter@pobox.com>

        CODE
        CPU 6800
        OUTPUT HEX                      ; For Intel hex output

;      ACIA ADDRESSES
ACIACR  EQU     $8300
ACIASR  EQU     $8300
ACIADR  EQU     $8301

FROM    EQU     $C000                   ; Address to copy from
TO      EQU     $0000                   ; Address to copy to
END     EQU     $1EFF                   ; Last address to copy to
GO      EQU     $0000                   ; Start address of Basic in RAM

*       EQU     $7000

src     DS      2                       ; Holds source address
dest    DS      2                       ; Holds destination address

*       EQU     $DF00

        ldx     #FROM                   ; Set source address
        stx     src
        ldx     #TO                     ; Set destination address
        stx     dest

loop    ldx     src                     ; Get source address
        ldaa    0,x                     ; Get byte from source
        ldx     dest                    ; Get destination address
        staa    0,x                     ; Copy to destination
        inx                             ; Increment destination address
        cpx     #END+1                  ; Last address reached?
        beq     done                    ; If so, break out of loop

        stx     dest                    ; Save incremented destination address
        ldx     src                     ; Increment source address
        inx
        stx     src
        bra     loop                    ; Keep copying

done    ldaa    #$03                    ; Reset ACIA
        staa    ACIACR
        ldaa    #$15                    ; Set ACIA to 8N1, CLK/16, RTS LOW
        staa    ACIACR
        jmp     GO                      ; Jump to start of Basic


; Poll input; carry set if char avail

POLCAT LDAA   ACIASR   ;GET RX STATUS
       LSRA            ;ROTATE RX BIT INTO C
       RTS

INCH   LDAB   ACIASR   ;GET RX STATUS
       LSRB            ;ROTATE RX BIT INTO C
       BCC    INCH
       LDAB   ACIADR   ;GET DATA
       RTS

OUTCH  PSHA
       LDAA   #2       ;MASK FOR ACIACR
OUT1   BITA   ACIASR
       BEQ    OUT1
       PSHB            ;SAVE ORIGINAL A
       ANDB   #$7F     ;CONVERT TO 7-BIT ASCII
       STAB   ACIADR   ;SEND (A) TO CONSOLE
       PULB            ;RESTORE A
       TSTB            ;RESTORE FLAGS
       PULA
OUT2   RTS

MF002  DB      $FF     ; Hardware straps at $8200? See MikBug.

; Fill unused locations with $FF

        DS      $E000-*,$FF
