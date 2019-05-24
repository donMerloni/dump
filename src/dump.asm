CPU 386
BITS 16
ORG 0x7C00

;-----------------------------------
; CODE
;-----------------------------------

start:
    ; Save registers
    mov [_AX], ax
    mov [_SS], ss
    mov [_SP], sp

    ; Setup 1kB Stack
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x7C00 + 512 + 1024
    sti
    
    ; Calculate the address of our entry point (Instruction Pointer)
    call getIP
    sub ax, $ - start
    mov [_IP], ax
    
suspend:
    hlt
    jmp suspend
    
;-----------------------------------
; DATA
;-----------------------------------

%imacro line 0-*
    %if %0 >= 1
        db %1
    %endif
    %if %0 >= 2
        db %{2:-1}
    %else
        db 13, 10
    %endif
%endmacro

_SZ_FORMAT:
    line " CS:IP = %x:%x"
    line   
    line " SS:SP = %x:%x"
    line "    BP = %x"
    line   
    line " AX = %x"
    line " CX = %x"
    line " DX = %x"
    line " BX = %x"
    line " SI = %x"
    line " DI = %x"
    line      
    line " DS = %x"
    line " ES = %x"
    line " FS = %x"
    line " GS = %x"
    line
    line " FLAGS = %b", 0 

_AX: dw 0
_SS: dw 0
_SP: dw 0
_IP: dw 0

;-----------------------------------
; FUNCTIONS
;-----------------------------------

; Copies the return address of this function into AX
getIP:
push bp
    mov bp, sp
    mov ax, [bp+2]
pop bp
ret

; Print string
; Args:
;   Stack = string pointer
_print:
pusha
mov bp, sp
    mov si, [bp+18]
    mov ah, 0xE
.next:
    lodsb
    and al, al
    jz .done
    int 0x10
    jmp .next
.done:
popa
ret 2

; Print 16-bit integer (word). Supports base 1-16
; Args:
;   Stack = number, base
_printw:
pusha
mov bp, sp
    mov ax, [bp+18]
    xor dx, dx
    div word [bp+20]
    test ax, ax
    jz .digit
    push word [bp+20]
    push ax
    call _printw
.digit:
    mov bx, dx
    mov ax, [_SZ_HEX+bx]
    mov ah, 0xE
    int 0x10
popa
ret 4

_SZ_HEX: db "0123456789ABCDEF"

; A simple and naive C-style printf function.
; Specifiers:
;   %s = string | %d = decimal int16 | %x = hex int16 | %b = binary int16
;   %% = % | any other specifier = char
; Args:
;   Stack = format, args...
_printf:
pusha
mov bp, sp

    ; Get pointer to format string
    mov si, [bp+18]
    ; Get pointer to stack arguments
    lea di, [bp+18]
    add di, 2
    
    ; Loop over format string
.loop:
    mov al, [si]
    test al, al
    jz .end
    
    push 0  ; possible argument 2
    
    cmp al, '%'
    jne .noFormat
    
    push word [di] ; argument 1
    add di, 2
    inc si
    
    ; Check format
    mov bl, byte [si]
    cmp bl, '%'
    je .noFormat
.checkS:
    cmp bl, 's'
    je .string
.checkD:
    cmp bl, 'd'
    jne .checkX
    mov word [bp-2], 10
    jmp .word
.checkX:
    cmp bl, 'x'
    jne .checkB
    mov word [bp-2], 16
    jmp .word
.checkB:
    cmp bl, 'b'
    jne .char
    mov word [bp-2], 2
    
.word:
    call _printw
    jmp .loopContinue
    
.string:
    call _print
    jmp .loopContinue_1UnusedArgs
    
.char:
    pop ax
    
.noFormat:
    mov ah, 0xE
    int 0x10
    
.loopContinue_1UnusedArgs:
    pop ax
.loopContinue:
    inc si
    jmp .loop
    
.end:
popa
ret 2

;-----------------------------------
; Master Boot Record (MBR)
;-----------------------------------
times 446-($-$$) db 0 ; max 446 bytes of code
;--------------------------------
; Partition entry #1 
;--------------------------------
db 0x80               ; bootable
db 0, 0, 0            ; start CHS
db 4                  ; type
db 0, 0, 0            ; end CHS
dd 0                  ; start LBA
dd 1                  ; sector count         
;--------------------------------
; 3 empty entries
;--------------------------------
times 16 * 3 db 0
db 0x55, 0xAA         ; Magic number