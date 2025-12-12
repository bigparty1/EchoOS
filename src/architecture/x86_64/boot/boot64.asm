;Autor: Kauê dos Santos Gomes
;Data: 12/12/2025
;Descrição: Bootloader stage 2 (Protected Mode / Long Mode)

[org 0x1000]
[bits 16]

start_stage2:
    ; Segurança: Limpar segmentos
    xor ax, ax
    mov ds, ax
    mov es, ax

    call enable_a20

    cli
    lgdt [gdt_descriptor]
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Agora que a GDT vai estar correta, podemos usar a sintaxe limpa.
    ; O "dword" força o assembler a gerar o offset correto de 32 bits.
    jmp dword CODE_SEG:start_protected_mode

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

; --- GDT 32 (AQUI ESTAVA O ERRO) ---
gdt_start:
gdt_null: 
    dd 0, 0

gdt_code: 
    dw 0xffff       ; Limit (0-15)
    dw 0x0000       ; Base (0-15)
    db 0x00         ; Base (16-23) - IMPORTANTE: db, não dw!
    db 10011010b    ; Access (Present, Ring0, Code, Exec/Read)
    db 11001111b    ; Flags (4KB, 32-bit) + Limit (16-19)
    db 0x00         ; Base (24-31)

gdt_data: 
    dw 0xffff       ; Limit (0-15)
    dw 0x0000       ; Base (0-15)
    db 0x00         ; Base (16-23)
    db 10010010b    ; Access (Present, Ring0, Data, Read/Write)
    db 11001111b    ; Flags (4KB, 32-bit) + Limit (16-19)
    db 0x00         ; Base (24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; -----------------------------------------------------------------------------
; 32-BITS
; -----------------------------------------------------------------------------
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

    ; 1. Configurar as tabelas de página
    call setup_paging

    ; 2. Ativar Paginação e Long Mode
    call enable_paging_mode
    
    ; Carregar GDT 64
    lgdt [gdt64_descriptor]
    jmp 0x08:start_long_mode

; --- Configuração 64-bits ---
setup_paging:
    mov edi, 0x2000
    xor eax, eax
    mov ecx, 3072
    rep stosd
    
    mov eax, 0x3003      ; PML4 -> PDP
    mov [0x2000], eax
    
    mov eax, 0x4003      ; PDP -> PD
    mov [0x3000], eax
    
    mov eax, 0x83        ; PD -> 2MB Page
    mov [0x4000], eax
    ret

enable_paging_mode:
    mov eax, 0x2000
    mov cr3, eax
    
    mov eax, cr4
    or eax, 1 << 5       ; PAE
    mov cr4, eax
    
    mov ecx, 0xC0000080  ; EFER
    rdmsr
    or eax, 1 << 8       ; LME
    wrmsr
    
    mov eax, cr0
    or eax, 1 << 31      ; PG
    mov cr0, eax
    ret

; --- GDT 64 ---
gdt64_start:
    dq 0
gdt64_code: dq 0x00209A0000000000 ; Exec + Read
gdt64_data: dq 0x0000920000000000 ; Read + Write
gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start

; -----------------------------------------------------------------------------
; 64-BITS (LONG MODE)
; -----------------------------------------------------------------------------
[bits 64]
start_long_mode:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Limpar tela AZUL
    mov edi, 0xb8000
    mov rax, 0x1f201f201f201f20 
    mov ecx, 500
    rep stosq

    ; Escrever "OK 64"
    mov rax, 0x1f201f341f361f20 
    mov [0xb8000], rax
    
    jmp $