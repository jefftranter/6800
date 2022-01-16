all:	all.run all.hex monitor.hex fantomii.hex tinybasic.hex

monitor.hex: monitor.asm
	crasm -o monitor.hex monitor.asm >monitor.lst

fantomii.hex: fantomii.asm
	crasm -o fantomii.hex fantomii.asm >fantomii.lst

tinybasic.hex: tinybasic.asm
	crasm -o tinybasic.hex tinybasic.asm >tinybasic.lst

all.hex: monitor.hex fantomii.hex tinybasic.hex
	cat monitor.hex fantomii.hex tinybasic.hex | grep "^:1" | sort >all.hex
	echo ":00000001FF" >>all.hex

all.run: all.hex
	srec_cat all.hex -intel -o all.run

clean:
	$(RM) *.hex *.lst *.run
