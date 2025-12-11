/*
Autor: Kauê dos Santos Gomes
Data: 11/12/2025
Descrição: Script de linkedição para o kernel em arquitetura x86_64
*/

ENTRY(start)

SECTIONS
{
    /* Kernel a partir do endereço 1MB */
    . = 1M;

    /* Seção de código */
    .text :
    {
        *(.text)
    }

    /* Seção de dados de leitura (Read-Only Data) */
    .rodata :
    {
        *(.rodata)
    }

    /* Seção de dados inializados */
    .data :
    {
        *(.data)
    }

    /* Seção de dados não inicializados (Black Started by Symbol) */
    .bss :
    {
        *(COMMON)
        *(.bss)
    }
}
