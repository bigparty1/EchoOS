#pragma once
#include <stdint.h>
#include <stddef.h>

#define TTY_ADDRESS 0xB8000
#define TTY_WIDTH 80
#define TTY_HEIGHT 25

/// @brief Codigos de cores do tty
enum tty_color {
    TTY_COLOR_BLACK = 0,
    TTY_COLOR_BLUE = 1,
    TTY_COLOR_GREEN = 2,
    TTY_COLOR_CYAN = 3,
    TTY_COLOR_RED = 4,
    TTY_COLOR_MAGENTA = 5,
    TTY_COLOR_BROWN = 6,
    TTY_COLOR_LIGHT_GREY = 7,
    TTY_COLOR_DARK_GREY = 8,
    TTY_COLOR_LIGHT_BLUE = 9,
    TTY_COLOR_LIGHT_GREEN = 10,
    TTY_COLOR_LIGHT_CYAN = 11,
    TTY_COLOR_LIGHT_RED = 12,
    TTY_COLOR_LIGHT_MAGENTA = 13,
    TTY_COLOR_LIGHT_BROWN = 14,
    TTY_COLOR_WHITE = 15,
};

/// @brief Combina as cores de primeiro plano e fundo em um unico byte
/// @param fg Cor de primeiro plano (Foreground)
/// @param bg Cor de segundo plano (Background)
/// @return Retorna o byte combinado
static inline uint8_t tty_entry_color(enum tty_color fg, enum tty_color bg) 
{
    return fg | (bg << 4);
}

/// @brief Combina um caractere e uma cor em uma entrada tty
/// @param uc Caractere a ser exibido
/// @param color Cor combinada (Foreground e Background)
/// @return Retorna a entrada tty combinada
static inline uint16_t tty_entry(unsigned char uc, uint8_t color) 
{
    return (uint16_t)uc | (uint16_t)color << 8;
}

/// @brief Retorna um ponteiro para o buffer de vídeo tty
/// @return Ponteiro para o buffer de vídeo tty
static inline uint16_t* get_tty_buffer() 
{
    return (uint16_t*)TTY_ADDRESS;
}

/// @brief Inicializa o terminal tty
void terminal_initialize();

/// @brief Coloca um caractere na posição especificada do terminal tty
/// @param c Caractere a ser colocado
/// @param color Cor combinada (Foreground e Background) 
/// @param x Posição horizontal (coluna)
/// @param y Posição vertical (linha)
void terminal_putentryat(char c, uint8_t color, size_t x, size_t y);

/// @brief Coloca um caractere no terminal tty na posição atual
/// @param c Caractere a ser colocado
void terminal_putchar(char c);

/// @brief Escreve uma string no terminal tty
/// @param data Ponteiro para a string a ser escrita
/// @param size Tamanho da string (padrão: -1, que indica string terminada em null ou '\0')
void terminal_write(const char* data, size_t size);

/// @brief Imprime uma string no terminal tty
/// @param data Ponteiro para a string a ser impressa
void terminal_print(const char* data);