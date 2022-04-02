; Example or programmming real-time clock using a DS1216E SmartWatch
; ROM AKA No-Slot Clock. Install a DS1216E in the EPROM socket.
;
; Notes:
;
; In docs READ/WRITE refers to level of A2.
; Sequence:
; 1. One cycle with A2 high to reset.
; 2. Enable with 64 cycles with A2 low and A1 set by pattern.
; 3. To read registers:
;     64 read cycles, A2 high, data returned in D0
; 3.  To write registers:
;     64 read cycles, A2 low, data set by A0
;
; Pattern: C5 3A A3 5C C5 3A A3 5C

        CPU     6800
        OUTPUT  SCODE           ; For Motorola S record (RUN) output

MONITOR equ     $F400           ; Start address of monitor
ROM     equ     $C000           ; Start address of ROM/DS1316E
BUFFER  equ     $2000           ; Buffer for clock data

        * EQU   $1000

; Example read:

        ldaa    ROM+4           ; Reset the sequence
        ldx     #pattern        ; Get pointer to pattern byte
l2      clrb                    ; Shift count
        ldaa    0,x             ; Get byte of pattern
L1      lsra                    ; Shift LSB into carry
        bcs     one
        tst     ROM             ; Zero bit pattern
        bra     shift
one     tst     ROM+1           ; One bit pattern
shift   incb                    ; Increment shift count
        cmpb    #8              ; Shifted 8 times?
        bne     l1              ; If not, go back and continue
        inx                     ; Increment pointer to next byte in pattern
        cpx     #pattern+8      ; Last byte reached?
        bne     l2              ; If not, go back and contine

; Now read 64 register bits using 64 reads.
; A2 must be high, data is in D0

        ldx     #BUFFER         ; Start of data buffer
loop    ldaa    ROM+4           ; Get data
        staa    0,X             ; Save in buffer
        inx                     ; Advance buffer
        cpx     #ROM+64         ; 64 bytes reached?
        bne     loop            ; Branch if not

        jmp     MONITOR         ; Done, back to monitor

pattern DB      $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C
