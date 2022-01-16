This is a port of software to my 6800-based single board computer:

- The keypad-based monitor program from the Heathkit ET-3400 and
  ET-6800 Microprocessor Trainers.

- The serial monitor (Fantom II) from the Heathkit ETA-3400 memory I/O
  accessory.

- Pittman Tiny Basic from the Heathkit ETA-3400 memory I/O accessory.

All will fit in the 6800 SBC EPROM.

Keypad monitor - run on reset.
Serial monitor - start address E400.
Tiny Basic - start address EC00.

PROGRAM         ADDRESSES
--------------  ---------
Monitor         FC00-FFFF
Unused          F400-FBFF
Tiny Basic      EC00-F3FF
Serial Monitor  E400-EBFF
Unused          C000-E3FF
