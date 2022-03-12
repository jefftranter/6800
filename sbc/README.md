6800 Single Board Computer

This is a 6800-based single board computer design. It has the
following features:

* 6802 CPU running at 1.0 MHz
* 32K of RAM
* 16K of EPROM
* Hex keypad and 7-segment LED display interface
* Parallel interface using 6821 PIA (2 8-bit parallel ports)
* Serial interface using 6850 UART with TTL levels for FTDI USB serial adaptor
* Various power options: regulated 5VDC in (e.g. via USB), unregulated 8-25 VDC in, unregulated 8-25 AC in, or 120/220 VAC in via external AC adaptor or transformer (i.e. wall-wart)
* Address decoding using CPLD (Can adjust memory map by reprogramming CPLD)
* 50/60 Hz interrupt support if powered by AC input
* Expansion connector with all CPU bus signals
* Open Source hardware design, including PCB layout, using Kicad

The design is roughly based on the Heathkit ET-6800 CPU trainer with
additional features, some taken from the Heathkit ETA-3400 expander.
It can run a modified version of the ET-6800/ET-3400 firmware and
other firmware including a serial monitor and BASIC.

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
J2 5V IN Connector to power board from regulated 5 Volt input.
J3 EXPANSION Connector for expansion connector to CPU bus signals.
J4 LTC Jumper to select if AC input generates IRQ or NMI interrupts.
J5 PARALLEL PORT Connector for 2 8-bit parallel i/o ports from PIA.
J6 TX DATA SELECT Jumper to select whether to use ACIA or PIA for serial output.
J7 RX DATA SELECT Jumper to select whether to use ACIA or PIA for serial input.
J8 USB POWER Jumper to select powering board from USB FTDI connector.
J9 FTDI SERIAL Connector to a 6 pin FTDI USB serial adaptor for console.
J11 SEGMENT TEST Jumper to light all LED segments for testing.
J12 REG. POWER Jumper to select powering board from unregulated AC/DC input.
J10 PA1 Jumper to select baud rate for PIA serial interface.
J13 PA2 Jumper to select baud rate for PIA serial interface.
J14 PA3 Jumper to select baud rate for PIA serial interface.
J15 PA4 Jumper to select baud rate for PIA serial interface.
J16 PA5 Jumper to select baud rate for PIA serial interface.
J17 PA6 Jumper to select baud rate for PIA serial interface.

Serial Select Jumpers:
ACIA: J6 1-2, J7 2-3
PIA:  J6 2-3, J7 1-2

Baud Rate Jumpers:
+---+---+---+---+---+---+----+
|PA1|PA2|PA3|PA4|PA5|PA6|RATE|
+---+---+---+---+---+---+----+
| H | H | H | - | - | - | 110|
| L | L | L | - | - | - | 300|
| H | L | H | - | - | - | 600|
| L | L | H | - | - | - |1200|
| H | H | L | - | - | - |2400|
| L | H | L | - | - | - |4800|
| H | L | L | - | - | - |9600|
+---+---+---+---+---+---+----+
```

ASSEMBLY NOTES

Assembly using a PCB with the provided Gerber files is straightforward
and uses all though-hole components. It is recommended to start with
lowest height components (e.g. resistors). All ICs should be mounted
on sockets. A machined socket is recommended for the EPROM so it can
be more easily replaced when reprogrammed.

You will need a way to program the EPROM and CPLD chips.

If problems are encountered, these are the most common issues to check
for:

- Check for solder opens or shorts
- Check for bent pins under IC sockets
- Check that all parts are correct values and installed with correct orientation
- Make sure PROM and CPLD are correctly programmed
- Check for 5V power, CPU clock
- Check for ACIA clock

To test memory, you can run the memory test at address EA34. It should
display the top memory address (7FFF) and increment the test cycle
count without stopping.

To test the serial output from the PIA, set jumpers for PIA output and
desired baud rate, and run the routine at EAF6. It should continuously
output "THIS IS A TERMINAL TEST".

POWER REQUIREMENTS

Typical current requirement if powered by USB is 560 mA. A 1 amp USB
power source is recommended (note that some USB power supplies and
older USB ports can only supply 0.5A).

It can be powered from unregulated AC or DC input. It can operate from
8 to 25 volts DC either polarity. Make sure (the maximum voltage
rating of C2 is not exceeded). For AC input, change the value of C2 to
2000 uF or more. AC input is required if you want to use the AC line
(50/60 Hz) interrupt feature.

Current consumption for unregulated input should be between 400 and
600mA. If the 7805 regulator gets hot you might want to mount a
heatsink on it.

OTHER NOTES

If you want to use port A of the PIA for i/o, be sure to remove any
jumpers at J6, J7, and J10-J17.

The Heathkit ETA-3400 had support for a cassette tape interface. This
is not present, so any monitor or Basic commands related to cassette
will not function.
