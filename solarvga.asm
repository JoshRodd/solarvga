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
		jmp	near chk_tsr ; dw -1,-1 ; for driver
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

int10h_hook:	cmp	ah,'O'
		jz	inst_chk
		cmp	ah,0
		jz	mode_set
;		jmp	far <int10h_off>
unsupp_mode:   	db	0eah	; jmp far absolute immediate_segment:immediate_offset
int10h_off:	dd	0
		; Check for installation check request.
inst_chk:     	cmp	al,'S'
		jnz	not_inst_chk
		cmp	cx,'L'+'A'*256
		jnz	not_inst_chk
		cmp	dx,'R'+'V'*256
		jnz	not_inst_chk
		cmp	bx,'G'+'A'*256
		jnz	not_inst_chk
		jmp	is_inst_chk
mode_set:       ; We only support modes 1, 3, D, E, 10h, 12h, 13h.
		cmp	al,3 ; 80x25 colour
		jz	not_inst_chk
		cmp	al,1 ; 40x25 colour
		jz	not_inst_chk
		cmp	al,0dh ; 320x200 (EGA)
		jz	not_inst_chk
		cmp	al,10h ; 640x200 (EGA)
		jz	not_inst_chk
		cmp	al,12h ; 640x350 (EGA)
		jz	not_inst_chk
		cmp	al,13h ; 640x480 (16 colour VGA)
		jz	not_inst_chk
		jmp	unsupp_mode
not_inst_chk:	pushf
;		call	far [cs:int10h_off]
		db	2eh	; cs:
		dw	1effh	; call far [immediate_offset]
int10h_off_ptr:	dw	int10h_off
		; load_dac will disable interrupts.
		call	near load_dac
		; iret will restore the interrupt flag.
		iret
is_inst_chk:	mov	ax,'S'+'Y'*256
		mov	cl,'S'
		mov	bp,cs
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

chk_tsr:	; Check for the command-line option /U
		; (for uninstall). If so, make sure the
		; driver is installed before trying to
		; uninstall it.

		; Make sure command line is at least 2 bytes
		; long.
		mov	al,2
		cmp	[80h],al ; Allow SOLARVGA/U or SOLARVGA /U
		jb	no_args
		mov	cx,'/'+'u'*256
		mov	dx,invalid_args_txt+100h
		or	[82h],byte 20h ; Lowercase the u; won't change a / or space
		cmp 	[81h],cx
		jz	uninstall_arg
		mov	al,3
		cmp	[80h],al
		jb	chk_error
		mov	al,' '
		cmp	[81h],al ; Check for " /U"
		jnz	chk_error
		or	[83h],byte 20h ; Lowercase the u
		cmp 	[82h],cx
		jnz	chk_error

		; OK, the argument is /U[NINSTALL], so do
		; an installation check. If it isn't installed,
		; then print an error.
uninstall_arg:
		call	call_inst_chk
		mov	dx,tsr_not_install_chk_txt+100h
		jnc	chk_error
		mov	dx,cant_uninstall_drvr_txt+100h
		cmp	al,2
		jz      chk_error

		; Go try to uninstall it.
		jmp	tsr_uninstall

		; Checks if the TSR is already installed.
no_args:       	call	call_inst_chk
		jnc	tsr_install
		mov	dx,drvr_install_chk_txt+100h
		cmp	al,2
		jz	chk_error
		mov	dx,tsr_install_chk_txt+100h
		jmp	chk_error

tsr_install:	; Make sure a VGA or MCGA is present.
		mov	dx,not_vga_txt+100h
		call	chk_vga
		jc	chk_error
	        ; Fix up the pointers in the int10h hook
		mov	ax,100h
		add	[int10h_off_ptr+100h],ax
		; Copy the colours over
		mov	di,base+100h
		mov	si,colours_source+100h
		mov	cx,(16*3)/2
		pushf
		cld
		rep	movsw
		; Change our installation check to "COM" from SYS".
		mov	ax,'C'+'O'*256
		mov	[is_inst_chk+1+100h],ax
		mov	al,'M'
		mov	[is_inst_chk+4+100h],al
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
		; Free our environment (if it exists).
		mov	ax,[2ch]
		or	ax,ax
		; If zero, this is probably DOS 1.00.
	        jz	tsr_exit
		mov	es,ax
		mov	ah,49h
		int	21h
		; If this fails, we might be on DOS 1.00; change it to zero.
		jnc	tsr_exit
		xor	ax,ax
		mov	[2ch],ax
tsr_exit:      	mov	dx,tsr_end+100h
		int 	27h

chk_error:	sti
		mov	ah,9
		int	21h
		int	20h

tsr_uninstall:	; The vector must be the same as the one we'd install.
		xor	ax,ax
		mov	es,ax
		cli
	        mov	ax,[es:10h*4]
		mov	dx,tsr_chain_txt+100h
		cmp	ax,int10h_hook+100h
		jnz	chk_error
		; Ensure the segment returned by the installation check (BP)
		; is the same as the vector.
	        cmp	bp,[es:10h*4+2]
		jnz	chk_error
		mov	es,bp
		; Compare the colour table at the top of the TSR to
		; ours.
		mov	di,base+100h
		mov	si,colours_source+100h
		mov	cx,(16*3)/2
		repz	cmpsw
		jnz	chk_error
	        ; At this point, assume this really is our own TSR.
		xor	ax,ax
		mov	ds,ax
	        mov	ax,[es:int10h_off+100h]
	        mov	dx,[es:int10h_off+100h+2]
	        mov	[10h*4],ax
	        mov	[10h*4+2],dx
		sti
		push	bp
                mov     ax,cs
                mov     ds,ax
		; Reset the palette to the video mode's default.
		; Get the current video mode.
		mov	ah,0fh
		int	10h
		xor	ah,ah
		or	al,80h
		push	ax ; Preserve video mode.
		push	bx ; Preserve current page.
		; Save the cursor position.
		mov	ah,3
		int	10h
		; Restore the video mode.
		pop	bx ; Restore current page.
		pop	ax ; Restore video mode.
		push	dx ; Preserve the cursor position.
		push	bx ; Preserve current page.
		int	10h ; Set mode (AX no longer needed).
		; Restore the cursor.
		pop	bx ; Restore current page.
		pop	dx ; Restore cursor position.
		mov	ah,2 ; Set cursor position.
		int	10h
		; Free the memory. Segment is in BP.
		pop	bp
		mov	ah,49h
		mov	es,bp
		int	21h
		mov	dx,uninstalled_txt+100h
		jmp	chk_error

; Checks if TSR or driver is installed. CY=Clear,
; neither installed. CY=Set, AL=1 if TSR and AL=2
; if driver.
call_inst_chk:  mov	ax,'S'+'O'*256
		mov	cx,'L'+'A'*256
		mov	dx,'R'+'V'*256
		mov	bx,'G'+'A'*256
		int	10h
		cmp	ax,'C'+'O'*256
		jnz	not_com
		cmp	cl,'M'
		jnz	not_com
		mov	al,1
		stc
		ret
not_com: 	cmp	ax,'S'+'Y'*256
		jnz	not_sys_or_com
		cmp	cl,'S'
		jnz	not_sys_or_com
		mov	al,2
		stc
		ret
not_sys_or_com: mov	al,0
		clc
		ret

chk_vga:	mov	ax,1200h ; Check for MCGA
		mov	bl,10h
		int	10h
		cmp	al,10h
		jz	chk_vga_ok
		; No MCGA...
		mov	ax,1a00h ; Check for VGA
		int	10h
		cmp	al,1ah
		jz	chk_vga_ok
		stc
		ret
chk_vga_ok:	clc
		ret

drvr_install_chk_txt:
		db	'SOLARVGA.SYS driver already installed.',13,10,'$'

tsr_install_chk_txt:
		db	'SOLARVGA.COM TSR already installed.',13,10,'$'

tsr_not_install_chk_txt:
		db	'SOLARVGA.COM TSR is not installed; cannot uninstall.',13,10,'$'

tsr_chain_txt:
		db	'Another TSR has hooked INT 10h after SOLARVGA.COM was '
		db      'installed. Cannot',13,10,'uninstall unless that TSR is '
		db      'uninstalled first.',13,10,'$'

cant_uninstall_drvr_txt:
		db      'SOLARVGA.SYS driver is installed and cannot be uninstalled '
		db      'without removing the',13,10,'DEVICE=SOLARVGA.SYS statement '
		db      'from CONFIG.SYS and rebooting.',13,10,'$'

invalid_args_txt:
		db	'Invalid argument(s). Valid argument is /U to uninstall.',13,10,'$'

uninstalled_txt:
		db	'SOLARVGA.COM TSR uninstalled.',13,10,'$'

not_vga_txt:	db	'This program requires an IBM PS/2, a PS/2 Display Adapter, or '
		db	'100% ',13,10,'VGA-compatible or MCGA-compatible display adapter.'
		db	13,10,'$'
