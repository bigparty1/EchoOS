[bits 64]
global idt_flush

idt_flush:
    ; Carrega o IDT a partir do ponteiro em RDI
    lidt [rdi]
    ret