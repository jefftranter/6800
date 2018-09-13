; Example 8 - Program to Subtract Absolute Values of Two

        nam     ams
        cpu     6800
        * = $0000
w       ds      1
y       ds      1
z       ds      1
        * = $0500
        ldaa    w
        bpl     z1      ; is w positive?
        nega            ; w was neg, make pos
z1      ldab    y
        bpl     z2      ; is y positive?
        negb            ; y was neg, make pos
z2      sba             ; subtract y from w
        bgt     z3      ; is z positive?
        clra            ; result was zero or neg.
z3      staa    z       ; store answer in z
        bra     *
