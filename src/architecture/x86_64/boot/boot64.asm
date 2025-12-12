;Autor: Kauê dos Santos Gomes
;Data: 12/12/2025
;Descrição: Bootloader stage 2 (Entry Point para o Kernel C)

global start
extern kernel_main

; --- SEÇÃO ESPECIAL DE BOOT (Garante posição 0x1000) ---
section .boot
[bits 16]

start:
    ; 1. Limpar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00 ; Pilha temporária

    ; 2. Habilitar A20 e carregar GDT
    call enable_a20

    cli
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump manual para 32-bits (bytes literais)
    db 0x66         ; Operand size prefix (32-bit)
    db 0xEA         ; Far jump opcode
    dd start_protected_mode  ; Offset 32-bit
    dw CODE_SEG     ; Segment selector

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

; --- GDT 32 ---
gdt_start:
gdt_null: 
    dq 0                          ; Null descriptor (8 bytes)
gdt_code: 
    dw 0xFFFF                     ; Limite (bits 0-15)
    dw 0x0000                     ; Base (bits 0-15)
    db 0x00                       ; Base (bits 16-23)
    db 10011010b                  ; Acesso: Present, Ring 0, Code, Executable, Readable
    db 11001111b                  ; Flags (4KB granularity, 32-bit) + Limite (bits 16-19)
    db 0x00                       ; Base (bits 24-31)
gdt_data: 
    dw 0xFFFF                     ; Limite (bits 0-15)
    dw 0x0000                     ; Base (bits 0-15)
    db 0x00                       ; Base (bits 16-23)
    db 10010010b                  ; Acesso: Present, Ring 0, Data, Writable
    db 11001111b                  ; Flags (4KB granularity, 32-bit) + Limite (bits 16-19)
    db 0x00                       ; Base (bits 24-31)
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; --- CÓDIGO 32-BITS (ainda na seção .boot para resolver o far jump) ---
[bits 32]

start_protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov ebp, 0x90000
    mov esp, ebp

    call setup_paging
    call enable_paging_mode
    
    mov edi, gdt64_descriptor
    lgdt [edi]
    jmp 0x08:start_long_mode

setup_paging:
    ; Limpa as tabelas de paginação
    mov edi, 0x2000
    xor eax, eax
    mov ecx, 3072
    rep stosd
    
    ; PML4[0] -> PDPT @ 0x3000
    mov edi, 0x2000
    mov eax, 0x3003
    mov [edi], eax
    
    ; PDPT[0] -> PD @ 0x4000
    mov edi, 0x3000
    mov eax, 0x4003
    mov [edi], eax
    
    ; PD[0] -> 2MB page @ 0x0 (huge page)
    mov edi, 0x4000
    mov eax, 0x83
    mov [edi], eax
    ret

enable_paging_mode:
    mov eax, 0x2000
    mov cr3, eax
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

; GDT 64 (alinhado para performance)
align 16
gdt64_start:
    dq 0                          ; Null descriptor
gdt64_code: dq 0x00209A0000000000 ; Code segment
gdt64_data: dq 0x0000920000000000 ; Data segment
gdt64_end:

; CORREÇÃO: Usar dq (64 bits) para o ponteiro em modo longo
align 4
gdt64_descriptor: 
    dw gdt64_end - gdt64_start - 1
    dq gdt64_start

; --- SEÇÃO .text APENAS PARA CÓDIGO 64-BITS ---
section .text
[bits 64]

start_long_mode:
    mov ax, 0x10              ; Seletor de dados (segundo descritor)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov rsp, 0x90000          ; Configurar pilha em 64 bits

    ; Chama o Kernel C
    call kernel_main
    
.halt:
    hlt
    jmp .halt