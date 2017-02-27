use16
org 0x7C00 ; boot sector address


start:

	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine

	mov ax,0xffff

wait_it:
	dec ax
	cmp ah, 0   ; Check if lock is free

	je cont
	pause            ; Wait for memory pipeline to become empty
	jmp wait_it
cont:

	jmp Boot			; Jump here - infinite loop!


	text_string db `\n\n\nThis text was printed in real mode!`, 0


print_string:			; Routine: output string in SI to screen
	mov al, 02h ; setting  the graphical mode 80x25(text)
	mov ah, 00h ; code  of function of changing video mode
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


Boot:
	;
	mov ah,0x00	; reset disk
	mov dl,0	; drive number
	int 0x13
	;
	mov ah,0x02	; read sectors into memory
	mov al,0x10	; number of sectors to read (16)
	mov dl,0	; drive number
	mov ch,0	; cylinder number
	mov dh,0	; head number
	mov cl,2	; starting sector number
	mov bx,Main	; address to load to
	int 0x13	; call the interrupt routine
	;
	jmp Main
	;

PreviousLabel:

PadOutWithZeroesSectorOne:
	times ((0x200 - 2) - ($ - $$)) db 0x00

BootSectorSignature:
	dw 0xAA55

;===========================================

Main:
	;
	; set the display to VGA text mode now
	; because interrupts must be disabled
	;
	;mov ax,3
	;int 0x10    ; set VGA text mode 3
	;
	; set up data for entering protected mode
	;
        xor edx,edx ; edx = 0
        mov dx,ds   ; get the data segment
        shl edx,4   ; shift it left a nibble
        add [GlobalDescriptorTable+2],edx ; GDT's base addr = edx
	;
        lgdt [GlobalDescriptorTable] ; load the GDT  
        mov eax,cr0 ; eax = machine status word (MSW)
        or al,1     ; set the protection enable bit of the MSW to 1
	;
        cli         ; disable interrupts
        mov cr0,eax ; start protected mode
	;
        mov bx,0x08 ; the size of a GDT descriptor is 8 bytes
        mov fs,bx   ; fs = the 2nd GDT descriptor, a 4 GB data seg
	;
	; write a status message
	;
	mov ebx,0xB8000 ; address of first char for VGA mode 3
	;
	mov si,TextProtectedMode ; si = message text
	;
	ForEachChar:
		;
		lodsb		; get next char	
		cmp al,0x00	; if it's null, break 	
		je EndForEachChar
		;
		mov [fs:ebx],al	; write char to display memory
		;
		inc ebx		; 2 bytes per char
		inc ebx		; so increment twice
		;
	jmp ForEachChar
	EndForEachChar:
	;
	LoopForever: jmp LoopForever
	;
	ret
	;
	TextProtectedMode: db `This text is being printed in protected mode.`,0

GlobalDescriptorTable:   

	; the global descriptor table is the heart of protected mode
	; entries are used to map virtual to physical memory
	; among other things
	;
	; each descriptor contains 8 bytes, "organized" as follows:
	;
	; |----------------------2 bytes--------------------|
	;
	; +-------------------------------------------------+
	; | segment address 24-31  | flags #2  | len 16-19  | +6
	; +-------------------------------------------------+
	; | flags #1               | segment address 16-23  | +4
	; +-------------------------------------------------+
	; | segment address bits 0-15                       | +2
	; +-------------------------------------------------+
	; | segment length bits 0-15                        | +0
	; +-------------------------------------------------+

	; the high-order bit of flags #2 controls "granularity"
	; setting it to 1 multiplies the segment length by 4096

	;======================================================

	; create two descriptors:
	; one for the GDT itself, plus a 4 gibabyte data segment

	dw GlobalDescriptorTableEnd - GlobalDescriptorTable - 1 
	; segment address bits 0-15, 16-23
	dw GlobalDescriptorTable 
	db 0	
	; flags 1, segment length 16-19 + flags 2
	db 0, 0
	; segment address bits 24-31
	db 0 

	; a data segment based at address 0, 4 gibabytes long
	; 
        dw 0xFFFF 	; segment length 0-15
	db 0, 0, 0 	; segment address 0-15, 16-23
	db 0x91 	; flags 1
	db 0xCF 	; flags 2, segment length 16-19
	db 0		; segment address 24-31
	;
GlobalDescriptorTableEnd:

;===========================================

PadOutWithZeroesSectorsAll:
	times (0x2000 - ($ - $$)) db 0x00