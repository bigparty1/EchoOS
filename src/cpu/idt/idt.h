#pragma once
#include <stdint.h>

struct idt_entry
{
    uint16_t base_low;    // Bits 0-15 do endereço do handler
    uint16_t selector;    // Seletor de segmento
    uint8_t ist;          // Interrupt Stack Table
    uint8_t flags;        // Tipo e atributos
    uint16_t base_mid;    // Bits 16-31 do endereço do handler
    uint32_t base_high;   // Bits 32-63 do endereço do handler
    uint32_t reserved;    // Reservado, deve ser zero
} __attribute__((packed));

struct idt_ptr
{
    uint16_t limit;       // Limite da IDT
    uint64_t base;        // Endereço base da IDT
} __attribute__((packed));

/// @brief Inicializa a Interrupt Descriptor Table (IDT)
void idt_init();