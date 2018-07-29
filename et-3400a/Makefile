all:	monitor.run sample1.run sample2.run

monitor.run: monitor.asm
	crasm -o monitor.run monitor.asm >monitor.lst

sample1.run: sample1.asm
	crasm -o sample1.run sample1.asm >sample1.lst

sample2.run: sample2.asm
	crasm -o sample2.run sample2.asm >sample2.lst

clean:
	$(RM) *.run *.lst
