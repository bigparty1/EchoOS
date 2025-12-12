/*
 * Autor: Kauê dos Santos Gomes
 * Data: 12/12/2025
 * Descrição: Implementação do driver do terminal tty
 */

#include "tty.h"

size_t terminal_row;
size_t terminal_column;
uint8_t terminal_color;
uint16_t* terminal_buffer;

void terminal_initialize() 
{
    terminal_row = 0;
    terminal_column = 0;
    terminal_color = tty_entry_color(TTY_COLOR_LIGHT_GREY, TTY_COLOR_BLACK);
    terminal_buffer = get_tty_buffer();
    for (size_t y = 0; y < TTY_HEIGHT; y++) 
    {
        for (size_t x = 0; x < TTY_WIDTH; x++) 
        {
            const size_t index = y * TTY_WIDTH + x;
            terminal_buffer[index] = tty_entry(' ', terminal_color);
        }
    }
}

void terminal_putentryat(char c, uint8_t color, size_t x, size_t y) 
{
    const size_t index = y * TTY_WIDTH + x;
    terminal_buffer[index] = tty_entry(c, color);
}

void terminal_putchar(char c) 
{
    if (c == '\n') 
    {
        terminal_column = 0;
        terminal_row++;
        if (terminal_row == TTY_HEIGHT) {
            terminal_scroll();
            terminal_row = TTY_HEIGHT - 1;
        }
        return;
    }

    terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
    terminal_column++;

    if (terminal_column == TTY_WIDTH) 
    {
        terminal_column = 0;
        terminal_row++;
        if (terminal_row == TTY_HEIGHT) 
        {
            terminal_scroll();
            terminal_row = TTY_HEIGHT - 1;
        }
    }
}

void terminal_write(const char* data, size_t size) 
{
    if(data == NULL) 
    {
        return;
    }
    for (size_t i = 0; i < size; i++) 
    {
        if(data[i] == '\0') 
        {
            break;
        }
        terminal_putchar(data[i]);
    }
}

void terminal_print(const char* data)
{
    if(data == NULL) 
    {
        return;
    }
    for (size_t i = 0; data[i] != '\0'; i++)
    {
        terminal_putchar(data[i]);
    }
}

void terminal_scroll() 
{
    for (size_t y = 0; y < TTY_HEIGHT - 1; y++) {
        for (size_t x = 0; x < TTY_WIDTH; x++) {
            const size_t src = (y + 1) * TTY_WIDTH + x;
            const size_t dst = y * TTY_WIDTH + x;
            terminal_buffer[dst] = terminal_buffer[src];
        }
    }

    size_t last_row = (TTY_HEIGHT - 1) * TTY_WIDTH;
    for (size_t x = 0; x < TTY_WIDTH; x++) {
        terminal_buffer[last_row + x] = tty_entry(' ', terminal_color);
    }
}