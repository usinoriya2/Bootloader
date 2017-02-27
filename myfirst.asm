	BITS 16
	ORG 0x7C00

start:
	;mov ax, 07C0h		; Set up 4K stack space after this bootloader
	;add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	;mov ss, ax
	;mov sp, 4096

	;mov ax, 0h		; Set data segment to where we're loaded
	;mov ds, ax


	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine

	jmp $			; Jump here - infinite loop!


	text_string db 'This text is being printed in real mode!', 0


print_string:			; Routine: output string in SI to screen
	mov al, 02h ; setting  the graphical mode 80x25(text)
mov ah, 00h ; code  of function of changing video mode
int 10h
	int 10h
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it

	jmp .repeat

.done:
	ret


	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature