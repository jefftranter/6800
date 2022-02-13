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

```
J1 AC/DC IN Connector to power board from unregulated AC or DC input.
J10 PA1 Jumper to select baud rate for PIA serial interface.
J11 SEGMENT TEST Jumper to light all LED segments for testing.
J12 REG. POWER Jumper to select powering board from unregulated AC/DC input.
J13 PA2 Jumper to select baud rate for PIA serial interface.
J14 PA3 Jumper to select baud rate for PIA serial interface.
J15 PA4 Jumper to select baud rate for PIA serial interface.
J16 PA5 Jumper to select baud rate for PIA serial interface.
J17 PA6 Jumper to select baud rate for PIA serial interface.
J2 5V IN Connector to power board from regulated 5 Volt input.
J3 EXPANSION Connector for expansion connector to CPU bus signals.
J4 LTC Jumper to select if AC input generates IRQ or NMI interrupts.
J5 PARALLEL PORT Connector for 2 8-bit parallel i/o ports from PIA.
J6 TX DATA SELECT Jumper to select whether to use ACIA or PIA for serial output.
J7 RX DATA SELECT Jumper to select whether to use ACIA or PIA for serial input.
J8 USB POWER Jumper to select powering board from USB FTDI connector.
J9 FTDI SERIAL Connector to a 6 pin FTDI USB serial adaptor for console.
```

ASSEMBLY NOTES

To be written...

THEORY OF OPERATION

To be written...
