; Example of programmming real-time clock using a DS1216E SmartWatch
; ROM AKA No-Slot Clock. Install a DS1216E in the EPROM socket.
;
; Notes:
;
; In docs READ/WRITE refers to level of A2.
; Sequence:
; 1. One cycle with A2 high to reset.
; 2. Enable with 64 cycles with A2 low and A1 set by pattern.
; 3. To read registers:
;     64 read cycles, A2 high, data returned in D0.
; 3.  To write registers:
;     64 read cycles, A2 low, data set by A0.

        CPU     6800
        OUTPUT  SCODE           ; For Motorola S record (RUN) output

MONITOR equ     $F400           ; Start address of monitor
ROM     equ     $C000           ; Start address of ROM/DS1316E
BUFFER  equ     $2000           ; Buffer for clock data

        * EQU   $1000

; Unlock clock

        ldaa    ROM+4           ; Reset the sequence
        ldx     #pattern        ; Get pointer to pattern byte
l2      clrb                    ; Clear shift count
        ldaa    0,x             ; Get byte of pattern
l1      lsra                    ; Shift LSB into carry
        bcs     one
        tst     ROM             ; Zero bit pattern
        bra     shift
one     tst     ROM+1           ; One bit pattern
shift   incb                    ; Increment shift count
        cmpb    #8              ; Shifted 8 times?
        bne     l1              ; If not, go back and continue
        inx                     ; Increment pointer to next byte in pattern
        cpx     #pattern+8      ; Last byte reached?
        bne     l2              ; If not, go back and continue

; Now read 64 register bits using 64 reads.
; A2 must be high, data is in D0.

        ldx     #BUFFER         ; Start of data buffer
o2      clr     0,x             ; Initially clear byte
        clrb                    ; Clear shift count
o1      ldaa    ROM+4           ; Get data
        anda    #$01            ; Mask out all bits except D0
        asla                    ; Shift bit 0 into bit 7
        asla
        asla
        asla
        asla
        asla
        asla
        lsr     0,x             ; Shift previous buffer contents to the right
        oraa    0,x             ; Set bit 7 of buffer byte based on data bit
        staa    0,x             ; Save in buffer
        incb                    ; Increment shift count
        cmpb    #8              ; Shifted 8 times?
        bne     o1              ; If not, go back and continue
        inx                     ; Increment pointer to next byte in pattern
        cpx     #BUFFER+8       ; Last byte reached?
        bne     o2              ; If not, go back and continue
;       jmp     MONITOR         ; Done, back to monitor

        ldaa    #$11            ; Need /RST bit to be 1 and /OSC to be 0.
        staa    $2004

; Now write 64 register bits using 64 reads.
; A2 must be low, data is set by A0.

        ldx     #BUFFER         ; Get pointer to data bytes
m2      clrb                    ; Clear shift count
        ldaa    0,x             ; Get byte of pattern
m1      lsra                    ; Shift LSB into carry
        bcs     wone
        tst     ROM             ; Zero bit pattern
        bra     shift2
wone    tst     ROM+1           ; One bit pattern
shift2  incb                    ; Increment shift count
        cmpb    #8              ; Shifted 8 times?
        bne     m1              ; If not, go back and continue
        inx                     ; Increment pointer to next byte in pattern
        cpx     #BUFFER+8       ; Last byte reached?
        bne     m2              ; If not, go back and continue

        jmp     MONITOR         ; Done, back to monitor

; Enable pattern
pattern DB      $C5, $3A, $A3, $5C, $C5, $3A, $A3, $5C
