This is a port of software to my 6800-based single board computer:

- The keypad-based monitor program from the Heathkit ET-3400 and
  ET-6800 Microprocessor Trainers.

- The serial monitor (Fantom II) from the Heathkit ETA-3400 memory I/O
  accessory. Uses the PIA serial port.

- The Motorola MiniBug serial monitor. Uses the ACIA serial port.

- The Motorola MikBug serial monitor. Uses the ACIA serial port.

- Pittman Tiny Basic from the Heathkit ETA-3400 memory I/O accessory.
  Uses the PIA serial port.

- A 6800 disassembler. Uses the ACIA serial port.

- A port of TSC Micro BASIC PLUS. Uses the ACIA serial port.

- A port of Microsoft MITS Altair 680 BASIC Version 1.1 rev 3.2.

The programs will fit in the 16K 6800 SBC EPROM as below:

ROM Image all1.bin:

Program             Size        Addresses  Start
----------          ----        ---------  ----
Monitor             0400 (1K)   FC00-FFFF  FC00 or reset
MiniBug             0100 (256)  FB00-FBFF  FBD6
MikBug              0200 (512)  F900-FAFF  F9D0
Fantom II (ACIA)    0500 (1.3K) F400-F8FF  F400
Tiny Basic          0800 (2K)   EC00-F3FF  EC00
Fantom II (PIA)     0800 (2K)   E400-EBFF  E400
Disassembler (ACIA) 1000 (4K)   D000-DFFF  D000
TSC Basic           1000 (4K)   C000-CFFF  C000

ROM Image all2.bin:

Program             Size        Addresses  Start
----------          ----        ---------  ----
Monitor             0400 (1K)   FC00-FFFF  FC00 or reset
MiniBug             0100 (256)  FB00-FBFF  FBD6
MikBug              0200 (512)  F900-FAFF  F9D0
Fantom II (ACIA)    0500 (1.3K) F400-F8FF  F400
Tiny Basic          0800 (2K)   EC00-F3FF  EC00
Fantom II (PIA)     0800 (2K)   E400-EBFF  E400
Microsoft Basic     1000 (4K)   C000-DFFF  CDF00

MONITOR:

By default on reset it runs the monitor from the Heathkit
ET-3400/ET-6800. This uses the 7-segment LEDs and keypad switches. See
the Heathkit manuals for more details.

FANTOM II Monitor (PIA):

This monitor came from the Heathkit ETA-3400 and uses a serial
interface.

Set jumpers for PIA serial interface and desired baud rate and start
using: RESET DO E400.

Here is a summary of the commands. See the Heathkit manuals for more
details.

```
M      - Display/Change Memory
I      - Display/Change Instruction
R      - Display MPU Registers
Ctl-A  - Display/Change Accumulator A
Ctl-B  - Display/Change Accumulator B
Ctl-C  - Display/Change Condition Codes Register
Ctl-P  - Display/Change Program Counter
Ctl-X  - Display/Change Index Register
G      - Go To User Program
S      - Single Step User Program
D      - Dump Memory
P      - Punch loader Compatible Tape
L      - Load Memory
B      - Go to BASIC Warm start
```

FANTOM II Monitor (ACIA):

This is a version of the FANTOM II montor above that uses the ACIA for
serial i/o.

Set jumpers for ACIA serial interface, set serial port settings to
115200 8N1, and start using: RESET DO F400.

TINY BASIC:

This is the Pitman Tiny Basic from the Heathkit ETA-3400. From the
FANTOM II PIA monitor, start Tiny Basic by typing G EC00. See the
Heathkit manuals for more details.

MINIBUG:

This is a port of Motorola's MINIBUG monitor and uses a serial interface.

Set jumpers for ACIA serial interface, set serial port settings to
115200 8N1, and start using: RESET DO FBD6.

Here is a summary of the commands. See the Motorola manual for more
details.

Load paper tape file in S record format:

L

Display and optionally change memory:

M <hex address> <byte> or <CR>

Display registers (CC, B, A, XH, XL, PH, PL, SH, SL):

P

Registers can be changed writing to memory locations starting from
0129 as listed below:

```
0129  CCR
012A  B
012B  A
012C  XH
012D  XL
012E  PCH
012F  PCL
````

Go (with registers set as above):
G

MIKBUG:

This is a port of Motorola's MIKBUG monitor and uses a serial interface.

Set jumpers for ACIA serial interface, set serial port settings to
115200 8N1, and start using: RESET DO F9D0.

Here is a summary of the commands. See the Motorola manual for more
details.

Load paper tape file in S record format:

L

Display and optionally change memory:

M <hex address> <byte> or <CR> <byte>


Output paper tape file (Start address in A002,3 and end address
in A004,5):

P

Display registers (CCR, B, A, X, PC, SP):

R

Registers can be changed writing to memory locations starting from
0143 as listed below:

```
0143  CCR
0144  B
0145  A
0146  XH
0107  XL
0148  PCH
0149  PCL
014A  SPH
014B  SPL
````

Go (with registers as above):

G

DISASSEMBLER:

Run from address D000 from the Fantom II (ACIA) monitor or the front
panel using: RESET DO D000.

Use should be self-explanatory. Enter a hex start address, press
<SPACE> to see a page of output, A to enter a new start address, and X
to go to the Fantom II (ACIA) monitor. Sample output is below:

6800 Disassembler ver 1.0 by Jeff Tranter
Start Address? FB00
FB00  B6 83 00  LDAA $8300
FB03  47        ASRA 
FB04  24 FA     BCC  $FB00
FB06  B6 83 01  LDAA $8301
...
FB27  86 15     LDAA #$15
FB29  B7 83 00  STAA $8300
FB2C  86 11     LDAA #$11
FB2E  8D 7E     BSR  $FBAE
<SPACE> to continue, A for new address, X to exit 

TSC MICRO BASIC

A port of TSC Micro BASIC PLUS. The language is pretty limited as
compared to other BASICs (e.g. integer math only, no string
variables).

Run from address C000 from the Fantom II (ACIA) monitor or the front
panel using: RESET DO C000.

The MONITOR command jumps to the Fantom II monitor. A running program
can be interrupted with Control-C.

Instruction Summary:

Commands: LIST MONITOR RUN SCRATCH

Statements: DATA DIM END EXTERNAL FOR GOSUB GOTO IF INPUT LET NEXT ON PRINT READ REM RESTORE RETURN THEN

Functions: ABS RND SGN SPC TAB

Math Operators: - + * / ^

Relational Operators: = < > <= >= <>

Other:

Line Numbers: 0 to 9999
Constants: -99999 to +99999
Variables: single letters, A to Z, may be subscripted
Backspace: Control-H
Line cancel: Control-X

Error Codes:

10 Unrecognizable keyword
14 Illegal variable
16 No line number referenced by GOTO or GOSUB
20 Expression syntax, unbalanced parens, or dimension error
21 Expression expected but not found
22 Divided by zero
23 Arithmetic overflow
24 Expression too complex
31 Syntax error in PRINT statement
32 Missing closing quote in printed string
40 Bad DIM statement
45 Syntax error in INPUT statement
51 Syntax error in READ statement
62 Syntax error in IF statement
73 RETURN with no GOSUB
81 Error with FOR-NEXT
90 Memory overflow
99 "BREAK" detected

MICROSOFT BASIC

A port of the full featured (e.g. floating point) Microsoft Basic
originally for the MITS Altair 680 computer.

Run from address DF00 from the Fantom II (ACIA) monitor or the front
panel using: RESET DO DF00.

At the "MEMORY SIZE?" prompt, press <Enter> to use all available
memory or a smaller number to use less memory.

At the "TERMINAL WIDTH?" prompt press <Enter> for the default line
width or a number to specify a line width.

At the "WANT SIN-COS-TAN-ATN?" prompt select "Y" to include the trig
functions or "N" to omit them and free up 240 bytes of memory.
