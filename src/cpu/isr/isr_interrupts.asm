[bits 64]
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

; Macro para exceções que NÃO TÊM código de erro da CPU
%macro ISR_NOERRCODE 1
    global isr%1
    isr%1:
        cli             ; Desliga interrupções
        push 0          ; Empurra dummy error code
        push %1         ; Empurra o número da interrupção
        jmp isr_common_stub
%endmacro

; Macro para exceções que TÊM código de erro da CPU
%macro ISR_ERRCODE 1
    global isr%1
    isr%1:
        cli
        ; Obs.: A CPU já empurrou o código de erro, não precisamos do dummy
        push %1         ; Empurra o número da interrupção
        jmp isr_common_stub
%endmacro

; --- DEFINIÇÃO DAS 32 EXCEÇÕES ---
ISR_NOERRCODE 0   ; Divisão por Zero
ISR_NOERRCODE 1   ; Debug
ISR_NOERRCODE 2   ; NMI
ISR_NOERRCODE 3   ; Breakpoint
ISR_NOERRCODE 4   ; Overflow
ISR_NOERRCODE 5   ; Bound Range
ISR_NOERRCODE 6   ; Invalid Opcode
ISR_NOERRCODE 7   ; Device Not Available
ISR_ERRCODE   8   ; Double Fault (Tem erro)
ISR_NOERRCODE 9   ; Coprocessor Segment Overrun
ISR_ERRCODE   10  ; Invalid TSS (Tem erro)
ISR_ERRCODE   11  ; Segment Not Present (Tem erro)
ISR_ERRCODE   12  ; Stack-Segment Fault (Tem erro)
ISR_ERRCODE   13  ; General Protection Fault (GPF) (Tem erro)
ISR_ERRCODE   14  ; Page Fault (Tem erro)
ISR_NOERRCODE 15  ; Reservado
ISR_NOERRCODE 16  ; x87 FPU Error
ISR_ERRCODE   17  ; Alignment Check
ISR_NOERRCODE 18  ; Machine Check
ISR_NOERRCODE 19  ; SIMD Float Exception
ISR_NOERRCODE 20  ; Virtualization Exception
ISR_NOERRCODE 21  ; Reservado
ISR_NOERRCODE 22  ; Reservado
ISR_NOERRCODE 23  ; Reservado
ISR_NOERRCODE 24  ; Reservado
ISR_NOERRCODE 25  ; Reservado
ISR_NOERRCODE 26  ; Reservado
ISR_NOERRCODE 27  ; Reservado
ISR_NOERRCODE 28  ; Reservado
ISR_NOERRCODE 29  ; Reservado
ISR_ERRCODE   30  ; Security Exception
ISR_NOERRCODE 31  ; Reservado

; Função C chamada por todas as ISRs
extern isr_handler 

isr_common_stub:
    ; 1. Salvar TODO o estado dos registradores (Context Save)
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

    ; 2. Chamar o Kernel em C
    ; O GCC espera que o primeiro argumento esteja em RDI.
    ; RSP aponta para o topo da pilha, onde salvamos tudo isso.
    mov rdi, rsp
    call isr_handler

    ; 3. Restaurar TODO o estado (Context Restore)
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

    ; Remove o código de erro e o número da ISR da pilha (2 valores de 64 bits = 16 bytes)
    add rsp, 16 

    ; Retorna da interrupção (Recupera RIP, CS, RFLAGS)
    iretq