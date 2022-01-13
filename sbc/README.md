6800 Single Board Computer

This is a 6800-based single board computer design. It is still a work
in progress at the prototype stage and has not been tested. It has the
following features:

* 6802 CPU running at 0.88 (optionally 1.0) MHz
* 32K of RAM
* 16K of EPROM or EEPROM
* Hex keypad and 7-segment LED display interface
* Parallel interface using 6821 PIA (2 8-bit parallel ports)
* Serial interface using 6850 UART with TTL levels for FTDI USB serial adaptor
* Various power options: regulated 5VDC in (e.g. via USB), unregulated 7-15VDC in, unregulated 7-15AC in, or 120/220 VAC in via external AC adaptor (i.e. wall-wart)
* Address decoding using CPLD (Can adjust memory map by reprogramming CPLD)
* 60 Hz interrupt support if powered by AC input
* Expansion connector with all CPU bus signals
* Open Source hardware design using Kicad

The design is roughly based on the Heathkit ET-6800 CPU trainer with
additional features, some taken from the Heathkit ETA-3400 expander.
It can run a modified version of the ET-6800/ET-3400 firmware and in
future should run other firmware including a serial monitor and BASIC.

MEMORY MAP

```
+----------+-----------+----------+
| Function | Addresses | Comments |
+----------+-----------+----------+
| ROM      | C000-FFFF |   16K    |
+----------+-----------+----------+
| 6850 ACIA| 8300-8301 |          |
+----------+-----------+----------+
| 6821 PIA | 8200-8203 |          |
+----------+-----------+----------+
| Display  | 8110-816F |          |
+----------+-----------+----------+
| Keyboard | 8003-800E |          |
+----------+-----------+----------+
| RAM      | 0000-7FFF |   32K    |
+----------+-----------+----------+
```

JUMPERS AND CONNECTORS

To be written...

ASSEMBLY NOTES

To be written...

THEORY OF OPERATION

To be written...
