[bits 64]

; ==============================================================================
; Arquivo: isr_interrupts.asm
; Descrição: Implementação de baixo nível das Interrupções de Serviço (ISRs)
;            para o kernel. Este arquivo lida com a parte crítica de Assembly
;            que a CPU exige ao tratar exceções e interrupções.
; ==============================================================================

; Exporta os símbolos para que o linker saiba que estas funções existem
; e podem ser chamadas de outros arquivos (ex: idt.asm ou kernel.c).
global idt_flush
global isr0
global isr1
global isr2
global isr3
global isr4
global isr5
global isr6
global isr7
global isr8
global isr9
global isr10
global isr11
global isr12
global isr13
global isr14
global isr15
global isr16
global isr17
global isr18
global isr19
global isr20
global isr21
global isr22
global isr23
global isr24
global isr25
global isr26
global isr27
global isr28
global isr29
global isr30
global isr31

; ==============================================================================
; MACROS: Geradores de ISRs
; ==============================================================================

; Macro para exceções que NÃO geram um código de erro na pilha da CPU.
; Ex: Divisão por zero, Debug, etc.
; Como o handler em C espera sempre um código de erro, empurramos um '0' falso.
%macro ISR_NOERRCODE 1
    global isr%1
    isr%1:
        cli             ; Desliga interrupções para evitar aninhamento indesejado
        push 0          ; Empurra um código de erro "dummy" (0) para padronizar a pilha
        push %1         ; Empurra o número da interrupção (ex: 0, 1, 2...)
        jmp isr_common_stub ; Salta para o código comum que salva o contexto
%endmacro

; Macro para exceções que TÊM código de erro da CPU.
; Ex: Page Fault, General Protection Fault.
; A CPU já empurrou o erro automaticamente, então não precisamos do dummy.
%macro ISR_ERRCODE 1
    global isr%1
    isr%1:
        cli             ; Desliga interrupções
        ; A CPU já empurrou o código de erro na pilha automaticamente
        push %1         ; Empurra o número da interrupção
        jmp isr_common_stub
%endmacro

; ==============================================================================
; DEFINIÇÃO DAS 32 EXCEÇÕES (INTERRUPÇÕES)
; ==============================================================================

; 0-7: Exceções sem código de erro
ISR_NOERRCODE 0   ; #DE - Divisão por Zero (Divide Error)
ISR_NOERRCODE 1   ; #DB - Debug (Breakpoint)
ISR_NOERRCODE 2   ; #NMI - Non-Maskable Interrupt
ISR_NOERRCODE 3   ; #BP - Breakpoint
ISR_NOERRCODE 4   ; #OF - Overflow
ISR_NOERRCODE 5   ; #BR - Bound Range Exceeded
ISR_NOERRCODE 6   ; #UD - Invalid Opcode (Instruction Undefined)
ISR_NOERRCODE 7   ; #NM - Device Not Available (x87 FPU / SIMD)

; 8: Double Fault (Tem erro)
ISR_ERRCODE   8   ; #DF - Double Fault (Falha dupla, grave)

; 9: Coprocessor Segment Overrun (Sem erro)
ISR_NOERRCODE 9   ; #TS - Coprocessor Segment Overrun

; 10-11: Invalid TSS / Segment Not Present (Tem erro)
ISR_ERRCODE   10  ; #TS - Invalid TSS (Task State Segment)
ISR_ERRCODE   11  ; #NP - Segment Not Present

; 12-13: Stack-Segment Fault / GPF (Tem erro)
ISR_ERRCODE   12  ; #SS - Stack-Segment Fault
ISR_ERRCODE   13  ; #GP - General Protection Fault (GPF) - Muito comum!

; 14: Page Fault (Tem erro) - O mais importante para gerenciamento de memória
ISR_ERRCODE   14  ; #PF - Page Fault (Acesso a memória inválida)

; 15: Reservado (Sem erro)
ISR_NOERRCODE 15  ; #RS - Reserved

; 16: x87 FPU Error (Sem erro)
ISR_NOERRCODE 16  ; #MF - x87 FPU / SIMD Floating-Point Exception

; 17: Alignment Check (Tem erro)
ISR_ERRCODE   17  ; #AC - Alignment Check

; 18-20: Machine Check / SIMD / Virtualization (Sem erro)
ISR_NOERRCODE 18  ; #MC - Machine Check Exception
ISR_NOERRCODE 19  ; #XM - SIMD Floating-Point Exception
ISR_NOERRCODE 20  ; #VE - Virtualization Exception

; 21-29: Reservados (Sem erro)
ISR_NOERRCODE 21  ; #RS - Reserved
ISR_NOERRCODE 22  ; #RS - Reserved
ISR_NOERRCODE 23  ; #RS - Reserved
ISR_NOERRCODE 24  ; #RS - Reserved
ISR_NOERRCODE 25  ; #RS - Reserved
ISR_NOERRCODE 26  ; #RS - Reserved
ISR_NOERRCODE 27  ; #RS - Reserved
ISR_NOERRCODE 28  ; #RS - Reserved
ISR_NOERRCODE 29  ; #RS - Reserved

; 30: Security Exception (Tem erro)
ISR_ERRCODE   30  ; #SX - Security Exception

; 31: Reservado (Sem erro)
ISR_NOERRCODE 31  ; #RS - Reserved

; ==============================================================================
; STUB COMUM (isr_common_stub)
; ==============================================================================

; Declara que a função 'isr_handler' existe em outro arquivo (provavelmente em C).
; Ela será chamada após salvarmos o contexto da CPU.
extern isr_handler 

isr_common_stub:
    ; --------------------------------------------------------------------------
    ; 1. SALVAR O CONTEXTO (Context Save)
    ; --------------------------------------------------------------------------
    ; Precisamos salvar todos os registradores porque o código em C pode
    ; modificá-los. Se não salvássemos, o programa que estava rodando
    ; antes da interrupção ficaria corrompido.
    ; A ordem é importante: o último empurrado será o primeiro a ser restaurado.
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rdi
    push rsi
    push rbp
    push rdx
    push rcx
    push rbx
    push rax

    ; --------------------------------------------------------------------------
    ; 2. CHAMAR O HANDLER EM C
    ; --------------------------------------------------------------------------
    ; A convenção de chamada do GCC (System V AMD64 ABI) diz que o primeiro
    ; argumento deve estar no registrador RDI.
    ; Nós passamos o endereço do topo da pilha (RSP), que agora aponta para
    ; a estrutura de dados contendo o código de erro, número da ISR e os registradores.
    mov rdi, rsp
    
    ; Chama a função em C que vai processar a interrupção (logar, panic, etc.)
    call isr_handler

    ; --------------------------------------------------------------------------
    ; 3. RESTAURAR O CONTEXTO (Context Restore)
    ; --------------------------------------------------------------------------
    ; Após o retorno do C, restauramos os registradores na ordem inversa.
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rbp
    pop rsi
    pop rdi
    pop r8
    pop r9
    pop r10
    pop r11
    pop r12
    pop r13
    pop r14
    pop r15

    ; --------------------------------------------------------------------------
    ; 4. LIMPEZA DA PILHA (Stack Cleanup)
    ; --------------------------------------------------------------------------
    ; A pilha contém: [Registradores] [Número da ISR] [Código de Erro]
    ; Nós já restauramos os registradores com 'pop'.
    ; Agora precisamos remover o Número da ISR e o Código de Erro para que
    ; a pilha esteja limpa para o 'iretq'.
    ; Cada valor é 64 bits (8 bytes). 2 valores = 16 bytes.
    add rsp, 16 

    ; --------------------------------------------------------------------------
    ; 5. RETORNO DA INTERRUPÇÃO
    ; --------------------------------------------------------------------------
    ; 'iretq' (Interrupt Return for 64-bit) recupera o RIP, CS e RFLAGS
    ; da pilha e retorna ao código que estava executando antes da interrupção.
    iretq