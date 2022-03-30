; Program to copy MicroBas from ROM to RAM. As it uses a lot of
; self-modifying code, it must run from RAM. This program copies the
; code from ROM (addresses $C100 to $CFFF) to RAM (addresses $0100 to
; $0FFF) and then executes it starting at address $0100.
;
; Jeff Tranter <tranter@pobox.com>

        CODE
        CPU 6800
        OUTPUT HEX                      ; For Intel hex output

FROM    EQU     $C100                   ; Address to copy from
TO      EQU     $0100                   ; Address to copy to
END     EQU     $0FFF                   ; Last address to copy to
GO      EQU     $0100                   ; Start address of Basic in RAM
EXTERN  EQU     $7F00                   ; Location of Basic EXTERN routine

*       EQU     $0000

src     DS      2                       ; Holds source address
dest    DS      2                       ; Holds destination address

*       EQU     $C000

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

done    ldaa    #$39                    ; RTS
        staa    EXTERN                  ; Write the RTS needed by the EXTERN command
        jmp     GO                      ; Jump to start of Basic

; Fill unused locations with $FF

        DS      $C100-*,$FF
