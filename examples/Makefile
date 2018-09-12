all:	example1.run example2.run

#example1.run: example1.asm
#	crasm -o example1.run example1.asm >example1.lst

%.run: %.asm
	crasm -o $@ $< >$*.lst

clean:
	$(RM) *.run *.lst
