all:	monitor.run sample1.run sample2.run sample3.run sample4.run sample5.run sample6.run sample7.run interrupt.run intclock.run

monitor.run: monitor.asm
	crasm -o monitor.run monitor.asm >monitor.lst

sample1.run: sample1.asm
	crasm -o sample1.run sample1.asm >sample1.lst

sample2.run: sample2.asm
	crasm -o sample2.run sample2.asm >sample2.lst

sample3.run: sample3.asm
	crasm -o sample3.run sample3.asm >sample3.lst

sample4.run: sample4.asm
	crasm -o sample4.run sample4.asm >sample4.lst

sample5.run: sample5.asm
	crasm -o sample5.run sample5.asm >sample5.lst

sample6.run: sample6.asm
	crasm -o sample6.run sample6.asm >sample6.lst

sample7.run: sample7.asm
	crasm -o sample7.run sample7.asm >sample7.lst

interrupt.run: interrupt.asm
	crasm -o interrupt.run interrupt.asm >interrupt.lst

intclock.run: intclock.asm
	crasm -o intclock.run intclock.asm >intclock.lst

clean:
	$(RM) *.run *.lst
