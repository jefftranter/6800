all:	mondeb.run

%.run: %.asm
	crasm -o $@ $< >$*.lst
	egrep "ERRORS: |WARNINGS: " $*.lst

clean:
	$(RM) *.run *.lst

distclean: clean
