; Example 9 - Multiplication Subroutine

        nam     cmult
        cpu     6800
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; REV 003 11-10-75 BAINTER
;
; This subroutine multiplies two 8 bit bytes.
; The multiplicand is stored in byte nb1.
; The multiplier is stored in byte nb2.
; The result is stored in bytes ans2 and ans1.
; Ans2 is the upper byte of the result.
; Ans1 is the lower byte of the result.

        * = $0000
nb1a    ds      1       ; shift multiplicand store
nb1     ds      1       ; multiplicand
nb2     ds      1       ; multiplier
ans2    ds      1       ; upper byte of result
ans1    ds      1       ; lower byte of result

        * = $0010
mult    clra            ; clear answer & shift areas
        staa    nb1a
        staa    ans1
        staa    ans2
        ldaa    nb2     ; nb2 = multiplier
        bra     loop1

loop2   asl     nb1     ; shift multiplicand left
        rol     nb1a    ; upper byte of multiplicand
loop1   lsra            ; shift multiplier right
        bcc     noadd   ; shift and don't add
        ldab    ans1    ; add shifted multiplicand
        addb    nb1     ; to ans1 and ans2.
        stab    ans1    ; lower byte of result
        ldab    ans2
        adcb    nb1a    ; add with carry
        stab    ans2    ; upper byte of result
        tsta
noadd   bne     loop2   ; start shifting again
        rts             ; finished!
