; Example 11 - Machine Control System Program

        nam     hyder
        cpu     6800

        * = $0000
eximp   ds      1       ; label RAM locations
count   ds      1
exout   ds      1
temp    ds      1

        * = $0080
piapa   ds      1
piaca   ds      1
piapb   ds      1
piacb   ds      1

        * = $8000
;;;;;;;;;;;;;;;;;;;;;;;;;begin restart routine;;;;;;;;;;;;;;;;;;;;;;;;;

restrt  lds     #$007F  ; load stack pointer
        clr     eximp
        clr     count   ; clear out RAM
        clr     exout
        clr     temp

        ldx     #$0007  ; set up PIA
        stx     piapa
        ldx     #$FF05
        stx     piapb

        cli

;;;;;;;;;;;;;;;;;;;;;;;;;begin executive routine;;;;;;;;;;;;;;;;;;;;;;;

exec    ldx     #table
contin  ldaa    eximp   ; set data from RAM
        cmpa    0,x     ; is there a match?
        beq     match
check   inx
        inx
        cpx     #endtab+2 ; end of table?
        bne     contin    ; no? continue
        bra     exec      ; yes? begin again

match   ldab    1,x       ; get data to output
        stab    exout     ; store it in RAM
        wai               ; nothing else to do
        bra     exec      ; return to exec loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Table follows: Form is: data byte followed
; by an output byte indicative of the output byte
; to be given to the piapb
;
table   dw      $0000, $0103, $0277, $0381, $4201, $A42F
        dw      $D311, $8B29, $FF11, $FEC8
endtab  dw      $4D88     ; end of table

;;;;;;;;;;;;;;;IRQ polling routine;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll    ldaa    piacb     ; get cb
        bmi     peak      ; Valley o peak interrupt?

;;;;;;;;;;;interrupt for valley (lights & inputs);;;;;;;;;;;;;;;;;;;;;;;

valley  ldaa    #$F0
        anda    exout     ; output 4 bits of light
        ldab    piapb     ; data only w/o changing
        andb    #$0F      ; motor outputs
        aba
        staa    piapb

        ldaa    piapa     ; inputs same as
        cmpa    temp      ; last time? Clear interrupt
        beq     same
        staa    temp      ; store new data
        clr     count     ; zero counter
        rti               ; go back to exec

same    ldab    #01       ; third time match?
        cmpb    count
        beq     goodin    ; if so, go to goodin
        inc     count     ; if not, just inc counter
        rti               ; and return

goodin  staa    eximp     ; put good data in RAM
        clr     count
        rti

;;;;;;;;;;;interrupt for peak (motor) outputs;;;;;;;;;;;;;;;;;;;;;;;;;;;

peak    ldaa    #$0F      ; output 4 bits of
        anda    exout     ; motor data w/o changing
        ldab    piapb     ; light data. Also clears int
        andb    #$F0
        aba
        staa    piapb
        rti

;;;;;;;;;;;optional NMI interrupt;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nmi     clr     piapb     ; turn off all outputs
hangup  nop
        bra     hangup    ; go to sleep

;;;;;;;;;;;set vectors in upper ROM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        * = $83F8
        dw      poll, $0000, nmi, restrt
