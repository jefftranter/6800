all:	all.bin all.run all.hex monitor.hex fantomii.hex fantomii-acia.hex tinybasic.hex mikbug.hex minibug.hex disasm.hex unused.hex basic680.run example.run

monitor.hex: monitor.asm
	crasm -o monitor.hex monitor.asm >monitor.lst

fantomii.hex: fantomii.asm
	crasm -o fantomii.hex fantomii.asm >fantomii.lst

fantomii-acia.hex: fantomii-acia.asm
	crasm -o fantomii-acia.hex fantomii-acia.asm >fantomii-acia.lst

tinybasic.hex: tinybasic.asm
	crasm -o tinybasic.hex tinybasic.asm >tinybasic.lst

mikbug.hex: mikbug.asm
	crasm -o mikbug.hex mikbug.asm >mikbug.lst

minibug.hex: minibug.asm
	crasm -o minibug.hex minibug.asm >minibug.lst

basic680.run: basic680.asm
	crasm -o basic680.run basic680.asm >basic680.lst

unused.hex: unused.asm
	crasm -o unused.hex unused.asm >unused.lst

example.run: example.asm
	crasm -o example.run example.asm >example.lst

disasm.hex: disasm.asm
	crasm -o disasm.hex disasm.asm >disasm.lst

all.hex: monitor.hex fantomii.hex fantomii-acia.hex tinybasic.hex minibug.hex mikbug.hex disasm.hex unused.hex
	cat monitor.hex mikbug.hex minibug.hex fantomii.hex fantomii-acia.hex tinybasic.hex disasm.hex unused.hex | grep "^:1" | sort >all.hex
	echo ":00000001FF" >>all.hex

all.run: all.hex
	srec_cat all.hex -intel -o all.run

all.bin: all.hex
	srec_cat all.hex -Intel --crop 0xc000 0x10000 --offset -0xc000 -output all.bin -Binary

clean:
	$(RM) *.hex *.lst *.run *.bin

# For EPROM programming using TL866 II Plus programmer
blankcheck: all.bin
	minipro -p 27C128@DIP28 -y -b

program: all.bin
	minipro -p 27C128@DIP28 -y -w all.bin

verify: all.bin
	minipro -p 27C128@DIP28 -y -m all.bin
