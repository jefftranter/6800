all:	monitor.hex

monitor.hex: monitor.asm
	crasm -o monitor.hex monitor.asm >monitor.lst

clean:
	$(RM) *.hex *.lst
