#include <stdint.h>

// Definimos uma estrutura para representar um caractere na tela (Char + Cor)
struct Char {
    uint8_t character;
    uint8_t color;
};

// O buffer de vídeo VGA começa sempre em 0xB8000
struct Char* buffer = (struct Char*) 0xb8000;

// Definimos cores para facilitar
enum Color {
    PRINT_COLOR_BLACK = 0,
    PRINT_COLOR_WHITE = 15,
    PRINT_COLOR_RED = 4,
    PRINT_COLOR_CYAN = 3,
};

void clear_screen() {
    // A tela tem 25 linhas x 80 colunas
    for (int i = 0; i < 25 * 80; i++) {
        buffer[i].character = ' ';
        buffer[i].color = (PRINT_COLOR_BLACK << 4) | PRINT_COLOR_WHITE;
    }
}

void print_str(char* str, int color) {
    int i = 0;
    // Escreve até encontrar o caractere nulo \0
    while (str[i] != '\0') {
        buffer[i].character = str[i];
        buffer[i].color = color;
        i++;
    }
}

// Esta é a função que o Assembly vai chamar!
void kernel_main() {
    clear_screen();
    
    // Escreve algo vindo do C!
    // Cyan (3) sobre Preto
    print_str("Bem-vindo ao EchoOS - Agora em C (64-bit)!", (PRINT_COLOR_BLACK << 4) | PRINT_COLOR_CYAN);
    
    // Trava o sistema aqui
    while(1);
}