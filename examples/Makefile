all:	example1.run example2.run example3.run example4.run example5.run example6.run example7.run

%.run: %.asm
	crasm -o $@ $< >$*.lst

clean:
	$(RM) *.run *.lst
