; Example 3 - Program to Clear Locations 00 Through Hex FF

        nam     clm
        cpu     6800
        * = $500
        ldx     #0
        clra
again   staa   0,x
        inx
        cpx     #$100
        bne     again
