#include "../driver/tty/tty.h"
#include "../cpu/gdt/gdt.h"
#include "../cpu/idt/idt.h"

void kernel_main() {
    initialize();
    
    print("Inicializando EchoOS ...\n");

    gdt_init();
    print("GDT inicializada com sucesso.\n");

    idt_init();
    print("IDT inicializada com sucesso.\n");

    // __asm__ volatile ("int $3");

    while(1);
}
