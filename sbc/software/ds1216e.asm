; Example or programmming real-time clock using a DS1216E SmartWatch
; ROM AKA No-Slot Clock. Install a DS1216E in the EPROM socket.
;
; Notes:
;
; In docs READ/WRITE refers to level of A2.
; Sequence:
; 1. One cycle with A2 high to reset.
; 2. Enable with 64 cycles with  A2 low, A1 set by pattern.
; 3. To read registers:
;     64 read cycles, A2 high, data returned in D0
; 3.  To write registers:
;     64 read cycles, A2 low, data set by A0
;
; Pattern: C5 3A A3 5C C5 3A A3 5C

        CPU     6800
        OUTPUT  SCODE           ; For Motorola S record (RUN) output

        * EQU   $1000

; Example read:

        ldaa    $C004           ; Reset sequence

        ldaa    $C001           ; 64 bit enable pattern
        ldaa    $C000
        ldaa    $C001
        ldaa    $C000
        ldaa    $C000
        ldaa    $C000
        ldaa    $C001
        ldaa    $C001

        ldaa    $C000
        ldaa    $C001
        ldaa    $C000
        ldaa    $C001
        ldaa    $C001
        ldaa    $C001
        ldaa    $C000
        ldaa    $C000

        ldaa    $C001
        ldaa    $C001
        ldaa    $C000
        ldaa    $C000
        ldaa    $C000
        ldaa    $C001
        ldaa    $C000
        ldaa    $C001

        ldaa    $C000
        ldaa    $C000
        ldaa    $C001
        ldaa    $C001
        ldaa    $C001
        ldaa    $C000
        ldaa    $C001
        ldaa    $C000

        ldaa    $C001
        ldaa    $C000
        ldaa    $C001
        ldaa    $C000
        ldaa    $C000
        ldaa    $C000
        ldaa    $C001
        ldaa    $C001

        ldaa    $C000
        ldaa    $C001
        ldaa    $C000
        ldaa    $C001
        ldaa    $C001
        ldaa    $C001
        ldaa    $C000
        ldaa    $C000

        ldaa    $C001
        ldaa    $C001
        ldaa    $C000
        ldaa    $C000
        ldaa    $C000
        ldaa    $C001
        ldaa    $C000
        ldaa    $C001

        ldaa    $C000
        ldaa    $C000
        ldaa    $C001
        ldaa    $C001
        ldaa    $C001
        ldaa    $C000
        ldaa    $C001
        ldaa    $C000

; Now read 64 register bits using 64 reads.
; A2 must be high, data is in D0

        ldx     #$2000          ; Start of data buffer
loop    ldaa    $C004           ; Get data
        staa    0,X             ; Save in buffer
        inx                     ; Advance buffer
        cpx     #$C040          ; 64 bytes reached?
        bne     loop            ; Branch if not

        jmp     $F400           ; Done, back to monitor
