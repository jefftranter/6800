all:	example1.run example2.run example3.run example4.run example5.run example6.run example7.run example8.run example9.run example10.run example11.run example12.run example13.run example14.run example15.run

%.run: %.asm
	crasm -o $@ $< >$*.lst

clean:
	$(RM) *.run *.lst
