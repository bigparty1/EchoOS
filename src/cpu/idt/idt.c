#include "idt.h"

struct idt_entry idt[256];
struct idt_ptr idtr;

extern void idt_flush(uint64_t);

void idt_set_gate(int32_t num, uint64_t base, uint16_t selector, uint8_t flags) 
{
    idt[num].base_low  = (base & 0xFFFF);
    idt[num].base_mid  = (base >> 16) & 0xFFFF;
    idt[num].base_high = (base >> 32) & 0xFFFFFFFF;
    idt[num].selector  = selector;
    idt[num].ist       = 0;
    idt[num].flags     = flags;
    idt[num].reserved  = 0;
}

void idt_init() 
{
    idtr.limit = (sizeof(struct idt_entry) * 256) - 1;
    idtr.base  = (uint64_t)&idt;

    // Inicializa todas as entradas da IDT com zeros
    for (int i = 0; i < 256; i++) {
        idt_set_gate(i, 0, 0, 0);
    }

    // Carrega a nova IDT
    idt_flush((uint64_t)&idtr);
}