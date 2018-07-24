all:	monitor.run tinybasic.run

monitor.run: monitor.asm
	crasm -o monitor.run monitor.asm >monitor.lst

tinybasic.run: tinybasic.asm
	crasm -o tinybasic.run tinybasic.asm >tinybasic.lst

clean:
	$(RM) monitor.run monitor.lst tinybasic.run tinybasic.lst
