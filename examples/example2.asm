; Example 2 - Program to Clear Nine Memory Locations

        nam     clm
        cpu     6800
        * = $500
        ldx     #$70
 l1     clr     0,x
        inx
        cpx     #$79
        bne     l1
