%include "boot.inc"

LOADER_STACK_TOP equ LOADER_BASE_ADDR

SECTION loader vstart=LOADER_BASE_ADDR
    jmp loader_start

    ; construct gdt and descriptors in gpt
    GDT_BASE: dd 0x00000000
              dd 0x00000000

    CODE_DESC: dd 0x0000FFFF
               dd DESC_CODE_HIGH4

    DATA_STACK_DESC: dd 0x0000FFFF
                     dd DESC_DATA_HIGH4

    VIDEO_DESC: dd 0x80000007   ; limit = (0xbffff - 0xb8000) / 4k = 0x7
                dd DESC_VIDEO_HIGH4 ; dpl is 0 now

    GDT_SIZE equ $ - GDT_BASE
    GDT_LIMIT equ GDT_SIZE - 1
    times 60 dq 0               ; reserved space for subsequent descriptors

    SELECTOR_CODE equ (0x1 << 3) + TI_GDT + RPL0
    SELECTOR_DATA equ (0x2 << 3) + TI_GDT + RPL0
    SELECTOR_VIDEO equ (0x3 << 3) + TI_GDT + RPL0

    gdt_ptr dw GDT_LIMIT
            dd GDT_BASE

 	rarity db "RARITY LOADER IN REAL", 0

    ; --------------- start of the program -------------------
    loader_start:
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
	
    ; get into the protection mode
    ; 1. open A20
    in al, 0x92
    or al, 0000_0010b
    out 0x92, al

    ; 2. load GDT
    lgdt [gdt_ptr]

    ; 3. set the first position of cr0 to 1
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; flush the workflow
    jmp dword SELECTOR_CODE:p_mode_start


[bits 32]
    p_mode_start:
    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO
    mov gs, ax

    mov byte [gs:160], 'P'    

    ; make the program stop here
	jmp $
