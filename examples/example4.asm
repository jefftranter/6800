; Example 4 - Load Memory with a Data Table (Ascending)

        nam     stt
        cpu     6800
        * = $500
        ldx     #0
        clra
next    staa    0,x
        inca
        inx
        cpx     #$100
        bne     next

        
