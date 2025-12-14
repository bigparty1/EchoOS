#include "gdt.h"

struct gdt_entry gdt[3];
struct gdt_ptr gdtr;

/// @brief Carrega o novo GDT (Função implementada em assembly)
/// @param  ptr Endereço do descritor da GDT
extern void gdt_flush(uint64_t);

/// @brief Inicializa a Global Descriptor Table (GDT)
/// @param num Índice da entrada na GDT
/// @param base Endereço base do segmento
/// @param limit Limite do segmento
/// @param access Byte de acesso
/// @param granularity Granularidade do segmento
static void gdt_set_gate(int32_t num, uint64_t base, uint64_t limit, uint8_t access, uint8_t granularity) 
{
    gdt[num].base_low    = (base & 0xFFFF);
    gdt[num].base_middle = (base >> 16) & 0xFF;
    gdt[num].base_high   = (base >> 24) & 0xFF;
    gdt[num].limit_low   = (limit & 0xFFFF);
    gdt[num].granularity = (limit >> 16) & 0x0F;
    gdt[num].granularity |= granularity & 0xF0;
    gdt[num].access      = access;
}

void gdt_init() 
{
    gdtr.limit = (sizeof(struct gdt_entry) * 3) - 1;
    gdtr.base  = (uint64_t)&gdt;

    // 0: NULL Descriptor (Obrigatório ser tudo zero)
    gdt_set_gate(0, 0, 0, 0, 0);

    // 1: Kernel Code Segment (0x08)
    // Access 0x9A: Presente(1), Ring0(00), Code/Exec(1), Readable(1)
    // Gran 0xAF: 4KB Units(1), 64-bit Long Mode(1)
    gdt_set_gate(1, 0, 0, 0x9A, 0xAF);

    // 2: Kernel Data Segment (0x10)
    // Access 0x92: Presente(1), Ring0(00), Data(1), Writable(1)
    gdt_set_gate(2, 0, 0, 0x92, 0x00);

    // Carrega a nova GDT
    gdt_flush((uint64_t)&gdtr);
}