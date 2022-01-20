This is a port of software to my 6800-based single board computer:

- The keypad-based monitor program from the Heathkit ET-3400 and
  ET-6800 Microprocessor Trainers.

- The serial monitor (Fantom II) from the Heathkit ETA-3400 memory I/O
  accessory. Uses the PIA serial port.

- The Motorola MiniBug serial monitor. Uses the ACIA serial port.

- The Motorola MikBug serial monitor. Uses the ACIA serial port.

- Pittman Tiny Basic from the Heathkit ETA-3400 memory I/O accessory.
  Uses the PIA serial port.

- A port of Microsoft Basic for the Altair 680 computer.

All will fit in the 16K 6800 SBC EPROM.

Program     Size        Addresses  Start
----------  ----        ---------  ----
Monitor     0400 (1K)   FC00-FFFF  FC00 or reset
MiniBug     0100 (256)  FB00-FBFF  FBD6
MikBug      0200 (512)  F900-FAFF  F9D0
Unused      0500 (1.3K) F400-F8FF
Tiny Basic  0800 (2K)   EC00-F3FF  EC00
Fantom II   0800 (2K)   E400-EBFF  E400
Unused      2500 (9.5K) C000-E3FF
