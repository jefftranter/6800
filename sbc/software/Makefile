all:	all.bin all.run all.hex monitor.hex fantomii.hex tinybasic.hex mikbug.hex minibug.hex unused.hex basic680.hex

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

basic680.hex: basic680.asm
	crasm -o basic680.hex basic680.asm >basic680.lst

unused.hex: unused.asm
	crasm -o unused.hex unused.asm >unused.lst

all.hex: monitor.hex fantomii.hex tinybasic.hex minibug.hex mikbug.hex unused.hex
	cat monitor.hex mikbug.hex minibug.hex fantomii.hex tinybasic.hex unused.hex | grep "^:1" | sort >all.hex
	echo ":00000001FF" >>all.hex

all.run: all.hex
	srec_cat all.hex -intel -o all.run

all.bin: all.hex
	srec_cat all.hex -Intel --crop 0xc000 0x10000 --offset -0xc000 -output all.bin -Binary

clean:
	$(RM) *.hex *.lst *.run *.bin
