#include "../driver/tty/tty.h"

void kernel_main() {
    terminal_initialize();
    
    // Passamos 0 no tamanho para ele calcular sozinho com o strlen que fizemos
    terminal_print("EchoOS Kernel v0.2\n"); 
    // terminal_write("------------------\n", 0);
    
    // Teste do scroll: Vamos imprimir 30 linhas
    // for(int i = 0; i < 30; i++) {
    //     terminal_write("Linha de teste de scroll... ", 0);
    //     // Um truque simples para imprimir numero (ja que nao temos printf ainda)
    //     char c = '0' + (i % 10);
    //     terminal_putchar(c);
    //     terminal_putchar('\n');
    // }

    while(1);
}
