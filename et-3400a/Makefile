all:	monitor.run sample1.run sample2.run sample3.run

monitor.run: monitor.asm
	crasm -o monitor.run monitor.asm >monitor.lst

sample1.run: sample1.asm
	crasm -o sample1.run sample1.asm >sample1.lst

sample2.run: sample2.asm
	crasm -o sample2.run sample2.asm >sample2.lst

sample3.run: sample3.asm
	crasm -o sample3.run sample3.asm >sample3.lst

clean:
	$(RM) *.run *.lst
