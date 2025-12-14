#pragma once
#include <stdint.h>

struct gdt_entry {
    uint16_t limit_low;      // Limite inferior do segmento
    uint16_t base_low;       // Base inferior do segmento
    uint8_t  base_middle;    // Base média do segmento
    uint8_t  access;         // Byte de acesso
    uint8_t  granularity;    // Granularidade e limite superior
    uint8_t  base_high;      // Base superior do segmento
} __attribute__((packed));

struct gdt_ptr {
    uint16_t limit;          // Limite do GDT
    uint64_t base;           // Endereço base do GDT
} __attribute__((packed));

/// @brief Inicializa a Global Descriptor Table (GDT)
void gdt_init();




