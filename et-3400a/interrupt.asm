        NAM Interrupt Example
        PAGE 132,66

;      Interrupt Example

; This program demonstrates interrupt handling. Do the following using
; the ET-3400 keyboard:

; - Enter the code starting at address $0010 and at $00FD
; - write $00 to addresses $0000 and $0001
; - connect a jumper wire from the 1Hz signal to the NMI* signal

; An NMI interrupt will be performed once every second.
; Examine the contents of addresses $0000 and $0001 and observe
; that the value is increasing one per second.

; Now connect the jumper from the LINE signal to the NMI* signal
; Now the counter value should be incremented 60 times per second.

; Note that there is no need to execute the program from the monitor.
;
; Written by Jeff Tranter <tranter@pobox.com>

        CPU 6800

COUNT   = $0000         ; Count of interrupts

        * = $0010

; Interrupt handler routine

INT     LDX COUNT       ; Get current count (16-bit)
        INX             ; Increment it
        STX COUNT       ; Save it
        RTI             ; Return from interrupt

; Note that in the Monitor ROM the NMI vector at $FFFC,D points to
; $00FD, which is in RAM.

        * = $00FD       ; Address of HMI handler
        JMP INT         ; Call interrupt handler
