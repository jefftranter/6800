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

; Set the initial time by writing the current hours, minutes, and
; seconds (in BCD) to addresses $0000, $0001, $0002 repectively. Then
; run from address $004. Don't connect the jumper wire until you have
; entered the program.

; Written by Jeff Tranter <tranter@pobox.com>

        CPU 6800

        REDIS   EQU $FCBC
        DSPLAY  EQU $FD7B

        * = $0000

HOUR    DS      1       ; Hour (1-12) in BCD
MINUTE  DS      1       ; Minute (0-59) in BCD
SECOND  DS      1       ; Second (0-59) in BCD
JIFFY   DS      1       ; 60ths of a second (in BCD)

; TODO: Add options for 12 or 24 hour time.

; Main program. Simply displays the hours, minutes and seconds that
; are updated by the interrupt handler routine.

; TODO: Prompt user to enter the current time on startup.

START   JSR    REDIS   ; Reset display address
        LDAB   #3      ; Number of bytes to display
        LDX    #HOUR   ; Address of bytes to output
        LDAA   SECOND  ; Get current seconds
        PSHA           ; Save it on stack
        JSR    DSPLAY  ; Display time
        PULA           ; Restore seconds

; Wait for seconds to change before updating display again.

WAIT    CMPA   SECOND  ; Did seconds change from last value?
        BEQ    WAIT    ; If not, keep waiting
        BRA    START   ; Repeat forever

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
        CMPA    #$13    ; Did we reach 13?
        BLT     RET     ; No, then done
        LDAA    #1      ; Reset hour to 1
        STAA    HOUR    ; Save it
RET     RTI             ; Return from interrupt

; Note that in the Monitor ROM the NMI vector at $FFFC,D points to
; $00FD, which is in RAM. We add a jump there to the interrupt
; handler.

        * = $00FD       ; Address of NMI handler
        JMP INT         ; Call interrupt handler
