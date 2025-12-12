# Guia de Debug - Índice

## Visão Geral

Este diretório contém documentação detalhada sobre ferramentas e técnicas de debug para desenvolvimento de sistemas operacionais na arquitetura x86/x86-64.

---

## Documentos Disponíveis

### [qemu-debug.md](./qemu-debug.md)
Guia completo sobre debug com QEMU, incluindo:
- Flags de debug (`-d int`, `-d cpu_reset`, etc.)
- Interpretação de dumps de CPU
- Conexão com GDB
- Comandos úteis para filtrar logs

### [objdump.md](./objdump.md)
Guia sobre análise de binários com objdump:
- Disassembly de arquivos ELF
- Exame de headers e símbolos
- Sintaxe AT&T vs Intel
- Identificação de problemas de geração de código

### [xxd.md](./xxd.md)
Guia sobre análise hexadecimal com xxd:
- Dumps hexadecimais de binários
- Análise de estruturas (GDT, page tables)
- Verificação de bytes específicos
- Conversão hex ↔ binário

### [ndisasm.md](./ndisasm.md)
Guia sobre disassembly com ndisasm:
- Disassembly de binários raw
- Suporte a código 16/32/64-bit
- Análise de bootloaders
- Comparação com objdump

### [exception-codes.md](./exception-codes.md)
Referência completa de exceções x86:
- Tabela de todos os exception vectors
- Interpretação de error codes
- Causas comuns de cada exceção
- Debug de #GP, #PF, Triple Fault

---

## Fluxo de Debug Recomendado

### 1. Sistema Reiniciando (Triple Fault)

```bash
# Primeiro, capture o log de exceções
qemu-system-x86_64 -d int,cpu_reset -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | tail -100
```

Procure por:
- `check_exception` - qual exceção ocorreu?
- `Triple fault` - confirma que é triple fault
- `EIP` - onde estava executando?

### 2. Identificar a Exceção

Consulte [exception-codes.md](./exception-codes.md) para entender:
- O que significa o vector (`v=0d` = #GP)
- O que significa o error code (`e=0008`)
- Quais são as causas comuns

### 3. Analisar o Código

```bash
# Se é código de boot (16-bit)
ndisasm -b 16 -o 0x1000 build/kernel.bin | head -50

# Se é código protegido (32-bit)
ndisasm -b 32 -o 0x1053 -k 0x53 build/kernel.bin | head -50

# Para ver símbolos e seções
objdump -d build/kernel_full.o | head -100
```

### 4. Verificar Estruturas de Dados

```bash
# Examinar GDT
xxd -s OFFSET_GDT -l 32 build/kernel.bin

# Verificar page tables
xxd -s OFFSET_PML4 -l 16 build/kernel.bin
```

### 5. Debug Interativo (se necessário)

```bash
# Iniciar QEMU com GDB server
qemu-system-x86_64 -s -S -drive format=raw,file=build/os.bin

# Em outro terminal
gdb
(gdb) target remote localhost:1234
(gdb) break *0x1000
(gdb) continue
```

---

## Problemas Comuns e Soluções Rápidas

| Problema | Documento | Seção |
|----------|-----------|-------|
| Triple fault no boot | [qemu-debug.md](./qemu-debug.md) | Interpretando Saída |
| #GP após far jump | [exception-codes.md](./exception-codes.md) | #GP - General Protection |
| Código 16-bit aparece errado | [ndisasm.md](./ndisasm.md) | Por que usar ndisasm |
| GDT mal configurada | [xxd.md](./xxd.md) | Examinar a GDT |
| Page fault ao habilitar paging | [exception-codes.md](./exception-codes.md) | #PF - Page Fault |

---

## Ferramentas Necessárias

Certifique-se de ter instalado:

```bash
# QEMU
sudo apt install qemu-system-x86

# Binutils (objdump, etc.)
sudo apt install binutils

# NASM (inclui ndisasm)
sudo apt install nasm

# xxd (geralmente vem com vim)
sudo apt install xxd
# ou
sudo apt install vim

# GDB (para debug interativo)
sudo apt install gdb
```

---

## Comandos de Referência Rápida

```bash
# Debug com QEMU
qemu-system-x86_64 -d int,cpu_reset -no-reboot -drive format=raw,file=build/os.bin

# Disassembly ELF
objdump -d -M intel build/kernel_full.o

# Disassembly raw 16-bit
ndisasm -b 16 -o 0x1000 build/kernel.bin

# Dump hexadecimal
xxd -l 64 build/kernel.bin

# Ver seção específica
xxd -s 0x2d -l 24 build/kernel.bin
```

---

## Contribuindo

Ao adicionar novos documentos de debug:

1. Siga o formato Markdown existente
2. Inclua exemplos práticos
3. Explique a interpretação das saídas
4. Adicione referências a manuais oficiais
5. Atualize este índice
