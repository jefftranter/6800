sall:	all.bin all.run all.hex monitor.hex fantomii.hex tinybasic.hex mikbug.hex minibug.hex

monitor.hex: monitor.asm
	crasm -o monitor.hex monitor.asm >monitor.lst

fantomii.hex: fantomii.asm
	crasm -o fantomii.hex fantomii.asm >fantomii.lst

tinybasic.hex: tinybasic.asm
	crasm -o tinybasic.hex tinybasic.asm >tinybasic.lst

mikbug.hex: mikbug.asm
	crasm -o mikbug.hex mikbug.asm >mikbug.lst

minibug.hex: minibug.asm
	crasm -o minibug.hex minibug.asm >minibug.lst

all.hex: monitor.hex fantomii.hex tinybasic.hex
	cat monitor.hex fantomii.hex tinybasic.hex | grep "^:1" | sort >all.hex
	echo ":00000001FF" >>all.hex

all.run: all.hex
	srec_cat all.hex -intel -o all.run

all.bin: all.hex
	srec_cat all.hex -Intel --crop 0xc000 0x10000 --offset -0xc000 -output all.bin -Binary

clean:
	$(RM) *.hex *.lst *.run *.bin
