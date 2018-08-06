all:	monitor.run tinybasic.run sample.run mikbug.run

monitor.run: monitor.asm
	crasm -o monitor.run monitor.asm >monitor.lst

tinybasic.run: tinybasic.asm
	crasm -o tinybasic.run tinybasic.asm >tinybasic.lst

sample.run: sample.asm
	crasm -o sample.run sample.asm >sample.lst

mikbug.run: mikbug.asm
	crasm -o mikbug.run mikbug.asm >mikbug.lst

clean:
	$(RM) *.run *.lst
