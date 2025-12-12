;Autor: Kauê dos Santos Gomes
;Data: 11/12/2025
;Descrição: Bootloader stage 1 (Real Mode)

[org 0x7c00]
[bits 16]

KERNEL_LOCATION equ 0x1000

start:
    jmp 0:init_segments

init_segments:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov [BOOT_DISK], dl         ; Salva o ID do drive de boot

    ; 1. Resetar o Disco (Boa prática)
    mov ah, 0
    int 0x13

    ; 2. Carregar o Stage 2 (e o Kernel futuro) do disco
    ; Vamos ler 50 setores (aprox 25KB) para garantir que pegamos tudo
    mov bx, KERNEL_LOCATION ; Destino: 0x1000
    mov al, 10              ; Quantidade: 10 setores
    mov ch, 0
    mov dh, 0
    mov cl, 2               ; Começa do setor 2
    mov dl, [BOOT_DISK]
    mov ah, 0x02            ; Função READ
    int 0x13
    jc disk_error

    ; 3. Pular para o Stage 2
    jmp KERNEL_LOCATION     ; Pula para 0x1000

disk_error:
    mov ah, 0x0e
    mov al, 'E'
    int 0x10
    jmp $

BOOT_DISK: db 0

times 510-($-$$) db 0
dw 0xaa55
