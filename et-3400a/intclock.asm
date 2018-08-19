        NAM Intclock
        PAGE 66,132

;      Interrupt-Driven Clock Example

; This program implements an interrupt-driven clock program. It uses
; the NMI interrupt connected to the LINE signal to count time. This
; makes it much more accurate than a timing delay loop (like Example
; 6), as the line frequency is very accurate over long periods of
; time. In order for this to work you need to connect a jumper wire
; from the LINE signal to the NMI* signal. The causes an interrupt to
; occur every 60th of a second. Note that we could use the 1Hz signal,
; but it is driven by an RC oscillator which is not very stable or
; accurate.

; Run the program from address START. It will first wait for you to
; enter the current hours and minutes (as two digit numbers). Then the
; time will be displayed. Don't connect the jumper wire until you have
; entered the program. You can start (or restart) the program at entry
; point LOOP if you want to use the current time values and not prompt
; the user for the time.

; Written by Jeff Tranter <tranter@pobox.com>

        CPU 6800

; Monitor routines

        REDIS   EQU $FCBC
        DSPLAY  EQU $FD7B
        IHB     EQU $FE09

; Set this to one this if you want a 24-hour clock (0-24 hours).
; Leave it set to zero for 12-hour time (1-12).
        TWENTYFOURHOUR = 0

        * = $0000

HOUR    DS      1       ; Hour (1-12) in BCD (0-23 in 24-hour mode)
MINUTE  DS      1       ; Minute (0-59) in BCD
SECOND  DS      1       ; Second (0-59) in BCD
JIFFY   DS      1       ; 60ths of a second (in BCD)

; Main program. Simply displays the hours, minutes and seconds that
; are updated by the interrupt handler routine.

START   JSR    REDIS   ; Reset display address
        JSR    IHB     ; Get hours from user (assume it is in range)
        STAA   HOUR    ; Save it
        JSR    IHB     ; Get minutes from user (assume it is in range)
        STAA   MINUTE  ; Save it
        CLR    SECOND  ; Set seconds to zero
LOOP    JSR    REDIS   ; Reset display address
        LDAB   #3      ; Number of bytes to display
        LDX    #HOUR   ; Address of bytes to output
        LDAA   SECOND  ; Get current seconds
        PSHA           ; Save it on stack
        JSR    DSPLAY  ; Display time
        PULA           ; Restore seconds

; Wait for seconds to change before updating display again.

WAIT    CMPA   SECOND  ; Did seconds change from last value?
        BEQ    WAIT    ; If not, keep waiting
        BRA    LOOP    ; Repeat forever

; NMI Interrupt handler routine. Called 60 times per second. It
; increments the jiffies, seconds, minutes, and hours, clearing and
; rolling over as needed.

INT     LDAA    JIFFY   ; Get 60ths of a second
        ADDA    #1      ; Add one
        DAA             ; Convert to BCD
        STAA    JIFFY   ; Save it
        CMPA    #$60    ; Did we reach 60?
        BLT     RET     ; No, then done
        CLR     JIFFY   ; Set jiffies to zero
        LDAA    SECOND  ; Get Seconds
        ADDA    #1      ; Add one
        DAA             ; Convert to BCD
        STAA    SECOND  ; Save it
        CMPA    #$60    ; Did we reach 60?
        BLT     RET     ; No, then done
        CLR     SECOND  ; Set seconds to zero
        LDAA    MINUTE  ; Get minutes
        ADDA    #1      ; Add one
        DAA             ; Convert to BCD
        STAA    MINUTE  ; Save it
        CMPA    #$60    ; Did we reach 60?
        BLT     RET     ; No, then done
        CLR     MINUTE  ; Set minutes to zero
        LDAA    HOUR    ; Get hours
        ADDA    #1      ; Add one
        DAA             ; Convert to BCD
        STAA    HOUR    ; Save it
        if TWENTYFOURHOUR
        CMPA    #$24    ; Did we reach 24?
        else
        CMPA    #$13    ; Did we reach 13?
        endc
        BLT     RET     ; No, then done
        if TWENTYFOURHOUR
        LDAA    #0      ; Reset hour to 0
        else
        LDAA    #1      ; Reset hour to 1
        endc
        STAA    HOUR    ; Save it
RET     RTI             ; Return from interrupt

; Note that in the Monitor ROM the NMI vector at $FFFC,D points to
; $00FD, which is in RAM. We add a jump there to the interrupt
; handler.

        * = $00FD       ; Address of NMI handler
        JMP INT         ; Call interrupt handler
