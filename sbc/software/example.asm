; Sample program for testing S record download from monitor.
; Does nothing useful.

        CPU 6800
        OUTPUT SCODE            ; For Motorola S record (RUN) output

        * EQU $1000

start   nop
        clc
        ldaa    #$01
        ldab    #$02
        ldx     #$0010          ; Loop counter
loop    dex
        bne     loop
        rts
