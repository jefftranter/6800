; Example 1 - Add Four Numbers Program

        nam     add4nr
        cpu     6800
        * = $000A
temp    ds      1
        ldaa    #25
        adda    #35
        adda    #$32
        adda    #%10001
        staa    temp
