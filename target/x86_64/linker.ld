/*
Autor: Kauê dos Santos Gomes
Data: 11/12/2025
Descrição: Script de linkedição para o kernel em arquitetura x86_64
*/

ENTRY(start)

SECTIONS
{
    /* Kernel a partir do endereço 0x1000 */
    . = 0x1000;

    /* Seção de código */
    .text : ALIGN(16)
    {
        *(.boot)
        *(.text)
    }

    /* Seção de dados de leitura (Read-Only Data) */
    .rodata : ALIGN(8)
    {
        *(.rodata*)
    }

    /* Seção de dados inializados - SEM alinhamento grande */
    .data : ALIGN(8)
    {
        *(.data)
    }

    /* Seção de dados não inicializados */
    .bss : ALIGN(8)
    {
        __bss_start = .;
        *(COMMON)
        *(.bss)
        __bss_end = .;
    }

    /* Descartar seções desnecessárias */
    /DISCARD/ :
    {
        *(.eh_frame)
        *(.comment)
        *(.note*)
    }
}
