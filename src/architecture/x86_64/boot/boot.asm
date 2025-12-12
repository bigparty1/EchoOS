;Autor: Kauê dos Santos Gomes
;Data: 12/12/2025
;Descrição: Bootloader Completo (Real Mode -> Protected Mode)

[org 0x7C00]
[bits 16]          ; Modo Real (16-bits)

KERNEL_LOW_MEM equ 0x1000

start:
    jmp 0:init_segments

init_segments:
    ; 1. Inicialização Limpa de Segmentos
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [BOOT_DISK], dl         ; Salva o ID do drive de boot

    ; 2. Mensagens Iniciais e Leitura de Disco
    mov bx, MSG_LOADING
    call bios_print
    call bios_wait
    
    call read_disk
    
    ; 3. Habilitar A20
    mov bx, MSG_A20
    call bios_print
    call bios_wait
    call enable_a20

    ; 4. Preparar para a Transição (GDT)
    mov bx, MSG_GDT
    call bios_print
    call bios_wait
    
    mov bx, MSG_PM
    call bios_print
    
    cli                     ; Desabilita interrupções
    lgdt [gdt_descriptor]   ; Carrega a GDT

    mov eax, cr0
    or eax, 1               ; Liga o bit de Modo Protegido
    mov cr0, eax

    jmp CODE_SEG:start_protected_mode ; Salta para o código de 32-bits


[bits 32]       ; Modo Protegido (32-bits)
start_protected_mode:
    ; 1. Recarregar Segmentos de DADOS com o seletor 0x10
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 2. Configurar Pilha Segura
    mov ebp, 0x90000
    mov esp, ebp

    ; 3. Limpa a tela e escrever na memória de vídeo (VGA)
    mov edi, 0xb8000
    mov ecx, 1000      
    mov eax, 0x0f200f20 
    rep stosd           

    mov byte [0xb8000], 'P'
    mov byte [0xb8001], 0x2f
    
    mov byte [0xb8002], 'M'
    mov byte [0xb8003], 0x2f
    
    mov byte [0xb8004], ' '
    mov byte [0xb8005], 0x2f
    
    mov byte [0xb8006], 'O'
    mov byte [0xb8007], 0x2f
    
    mov byte [0xb8008], 'K'
    mov byte [0xb8009], 0x2f

    jmp $ ; Trava infinita temporaria

; Rotinas de BIOS e Utilitários (Modo Real)
[bits 16]

read_disk:
    mov ah, 0x02
    mov bx, KERNEL_LOW_MEM
    mov al, 2
    mov ch, 0
    mov dh, 0
    mov cl, 2
    mov dl, [BOOT_DISK]
    int 0x13
    jc disk_error
    cmp al, 2
    jne disk_error
    ret

disk_error:
    mov bx, MSG_ERROR
    call bios_print
    jmp $

enable_a20:
    push ax
    mov ax, 0x2401
    int 0x15
    jnc .done
    in al, 0x92
    or al, 2
    out 0x92, al
.done:
    pop ax
    ret

bios_print:
    push ax
    push bx
    mov ah, 0x0E
.loop:
    mov al, [bx]
    test al, al
    jz .done
    int 0x10
    inc bx
    jmp .loop
.done:
    pop bx
    pop ax
    ret

bios_wait:
    push cx
    push dx
    push ax
    mov cx, 0x0007  ; ~0.5s
    mov dx, 0xA120
    mov ah, 0x86
    int 0x15
    pop ax
    pop dx
    pop cx
    ret

; Dados e Mensagens
BOOT_DISK:   db 0
MSG_LOADING: db "Loading...", 0x0D, 0x0A, 0
MSG_ERROR:   db "Disk Error!", 0x0D, 0x0A, 0
MSG_A20:     db "A20 OK...", 0x0D, 0x0A, 0
MSG_GDT:     db "GDT Load...", 0x0D, 0x0A, 0
MSG_PM:      db "Going to 32-bits...", 0x0D, 0x0A, 0


; GDT (Global Descriptor Table)
gdt_start:

gdt_null:
    dd 0x0
    dd 0x0

gdt_code:
    ; Base=0x0, Limit=0xFFFFF, Access=0x9A (Exec/Read), Flags=0xC (4KB blocks)
    dw 0xffff
    dw 0x0
    db 0x0
    db 10011010b
    db 11001111b
    db 0x0

gdt_data:
    ; Base=0x0, Limit=0xFFFFF, Access=0x92 (Read/Write), Flags=0xC
    dw 0xffff
    dw 0x0
    db 0x0
    db 10010010b
    db 11001111b
    db 0x0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start


; Padding e assinatura de boot sectors
times 510-($-$$) db 0
dw 0xAA55