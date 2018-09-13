; Example 5 - Load Memory with a Data Table (Descending)

        nam     stt
        cpu     6800
        * = $500
        ldaa    #$FF
        ldx     #0
again   staa    0,x
        inx
        deca
        bne     again
        staa    $FF
