        CODE
        CPU 6800
        OUTPUT HEX                  ; For Intel hex output

; FILL UNUSED LOCATIONS WITH FF

*       EQU     $C000
        DS      $E400-*,$FF
