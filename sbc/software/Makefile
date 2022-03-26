all:	all.bin all.run all.hex monitor.hex fantomii.hex fantomii-acia.hex tinybasic.hex mikbug.hex minibug.hex disasm.hex loader.hex basic680.run MicroBas.run

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

loader.hex: loader.asm
	crasm -o loader.hex loader.asm >loader.lst

example.run: example.asm
	crasm -o example.run example.asm >example.lst

disasm.hex: disasm.asm
	crasm -o disasm.hex disasm.asm >disasm.lst

MicroBas.run: MicroBas.asm
	as02 -v -q -s -l -oMicroBas.run MicroBas.asm
	echo "S9030000FC" >>MicroBas.run

MicroBas.hex: MicroBas.run
	srec_cat MicroBas.run -Motorola --crop 0x0100 0x1000 --offset 0xc000 -output MicroBas.hex -Intel

all.hex: loader.hex MicroBas.hex disasm.hex fantomii.hex tinybasic.hex fantomii-acia.hex mikbug.hex minibug.hex monitor.hex
	cat loader.hex MicroBas.hex disasm.hex fantomii.hex tinybasic.hex fantomii-acia.hex mikbug.hex minibug.hex monitor.hex | grep "^:[12]" >all.hex
	echo ":00000001FF" >>all.hex

all.run: all.hex
	srec_cat all.hex -intel -o all.run

all.bin: all.hex
	srec_cat all.hex -Intel --crop 0xc000 0x10000 --offset -0xc000 -output all.bin -Binary

clean:
	$(RM) *.lst
	$(RM) disasm.hex fantomii-acia.hex fantomii.hex loader.hex MicroBas.hex mikbug.hex minibug.hex monitor.hex tinybasic.hex
	$(RM) basic680.run MicroBas.run

distclean:
	$(RM) *.hex *.lst *.run *.bin

# For EPROM programming using TL866 II Plus programmer
blankcheck: all.bin
	minipro -p 27C128@DIP28 -y -b

program: all.bin
	minipro -p 27C128@DIP28 -y -w all.bin

verify: all.bin
	minipro -p 27C128@DIP28 -y -m all.bin
