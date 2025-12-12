# Debug com objdump

## Visão Geral

O `objdump` é uma ferramenta do GNU Binutils que permite examinar arquivos objeto (`.o`) e executáveis. É essencial para:

1. Ver o código assembly gerado pelo assembler/compilador
2. Verificar endereços de símbolos
3. Examinar seções do binário
4. Identificar problemas de geração de código

---

## Comandos Principais

### Disassembly Completo (`-d`)

Mostra o código assembly de todas as seções executáveis:

```bash
objdump -d arquivo.o
```

#### Exemplo de Saída
```
build/kernel_full.o:     file format elf64-x86-64

Disassembly of section .text:

0000000000001000 <start>:
    1000:       31 c0                   xor    %eax,%eax
    1002:       8e d8                   mov    %eax,%ds
    1004:       8e c0                   mov    %eax,%es
```

#### Interpretação das Colunas

| Coluna | Descrição |
|--------|-----------|
| `1000:` | Endereço virtual da instrução |
| `31 c0` | Bytes de máquina (opcodes) |
| `xor %eax,%eax` | Instrução assembly (sintaxe AT&T) |

---

### Disassembly com Sintaxe Intel (`-M intel`)

Por padrão, `objdump` usa sintaxe AT&T. Para usar sintaxe Intel (mais comum em desenvolvimento x86):

```bash
objdump -d -M intel arquivo.o
```

#### Comparação AT&T vs Intel

| AT&T | Intel |
|------|-------|
| `mov %eax, %ebx` | `mov ebx, eax` |
| `mov $0x10, %ax` | `mov ax, 0x10` |
| `mov (%edi), %eax` | `mov eax, [edi]` |

**Diferenças principais:**
- AT&T: fonte → destino
- Intel: destino ← fonte
- AT&T: prefixo `$` para imediatos, `%` para registradores
- Intel: sem prefixos

---

### Mostrar Todas as Seções (`-D`)

Disassembla **todas** as seções, não apenas as executáveis:

```bash
objdump -D arquivo.o
```

Útil para examinar:
- Seção `.data` (dados inicializados)
- Seção `.rodata` (dados somente leitura)
- Seção `.bss` (dados não inicializados)
- Tabelas como GDT, IDT

---

### Examinar Headers (`-x`)

Mostra informações detalhadas sobre o arquivo:

```bash
objdump -x arquivo.o
```

#### Exemplo de Saída
```
build/kernel_full.o:     file format elf64-x86-64
build/kernel_full.o
architecture: i386:x86-64, flags 0x00000112:
EXEC_P, HAS_SYMS, D_PAGED
start address 0x0000000000001000

Program Header:
    LOAD off    0x0000000000001000 vaddr 0x0000000000001000 paddr 0x0000000000001000 align 2**12
         filesz 0x0000000000001234 memsz 0x0000000000001234 flags rwx

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         00001000  0000000000001000  0000000000001000  00001000  2**4
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
```

#### Campos Importantes

| Campo | Descrição |
|-------|-----------|
| `file format` | Formato do arquivo (ELF64, etc.) |
| `architecture` | Arquitetura alvo |
| `start address` | Ponto de entrada |
| `VMA` | Virtual Memory Address |
| `LMA` | Load Memory Address |
| `Size` | Tamanho da seção |

---

### Listar Símbolos (`-t`)

Mostra a tabela de símbolos:

```bash
objdump -t arquivo.o
```

#### Exemplo
```
SYMBOL TABLE:
0000000000001000 g       .text  0000000000000000 start
0000000000001053 l       .text  0000000000000000 start_protected_mode
0000000000001080 l       .text  0000000000000000 setup_paging
0000000000002000 g       .data  0000000000000000 buffer
```

#### Flags dos Símbolos

| Flag | Significado |
|------|-------------|
| `g` | Global (exportado) |
| `l` | Local |
| `d` | Debug |
| `f` | File |
| `O` | Object |
| `F` | Function |

---

### Mostrar Apenas Seções Específicas (`-j`)

Disassembla apenas uma seção específica:

```bash
# Apenas seção .text
objdump -d -j .text arquivo.o

# Apenas seção .boot
objdump -d -j .boot arquivo.o
```

---

## Análise de Código Gerado

### Identificando Problemas de Modo (16/32/64-bit)

O `objdump` sempre interpreta o código conforme o formato do arquivo. Para ELF64, ele assume 64-bit por padrão.

**Problema comum:** Código 16-bit em arquivo ELF64 aparece "errado":

```
1008:       bc 00 7c e8 18          mov    $0x18e87c00,%esp
```

Na verdade, são duas instruções 16-bit:
- `bc 00 7c` = `mov sp, 0x7c00`
- `e8 18 00` = `call +0x18`

**Solução:** Usar `ndisasm` para código 16-bit (veja documento sobre ndisasm).

### Verificando Far Jumps

Far jumps em modo protegido aparecem como:

```
101e:       66 ea                   data16 (bad)
1020:       53                      push   %rbx
1021:       10 00                   adc    %al,(%rax)
```

O `objdump` não consegue interpretar corretamente o far jump 32-bit em contexto 64-bit. Os bytes reais são:

```
66 ea 53 10 00 00 08 00
```

Que significa:
- `66`: Operand size prefix (32-bit)
- `ea`: Far jump opcode
- `53 10 00 00`: Offset de 32-bit (0x00001053)
- `08 00`: Seletor de 16-bit (0x0008)

### Verificando Descritores GDT

Para verificar a GDT gerada, examine os bytes raw:

```bash
objdump -s -j .text arquivo.o | head -20
```

Ou use `xxd` no binário final:

```bash
xxd build/kernel.bin | head -20
```

#### Estrutura de um Descritor GDT (8 bytes)

```
Byte 0-1: Limite (bits 0-15)
Byte 2-3: Base (bits 0-15)
Byte 4:   Base (bits 16-23)
Byte 5:   Access byte
Byte 6:   Flags (4 bits) + Limite (bits 16-19)
Byte 7:   Base (bits 24-31)
```

**Exemplo - Code Segment 32-bit:**
```
ff ff 00 00 00 9a cf 00
```
- Limite: 0xfffff (com granularidade 4KB = 4GB)
- Base: 0x00000000
- Access: 0x9a (Present, Ring 0, Code, Executable, Readable)
- Flags: 0xc (4KB granularity, 32-bit)

---

## Uso Combinado com Outros Comandos

### Filtrar Saída com grep

```bash
# Encontrar uma função específica
objdump -d arquivo.o | grep -A 20 "<start_protected_mode>:"

# Encontrar todos os jumps
objdump -d arquivo.o | grep -E "jmp|call"

# Encontrar instruções privilegiadas
objdump -d arquivo.o | grep -E "lgdt|lidt|mov.*cr"
```

### Limitar Saída com head/tail

```bash
# Primeiras 100 linhas do disassembly
objdump -d arquivo.o | head -100

# Ver apenas o início de cada função
objdump -d arquivo.o | grep -E "^[0-9a-f]+ <.*>:"
```

### Comparar Binários

```bash
# Gerar disassembly de dois binários
objdump -d build/kernel_v1.o > v1.asm
objdump -d build/kernel_v2.o > v2.asm

# Comparar
diff v1.asm v2.asm
```

---

## Problemas Comuns e Soluções

### "(bad)" no Disassembly

Quando você vê `(bad)`, significa que o `objdump` não conseguiu decodificar a instrução:

```
101e:       66 ea                   data16 (bad)
```

**Causas comuns:**
1. Código de modo diferente (16-bit em arquivo 64-bit)
2. Dados interpretados como código
3. Instruções privilegiadas ou extensões não suportadas

**Soluções:**
1. Use `ndisasm` para código 16-bit
2. Verifique se a seção é realmente código
3. Examine os bytes raw com `xxd`

### Endereços Incorretos

Se os endereços parecem errados, verifique:

1. O linker script está correto?
2. A seção `.boot` está antes de `.text`?
3. O `ENTRY()` aponta para o símbolo correto?

```bash
# Verificar ponto de entrada
objdump -f arquivo.o | grep "start address"
```

### Código 64-bit em Contexto 32-bit

Se você está escrevendo código 32-bit mas o `objdump` está mostrando instruções 64-bit estranhas:

```
1093:       a3 00 20 00 00 b8 03    movabs %eax,0x4003b800002000
```

Isso indica que a instrução `mov [0x2000], eax` foi gerada como `movabs` (64-bit absolute).

**Solução:** Use endereçamento via registrador:
```asm
mov edi, 0x2000
mov [edi], eax
```

---

## Flags de Referência Rápida

| Flag | Descrição |
|------|-----------|
| `-d` | Disassembly de seções executáveis |
| `-D` | Disassembly de todas as seções |
| `-S` | Mistura código fonte com assembly (se disponível) |
| `-t` | Tabela de símbolos |
| `-T` | Tabela de símbolos dinâmicos |
| `-x` | Todos os headers |
| `-h` | Headers de seção |
| `-r` | Relocations |
| `-s` | Conteúdo completo das seções |
| `-j <seção>` | Apenas a seção especificada |
| `-M intel` | Sintaxe Intel |
| `-M x86-64` | Forçar interpretação como x86-64 |
| `--no-show-raw-insn` | Ocultar bytes de máquina |
| `--wide` | Não truncar linhas longas |

---

## Referências

- [GNU Binutils Documentation](https://sourceware.org/binutils/docs/binutils/objdump.html)
- [OSDev Wiki - Object Files](https://wiki.osdev.org/Object_Files)
- [x86 Instruction Reference](https://www.felixcloutier.com/x86/)
