%include "boot.inc"

SECTION loader vstart=LOADER_BASE_ADDR
	; initialize segment registers
	mov ax, cs
	mov ds, ax
	mov ss, ax

	; print string on the screen
	mov ax, 0xb800
	mov es, ax
	mov di, 0
	mov si, 0
	mov ch, 0
	.show_str:
		mov cl, [rarity + si]
		jcxz .show_str_finish
		mov es:[di], cl
		mov byte es:[di + 1], 0x7

		add di, 2
		inc si
		loop .show_str

	.show_str_finish:
	; make the program stop here
	jmp $

; others
	rarity db "RARITY LOADER", 0	
