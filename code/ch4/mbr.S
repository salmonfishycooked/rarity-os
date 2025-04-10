; MBR Program
%include "boot.inc"

SECTION mbr vstart=0x7c00
; initialize segment registers
	mov ax, cs
	mov ds, ax
	mov ss, ax

; clear the screen using 10h interruption
	mov ax, 0x0600
	mov bx, 0x0700
	mov cx, 0x0
	mov dx, 0x184f
	int 10h

; output the string to the screen
	mov ax, 0xb800
	mov es, ax
	mov si, 0
	mov di, 0
	mov ch, 0
	.print:
		mov cl, [rarity + si]
		jcxz .print_finish
		mov es:[di], cl
		mov byte es:[di + 1], 0xA4
		add di, 2
		inc si

		loop .print
	.print_finish:

	; copy loader to LOADER_BASE_ADDR into memory
	mov eax, LOADER_START_SECTOR
	mov bx, LOADER_BASE_ADDR
	mov cx, 4
	call read_disk

	; hand control over to loader program
	jmp LOADER_BASE_ADDR

; function: read_disk will read n sectors from disk
; arguments:
; 1. eax = the sector number in LBA
; 2. bx = stores the memory address waiting for being written in
; 3. cx = the amount of sectors that will be read in
read_disk:
	; backup registers
	mov esi, eax
	mov di, cx

	; step 1: set the number of sectors that will be read
	mov dx, 0x1f2
	mov al, cl
	out dx, al
	mov eax, esi

	; step 2: write LBA to 0x1f3 ~ 0x1f6
	; write LBA 0~7 bit to port 0x1f3
	mov dx, 0x1f3
	out dx, al

	; write LBA 8~15 bit to port 0x1f4
	mov cl, 8
	shr eax, cl
	mov dx, 0x1f4
	out dx, al

	; write LBA 16~23 bit to port 0x1f5
	shr eax, cl
	mov dx, 0x1f5
	out dx, al

	; write LBA 24~27 bit and set corresponding lba state to port 0x1f6
	shr eax, cl
	and al, 0x0f
	or al, 0xe0
	mov dx, 0x1f6
	out dx, al

	; step 3: write read command to port 0x1f7, namely 0x20
	mov dx, 0x1f7
	mov al, 0x20
	out dx, al

	; step 4: check the state of the disk (use the same port as writting read command uses)
	.not_ready:
		nop
		in al, dx
		; that the position of 4 is 1 represents the controller of the disk is ready to transmit
		; that the position of 7 is 1 represents the disk is busy
		and al, 0x08
		cmp al, 0x08

		; if the disk is not ready, continue waiting
		jnz .not_ready

	; step 5: read data from port 0x1f0
	; a sector has 512 bytes, one in instruction reads 1 word, namely 2 Byte
	; so we need to read (di * 512 / 2 = di * 256) times in total.
	mov ax, di
	mov dx, 256
	mul dx
	mov cx, ax
	mov dx, 0x1f0

	.go_on_read:
	in ax, dx
	mov [bx], ax
	add bx, 2
	loop .go_on_read

	ret
; function: read_disk ends

; others
	rarity db "RARITY MBR", 0
	times 510 - ($ - $$) db 0
	db 0x55, 0xaa
