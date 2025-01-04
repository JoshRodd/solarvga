solarvga.sys:	solarvga.com
	cp solarvga.com solarvga.sys

solarvga.com:	solarvga.asm
	nasm solarvga.asm -l solarvga.lst -o solarvga.com

clean:
	rm -f solarvga.com solarvga.sys solarvga.lst
