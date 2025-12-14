#pragma once
#include <stdint.h>

typedef struct
{
    // Carregado pelo isr_common_stub
    // uint64_t r15, r14, r13, r12, r11, r10, r9, r8;
    // uint64_t rdi, rsi, rbp, rdx, rcx, rbx, rax;
    uint64_t rax, rbx, rcx, rdx, rbp, rsi, rdi;
    uint64_t r8, r9, r10, r11, r12, r13, r14, r15;

    // Carregado pelos macros ISR_NOERRCODE / ISR_ERRCODE
    uint64_t int_no, err_code;

    // Carregado automaticamente pela CPU
    uint64_t rip;
    uint64_t cs;
    uint64_t rflags;
    uint64_t rsp;
    uint64_t ss;
}isr_registers_t;

/// @brief Gerenciador de interrupções do sistema
/// @param regs Ponteiro para a estrutura de registradores
void isr_handler(isr_registers_t* regs);