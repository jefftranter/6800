; Example 6 - Move $80 Bytes of Data

        nam     mov
        cpu     6800
        * = $500
        ldx     #0
more    ldaa    0,x
        inx
        staa    $FF,x
        cpx     #$80
        bne     more

