;Autor: Kauê dos Santos Gomes
;Data: 11/12/2025
;Descrição: Código de boot para arquitetura x86_64

[org 0x7C00]                                    ; Endereço de carregamento do bootloader
KERNEL_LOW_MEM equ 0x1000                       ; Endereço onde o kernel será carregado (temporário, buffer de carga)

start:
    jmp 0:init_segments                         ; Far jump para inicializar segmentos

init_segments:
    cli                                         ; Desabilita interrupções
    xor ax, ax                                  ; Zera o registrador AX
    mov ds, ax                                  ; Configura o segmento de dados
    mov es, ax                                  ; Configura o segmento extra
    mov fs, ax                                  ; Configura o segmento FS
    mov gs, ax                                  ; Configura o segmento GS
    mov ss, ax                                  ; Configura o segmento de pilha
    mov sp, 0x7C00                              ; Inicializa o ponteiro de pilha
    sti                                         ; Habilita interrupções

    call delay_0_5s                             ; Espera 0,5 segundos

    mov [BOOT_DISK], dl                         ; Armazena o ID do disco de boot

    mov bx, MSG_LOADING                         ; Mensagem de carregamento
    call print_string                           ; Imprime a mensagem de carregamento

    call delay_0_5s                             ; Espera 0,5 segundos

    call read_disk                              ; Lê o kernel do disco para a memória

    call delay_0_5s                             ; Espera 0,5 segundos
    mov bx, MSG_SUCCESS                         ; Mensagem de sucesso
    call print_string                           ; Imprime a mensagem de sucesso

    call delay_0_5s                             ; Espera 0,5 segundos

    ; Aqui, futuramente, vamos mudar para 32-bits/64-bits 
    ; e mover o kernel de 0x1000 para 0x100000 (1MB)
    
    jmp $ ; Loop infinito por enquanto

; Rotina para ler o kernel do disco
read_disk:
    mov ah, 0x02                             ; Função de leitura de setores
    mov bx, KERNEL_LOW_MEM                   ; Endereço de destino
    mov al, 2                                ; Número de setores a ler
    mov ch, 0                                ; Cilindro 0
    mov dh, 0                                ; Cabeça 0
    mov cl, 2                                ; Setor 2 (setores começam em 1 no BIOS)
    mov dl, [BOOT_DISK]                      ; Disco de boot
    int 0x13                                 ; Chamada de interrupção do BIOS
    jc disk_error                            ; Se houver erro, salta para disk_error
    cmp al, 2                                ; Verifica se leu 2 setores
    jne disk_error                           ; Se não, salta para disk_error
    ret

; Rotina de erro de disco
disk_error:
    mov bx, MSG_ERROR                        ; Mensagem de erro
    call print_string                        ; Imprime a mensagem de erro
    jmp $                                    ; Loop infinito

; Rotina para imprimir uma string terminada em zero
print_string:
    push ax
    push bx
    mov ah, 0x0E                          ; Função de impressão de caractere
.loop_print:
    mov al, [bx]                          ; Carrega o próximo caractere
    test al, al                           ; Verifica se é o terminador
    je .done_print                        ; Se for, termina
    int 0x10                              ; Chamada de interrupção do BIOS para imprimir
    inc bx                                ; Próximo caractere
    jmp .loop_print                       ; Repete
.done_print:
    pop bx
    pop ax
    ret

; Espera 1,5 segundos
delay_0_5s:
    push cx
    push dx
    mov cx, 0x0007
    mov dx, 0xA120
    call wait_time
    pop dx
    pop cx
    ret

; Espera em microsegundos, tempo definido em cx:dx, sendo cx a parte alta e dx a baixa
wait_time:
    push ax
    mov ah, 0x86                          ; Função de espera
    int 0x15                              ; Chamada de interrupção do BIOS
    pop ax
    ret

; Dados
BOOT_DISK     db 0                              ; Armazena o ID do disco de boot
MSG_LOADING   db "Carregando o kernel...", 0x0D, 0x0A, 0
MSG_ERROR     db "Erro ao carregar o kernel!", 0x0D, 0x0A, 0
MSG_SUCCESS   db "Kernel carregado com sucesso!", 0x0D, 0x0A, 0

; Assinatura para o final do setor de boot
times 510-($-$$) db 0                      ; Preenche até o byte 510 com zeros
dw 0xAA55                                  ; Assinatura do setor de boot
