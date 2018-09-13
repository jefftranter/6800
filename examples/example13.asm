; Example 13 - Time Delay Program (Long Delay)

        nam     ltc
        cpu     6800

        * = $3000
loop1   ldaa    #4
loop2   ldx     #$FFFF
agn     dex
        bne     agn
        deca
        bne     loop2
