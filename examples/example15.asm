; Example 15 - ACIA Memory Load/Dump Program

        nam     ldboot
        cpu     6800

; This program loads or dumps memory
; Place start address in loc 00 & 01
; Place end address + 1 in loc 02 % 03
; If error occurs, check loc 04 & 05 for address.
; CA2 stops drive at EOT or error.
; CB2 gives error indication.
; Dump program starts at loc 094B.

pia1ac  =       $0805
pia1bc  =       $0807
aciac   =       $0806
aciad   =       $0809

        * = $0900

        ldaa    #$03
        staa    aciac   ; ACIA master reset
        ldx     $00     ; load start address
        ldaa    #$19    ; ACIA 8 bits even parity
        staa    aciac
loop    ldaa    aciac
        rora
        bcc     loop    ; receiver full?
        ldaa    aciad
cmpaa   cmpa    #$AA    ; is first char "AA"?
        bne     loop    ; branch if not
loop1   ldaa    aciac
        rora
        bcc     loop1
        ldaa    aciad
        cmpa    #$55    ; is second char "55"?
        bne     cmpaa   ; if not, try for an "AA"
loop2   ldaa    aciac
        tab             ; transfer A to B
        andb    #$70
        bne     error   ; branch if error
        rora
        bcc     loop2
        ldaa    aciad   ; load a char from tape
        staa    0,x     ; store in memory
        inx             ; increment address
        cpx     $02     ; load completed?
        bne     loop2   ; go get more
end     ldaa    #$30
        staa    pia1ac  ; turn off CA2
        bra     *
error   ldaa    #$36
        staa    pia1bc  ; turn on error light
        stx     $04     ; store adr of error
        bra     end

        ldx     $00     ; start of dump program
        ldaa    #$19
        staa    aciac
        ldaa    #$AA    ; output control char
        staa    aciad
loop5   ldaa    aciac
        rora
        rora
        bcc     loop5   ; xmit buffer empty?
        ldaa    #$55    ; output second control char
        staa    aciad
loop6   ldaa    aciac
        rora
        rora
        bcc     loop6   ; xmit buffer empty?
loop4   ldaa    0,x
        staa    aciad   ; output char to tape
loop3   ldaa    aciac
        rora
        rora
        bcc     loop3   ; xmit buffer empty?
        inx
        cpx     $02
        bne     loop4
        bra     end
