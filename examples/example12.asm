; Example 12 - Time Delay Program (Short Delay)

        nam     tmr
        cpu     6800

        * = $8000
        ldaa    #$FF
dagn    deca
        bne     dagn
