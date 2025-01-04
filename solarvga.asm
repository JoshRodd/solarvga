; Installs the Solarized (dark) palette onto
; a VGA. Installing the TSR will ensure it
; is reinstalled after any mode change.
;
; Compatible with DOS 1.0 as a .COM TSR or
; DOS 2.0+ as a .SYS driver. Installing as
; a driver takes 208 bytes less memory due
; to saving the PSP (256 bytes) and memory
; control block (16 bytes).

		org	0

; If we are a TSR, we use the first 30h (48) bytes of this
; to store the colour palette. Otherwise it's part of the 
; driver header.

base:		
		jmp	near install_tsr ; dw -1,-1 ; for driver
		db	0
		dw	8000h
		dw	strategy
		dw	interrupt
		db	'SOLARVGA'

interrupt:	push	ax
		push	bx
		push	ds
		;mov	bx,<ptrsav_seg>
		db	0bbh	; mov bx,immediate
ptrsav_seg:	dw	0
		mov	ds,bx
		;mov	bx,<ptrsav_off>
		db	0bbh	; move bx, immediate
ptrsav_off:	dw	0
		mov	al,[bx+2]
		cmp	al,10h
		ja	cmderr
		or	al,al
		jnz	drvrchk
		jmp	drvrinit
cmderr:		mov	al,3
err_exit:	mov	ah,10000001b
		jmp	exit1

; This should be right around 30h

load_dac:	push	ax
		push	cx
		push	dx
		push	ds
		push	si
		mov	ax,cs
		mov	ds,ax
		;mov	si,<baseptr>
		db	0beh	; mov si,immediate
baseptr:	dw	base+100h
		mov	dx,3c8h
		xor 	al,al
		cli
		out	dx,al
		mov	dx,3c9h
		mov	cx,16*3
	;	rep	outsb
l1:		lodsb
		out	dx,al
		loop	l1
		pop	si
		pop	ds
		pop	dx
		pop	cx
		pop	ax
		ret

int10h_hook:	cmp	ah,0
		jz	mode_set
;		jmp	far <int10h_off>
		db	0eah	; jmp far absolute immediate_segment:immediate_offset
int10h_off:	dd	0
mode_set:	pushf
;		call	far [cs:int10h_off]
		db	2eh	; cs:
		dw	1effh	; call far [immediate_offset]
int10h_off_ptr:	dw	int10h_off
		; load_dac will disable interrupts.
		call	near load_dac
		; iret will restore the interrupt flag.
		iret

; TSR sets top to here and throws the rest away

tsr_end:

drvrchk:	mov	ah,1
exit1:		mov	[bx+3],ax
		pop	ds
		pop	bx
		pop	ax
strategy:	mov	[cs:ptrsav_off],bx
		mov	[cs:ptrsav_seg],es
		retf

colours_source:
black:		db (7+2)/4,(54+2)/4,(66+2)/4 		;base02
blue:		db (38+2)/4,(139+2)/4,(210+2)/4 	;blue
green:		db (133+2)/4,(153+2)/4,(0+2)/4 		;green
cyan:		db (42+2)/4,(161+2)/4,(152+2)/4 	;cyan
red:		db (220+2)/4,(50+2)/4,(47+2)/4 		;red
magenta:	db (211+2)/4,(54+2)/4,(130+2)/4 	;magenta
brown:		db (181+2)/4,(137+2)/4,(0+2)/4 		;yellow
white:		db (238+2)/4,(232+2)/4,(213+2)/4 	;base2
brblack:	db (0+2)/4,(43+2)/4,(54+2)/4 		;base03
brblue:		db (131+2)/4,(148+2)/4,(150+2)/4 	;base0
brgreen:	db (88+2)/4,(110+2)/4,(117+2)/4 	;base01
brcyan:		db (147+2)/4,(161+2)/4,(161+2)/4 	;base1
brred:		db (203+2)/4,(75+2)/4,(22+2)/4 		;orange
brmagenta:	db (108+2)/4,(113+2)/4,(196+2)/4 	;violet
bryellow:	db (101+2)/4,(123+2)/4,(131+2)/4 	;base00
brwhite:	db (253+2)/4,(246+2)/4,(227+2)/4 	;base3

; Driver sets top to here and throws rest away

drvr_end:

drvrinit:	push	ax
		push	cx
		push	dx
		push	bx
		push	bp
		push	si
		push	di
		push	ds
		push	es
		pushf
		; install_hook_drvr will leave interrupts disabled
		call	install_hook_drvr
		mov	ax,-1
		mov	[cs:base],ax
		mov	[cs:base+2],ax
		; popf will restore the interrupt flag
		popf
		pop	es
		pop	ds
		pop	di
		pop	si
		pop	bp
		pop	bx
		pop	dx
		pop	cx
		pop	ax
		ret

install_hook_drvr:
		mov	ax,colours_source
		mov	[cs:baseptr],ax
		; Get current INT 10h
		xor	ax,ax
		mov	ds,ax
		cli
		mov	ax,[10h*4]
		mov	dx,[10h*4+2]
		mov	cs:[int10h_off],ax
		mov	cs:[int10h_off+2],dx
		; Install our hook
		mov	ax,int10h_hook
		mov	[10h*4],ax
		mov	ax,cs
		mov	[10h*4+2],ax
		; Set the palette too
		call	load_dac
		ret

install_tsr:	; Fix up the pointers in the int10h hook
		mov	ax,100h
		add	[int10h_off_ptr+100h],ax
		; Copy the colours over
		mov	di,base+100h
		mov	si,colours_source+100h
		mov	cx,(16*3)/2
		pushf
		cld
		rep	movsw
		; Get current INT 10h
		xor	ax,ax
		mov	ds,ax
		mov	dx,cs
		mov	es,dx
		mov	si,10h*4
		mov	di,int10h_off+100h
		cli
		movsw
		movsw
		; Install our hook.
		; Instead of fixing up CS, it's better to keep CS
		; the original so that programs that try to find the
		; PSP of a TSR can find us.
		sub	si,4
		mov	ax,int10h_hook+100h
		mov	[si],ax
		mov	[si+2],cs
		; Set the palette too
		call	load_dac
		; Terminate and stay resident.
		mov	dx,cs
		mov	es,dx
		mov	ds,dx
		popf
		mov	dx,tsr_end+100h
		int 	27h
