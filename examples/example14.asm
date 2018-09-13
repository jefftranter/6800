; Example 14 - Binary to BCD Conversion Program

        nam     dwa21
        cpu     6800

        * = $0000       ; initial binary number
msb     ds      1       ; most significant 8 bits
lsb     ds      1       ; least significant 8 bits

        * = $0010       ; BCD results
untten  ds      1       ; units and tens digits
hndthd  ds      1       ; hundreds and thousands
tentsd  ds      1       ; tens of thousands digit

        * = $0F00       ; **beginning of program**
        clr     untten
        clr     hndthd
        clr     tentsd
        ldx     #$0010
begin   ldaa    untten  ; units comparison
        tab
        anda    #$0F
        suba    #$05
        bmi     at
        addb    #$03
at      tba             ; tens comparison
        anda    #$F0
        suba    #$50
        bmi     bt
        addb    #$30
bt      stab    untten
        ldaa    hndthd  ; hundreds comparison
        tab
        anda    #$0F
        suba    #$05
        bmi     ct
        addb    #$03
ct      tba
        anda    #$F0
        suba    #$50
        bmi     dt
        addb    #$30
dt      stab    hndthd
        ldaa    tentsd  ; tens of thousands comparison
        tab
        suba    #$05
        bmi     et
        addb    #$03
et      stab    tentsd
        asl     lsb
        rol     msb
        rol     untten
        rol     hndthd
        rol     tentsd
        dex
        bne     begin   ; end of conversion check
