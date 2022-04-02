all: all1 all2

all1:	all1.bin all1.run all1.hex

all2:	all2.bin all2.run all2.hex

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

basic680.hex: basic680.run
	srec_cat basic680.run -Motorola --crop 0x0000 0x2000 --offset 0xc000 -output basic680.hex -Intel

loader1.hex: loader1.asm
	crasm -o loader1.hex loader1.asm >loader1.lst

loader2.hex: loader2.asm
	crasm -o loader2.hex loader2.asm >loader2.lst

example.run: example.asm
	crasm -o example.run example.asm >example.lst

ds1216e.run: ds1216e.asm
	crasm -o ds1216e.run ds1216e.asm >ds1216e.lst

disasm.hex: disasm.asm
	crasm -o disasm.hex disasm.asm >disasm.lst

MicroBas.run: MicroBas.asm
	as02 -v -q -s -l -oMicroBas.run MicroBas.asm
	echo "S9030000FC" >>MicroBas.run

MicroBas.hex: MicroBas.run
	srec_cat MicroBas.run -Motorola --crop 0x0100 0x1000 --offset 0xc000 -output MicroBas.hex -Intel

all1.hex: loader1.hex MicroBas.hex disasm.hex fantomii.hex tinybasic.hex fantomii-acia.hex mikbug.hex minibug.hex monitor.hex
	cat loader1.hex MicroBas.hex disasm.hex fantomii.hex tinybasic.hex fantomii-acia.hex mikbug.hex minibug.hex monitor.hex | grep "^:[12]" >all1.hex
	echo ":00000001FF" >>all1.hex

all2.hex: basic680.hex loader2.hex fantomii.hex tinybasic.hex fantomii-acia.hex mikbug.hex minibug.hex monitor.hex
	cat basic680.hex loader2.hex fantomii.hex tinybasic.hex fantomii-acia.hex mikbug.hex minibug.hex monitor.hex | grep "^:[12]" >all2.hex
	echo ":00000001FF" >>all2.hex

all1.run: all1.hex
	srec_cat all1.hex -intel -o all1.run

all2.run: all2.hex
	srec_cat all2.hex -intel -o all2.run

all1.bin: all1.hex
	srec_cat all1.hex -Intel --crop 0xc000 0x10000 --offset -0xc000 -output all1.bin -Binary

all2.bin: all2.hex
	srec_cat all2.hex -Intel --crop 0xc000 0x10000 --offset -0xc000 -output all2.bin -Binary

clean:
	$(RM) *.lst
	$(RM) disasm.hex fantomii-acia.hex fantomii.hex loader1.hex loader2.hex MicroBas.hex mikbug.hex minibug.hex monitor.hex tinybasic.hex basic680.hex
	$(RM) basic680.run MicroBas.run ds1216e.run

distclean:
	$(RM) *.hex *.lst *.run *.bin

# For EPROM programming using TL866 II Plus programmer
blankcheck:
	minipro -p 27C128@DIP28 -y -b

program1: all1.bin
	minipro -p 27C128@DIP28 -y -w all1.bin

verify1: all1.bin
	minipro -p 27C128@DIP28 -y -m all1.bin

program2: all2.bin
	minipro -p 27C128@DIP28 -y -w all2.bin

verify2: all2.bin
	minipro -p 27C128@DIP28 -y -m all2.bin
