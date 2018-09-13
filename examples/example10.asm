; Example 10 - System Program - BCD to LED

        nam     bcdled
        cpu     6800

        * = $0000
index   ds      2

        * = $0C00       ; PIA addresses
pia1ad  ds      1
pia1ac  ds      1
pia1bd  ds      1
pia1bc  ds      1

        * = $3F00       ; build table
table   db      $01, $4F, $12, $06, $4C, $24, $60, $0F, $00, $0C
        db      $30, $30, $30, $30, $30, $30 ; error inputs

        * = $3FFE
        dw      start   ; restart vector

        * = $3C00       ; begin program
start   ldaa    #$FF
        staa    pia1bd  ; B side all outputs
        ldaa    #%00000100
        staa    pia1ac
        staa    pia1bc
        ldx     #table  ; get starting adr of table
        stx     index
loop    ldaa    pia1ad  ; read BCD input
        anda    #%00001111 ; mask 4 msb
        staa    index+1
        ldx     index
        ldaa    0,x
        staa    pia1bd  ; output to LED
        bra     loop    ; do it again

