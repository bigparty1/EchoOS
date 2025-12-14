[bits 64]
global gdt_flush

gdt_flush:
    ; Carrega o GDT a partir do ponteiro em RDI
    lgdt [rdi]
    
    ; Carregar 0x10 (Data Segment) nos registradores de dados
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Pulo para carregar CS com 0x08 (Code Segment)
    pop rdi
    mov rax, 0x08
    push rax
    push rdi
    retfq