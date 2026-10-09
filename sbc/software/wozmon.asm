; a1mon68: a rewrite of the Apple 1 monitor to run on an MC6800
; microprocessor, rather than the MCS6502 microprocessor that
; was standard.

; Copyright 2011 Eric Smith <spacewar@gmail.com>

; This source code will assemble with the AS Macro Assembler:
;   http://john.ccac.rwth-aachen.de:8000/as/
; With minor changes it should assemble with any MC6800 assembler.

; This program is free software; you can redistribute and/or modify it
; under the terms of the GNU General Public License version 3 as
; published by the Free Software Foundation.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;	
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

            cpu 6800
            output hex

xam         equ $0024       ; two bytes
st          equ $0026       ; two bytes
h           equ $0028
l           equ $0029

mode        equ $002b
ysav        equ $002c       ; two bytes
inptr       equ $002e       ; two bytes

in	    equ $0200

kbd	    equ $d010
kbd_cr	    equ $d011
dsp	    equ $d012
dsp_cr	    equ $d013

	    * = $ff00

reset:      ; cld           ; No decimal mode on 6800, so we don't need
	                    ;  need to clear it.
	    ; cli           ; Disable interrupts - not actually needed on reset.
	    ldab #$7f	    ; Mask for DSP data direction register.
	    stab dsp	    ; Set it up.
	    ldab #$a7	    ; KBD and DSP control register mask.
	    stab kbd_cr	    ; Enable interrupts, set CA1, CB1, for
	    stab dsp_cr	    ;  positive edge sense/output mode.
	    lds  #$01ff	    ; On the 6502, the monitor didn't initialize the
	    	 	    ;  stack pointer, which was OK because it was
			    ;  guaranteed to be somewhere in page 1. Not so
			    ;  on the 6800!
			    ; Ideally, I'd take advantage of the stack
			    ;  starting right before the input buffer to
			    ;  save a few bytes, but I haven't yet figured
			    ;  out how to do it.

; Note that B contains $a7 here, which means that the incb below will
; set the negative flag, causing the bpl to fall through into escape.
; This saves us a "bra escape" instruction here.

; Get a line of input from the keyboard, echoing to display.
; Normally enter at escape or getline.

notcr 	    cmpa #$df	    ; "_"?  [NB back arrow]
	    beq  backspace  ; Yes.
	    cmpa #$9b	    ; ESC?
	    beq  escape	    ; Yes.
	    inx  	    ; Advance text index.
	    incb
	    bpl  nextchar   ; Auto ESC if > 127.

escape      ldaa #$dc	    ; "\".
	    jsr  echo	    ; Output it.

getline     ldaa #$8d	    ; CR.
	    jsr  echo	    ; Output it.
	    ldx  #in+1	    ; Initiallize [sic] text index.
	    ldab #1
backspace   dex	            ; Back up text index.
	    decb
	    bmi  getline    ; Beyond start of line, reinitialize.

nextchar    ldaa kbd_cr	    ; Key ready?
	    bpl  nextchar   ; Loop until ready.
	    ldaa kbd	    ; Load character. B7 should be '1'.
	    staa ,x         ; Add to text buffer.
	    bsr  echo	    ; Display character.
	    cmpa #$8d	    ; CR?
	    bne  notcr	    ; No.

; Process an input line.

cr	    ldx  #in+256-1  ; Reset text index to in-1, +256 so that
                            ;  'inc inptr+1' will result in $0200.
	    stx  inptr
	    clra	    ; For XAM mode. 0->B.

setblok     asla	    ; Leaves $56 if setting BLOCK XAM mode.
setmode     staa mode	    ; $00 = XAM, $BA = STOR, $56 = BLOK XAM.
blskip	    inc  inptr+1    ; Advance text index.
nextitem    ldx  inptr
            ldaa ,x         ; Get character.
	    cmpa #$8d	    ; CR?
	    beq  getline    ; Yes, done this line.
	    cmpa #$ae	    ; "."?
	    beq  setblok    ; Set BLOCK XAM mode.
	    bls  blskip	    ; Skip delimiter.
	    cmpa #$ba	    ; ":"?
	    beq  setmode    ; Yes, set STOR mode.
	    cmpa #$d2	    ; "R"?
	    beq  run	    ; Yes, run user program.
	    clr  l	    ; $00->L.
	    clr  h	    ;  and H.
	    stx  ysav	    ; Save Y for comparison.

nexthex     ldx  inptr
            ldaa ,x         ; Get character for hex test.
	    eora #$b0	    ; Map digits to $0-9.
	    cmpa #$09	    ; Digit?
	    bls  dig	    ; Yes.
	    adda #$89	    ; Map letter "A"-"F" to $FA-FF.
	    cmpa #$f9	    ; Hex letter?
	    bls  nothex	    ; No, character not hex.

dig 	    asla            ; Hex digit to MSD of A.
	    asla
	    asla
	    asla

	    ldab #$04       ; Shift count.
hexshift    asla            ; Hex digit left, MSB to carry.
	    rol  l	    ; Rotate into LSD.
	    rol  h	    ; Rotate into MSD's.
	    decb 	    ; Done 4 shifts?
	    bne  hexshift   ; No, loop.

	    inc  inptr+1    ; Advance text index.
	    bra  nexthex    ; Always taken. Check next character for hex.

nothex 	    cpx  ysav	    ; Check if L, H empty (no hex digits).
	    beq  escape	    ; Yes, generate ESC sequence.
	    tst  mode	    ; Test MODE byte.
	    bpl  notstor    ; B6=0 for STOR, 1 for XAM and BLOCK XAM

; STOR mode
	    ldx  st
	    ldaa l	    ; LSD's of hex data.
            staa ,x	    ; Store at current 'store index'.
	    inx
	    stx  st
tonextitem  bra nextitem    ; Get next command item.

prbyte	    psha 	    ; Save A for LSD.
	    lsra
	    lsra
	    lsra	    ; MSD to LSD position.
	    lsra
	    bsr  prhex	    ; Output hex digit.
	    pula	    ; Restore A.
prhex	    anda #$0f	    ; Mask LSD for hex print.
	    oraa #$b0	    ; Add "0".
	    cmpa #$b9	    ; Digit?
	    bls  echo	    ; Yes, output it.
	    adda #$07	    ; Add offset for letter.
echo	    tst  dsp	    ; DA bit (B7) cleared yet?
	    bmi  echo	    ; No, wait for display.
	    staa dsp	    ; Output character. Sets DA.
	    rts		    ; Return.

run         ldx  xam
	    jmp  ,x	    ; Run at current XAM index.

notstor     bne  xamnext    ; mode = $00 for XAM, $56 for BLOCK XAM.

	    ldx  h	    ; Copy hex data to
	    stx  st	    ;  'store index'.
	    stx  xam	    ; And to 'XAM index'.
	    clra	    ; set Z flag to force following branch.

nxtprnt     bne  prdata	    ; NE means no address to print.
	    ldaa #$8d	    ; CR.
	    bsr  echo	    ; Output it.
	    ldaa xam	    ; 'Examine index' high-order byte.
	    bsr  prbyte	    ; Output it in hex format.
	    ldaa xam+1	    ; Low-order 'Examine index' byte.
	    bsr  prbyte	    ; Output it in hex format.
	    ldaa #$ba	    ; ":".
	    bsr  echo	    ; Output it.

prdata      ldaa #$a0	    ; Blank.
	    bsr  echo	    ; Output it.

	    ldx  xam
	    ldaa ,x         ; Get data byte at 'examine index'.
	    bsr  prbyte	    ; Output it in hex format.

xamnext     clr  mode	    ; 0->MODE (XAM mode).
	    ldx  xam	    ; Compare 'examine index' to hex data.
	    cpx  h
	    beq  tonextitem ; Not less, so more data to output.
	    inx
	    stx  xam
            ldaa xam+1	    ; Check low-order 'examine index' byte
	    anda #$07	    ;  For MOD 8 = 0
	    bra  nxtprnt    ; always taken

            * = $FFF8       ; vector table
	    dw  $0000	    ; IRQ
	    dw  $0000	    ; SWI
	    dw $f000	    ; NMI
	    dw	$ff00	    ; RESET
