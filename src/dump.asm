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