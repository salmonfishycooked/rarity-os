; MBR Program
; ------------------------------
SECTION MBR vstart=0x7c00
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov fs, ax
	mov sp, 0x7c00

; clear the screen using 0x06 function, scrolling up all lines to clear the screen
; --------------------------------------------------------------------
; INT 0x10	function number: 0x06	description: scroll up the window
; --------------------------------------------------------------------
; Input:
; AH function number = 0x06
; AL = the number of lines you need to scroll up (if it equals 0, representing all lines)
; BH = the attribute of lines that will be scrolled up
; (CL, CH) = the position of (X, Y) at the top-left corner of the window
; (DL, DH) = the position of (X, Y) at the bottom-right corner of the window
; return: nothing
	mov ax, 0x600
	mov bx, 0x700
	mov cx, 0			; top-right corner: (0, 0)
	mov dx, 0x184f		; bottom-right corner: (80, 25)
						; in VGA text mode, a line can only contain 80 characters. (25 lines in total)
						; index starts from 0, so 0x18 = 24, 0x4f = 79
	int 0x10

; -- the function of three lines below is to get the current position of the cursor. --
;	mov ah, 3			; input: the no.3 sub-function is to get the current position of the cursor, stored in ah
;	mov bh, 0			; the bh register stores the page number that is waiting to get.
;	int 0x10			; output: ch = the start line of the cursor, cl = the end line of the cursor
						; dh = the number of line of the current cursor, dl = the number of column ...
; -- end function --

; -- print string on screen --
	mov ax, message
	mov bp, ax			; es:bp points to the beginning address of the string

	mov cx, 10			; cx stores the length of the string
	mov ax, 0x1301		; sub-function number 13 displays characters and attributes, stored in ah
						; al are set to 1: display the string, and cursor make corresponding move.
	mov bx, 0x2			; bh stores the page number that will be displayed, and at here, it is 0
						; bl stores the attribute of characters, black background, green color text
	int 0x10
; -- end print string on screen --

	jmp $				; make this program stop here

	message db "RARITY MBR"
	times 510-($-$$) db 0
	db 0x55, 0xaa
