#include "isr.h"
#include "../../driver/tty/tty.h"

// Lista de nomes para as exceções
const char* exception_messages[] = {
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment Not Present",
    "Stack Fault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",
    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved"
};

void isr_handler(isr_registers_t* regs) {
    // Se o número da interrupção for menor que 32, é uma EXCEÇÃO da CPU.
    if (regs->int_no < 32) {
        // Mudar cor para Vermelho (Erro Crítico)
        set_color(entry_color(TTY_COLOR_RED, TTY_COLOR_BLACK));
        
        print("\n[KERNEL PANIC] Excecao: ");
        print(exception_messages[regs->int_no]);
        print("\n");
        
        print("Sistema Parado.\n");
        
        // Loop infinito para travar o sistema (Halt)
        for (;;) {
            __asm__ volatile("hlt");
        }
    }
}