all:	mondeb.run

%.run: %.asm
	crasm -o $@ $< >$*.lst

clean:
	$(RM) *.run *.lst

distclean: clean
