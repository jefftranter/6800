; Example 7 - Program to Move a Constant

        nam     ltr1
        cpu     6800
        * = $6A
temp    ds      1
        * = $0800
start   ldaa    #$7F    ; Start of program
        staa    $50
        ldab    $50
        stab    $0113
        ldaa    $0113
        staa    temp
        jmp     start
