# Debug com ndisasm

## Visão Geral

O `ndisasm` é o disassembler do NASM (Netwide Assembler). Diferente do `objdump`, ele trabalha diretamente com binários raw e permite especificar explicitamente o modo de operação (16, 32 ou 64 bits).

É a ferramenta ideal para:
1. Disassemblar código de boot (16-bit)
2. Analisar binários raw (sem headers ELF)
3. Verificar código de modo misto (16/32/64-bit)

---

## Por que usar ndisasm?

### Problema com objdump

O `objdump` assume o modo baseado no formato do arquivo:
- ELF64 → assume código 64-bit
- ELF32 → assume código 32-bit

Quando você tem código 16-bit em um arquivo ELF64 (comum em bootloaders), o `objdump` interpreta incorretamente:

```
# objdump mostra (ERRADO):
1008:       bc 00 7c e8 18          mov    $0x18e87c00,%esp
```

### ndisasm mostra corretamente

```
# ndisasm mostra (CORRETO):
00001008  BC007C            mov sp,0x7c00
0000100B  E81800            call 0x1026
```

---

## Comandos Básicos

### Disassembly 16-bit (`-b 16`)

```bash
ndisasm -b 16 arquivo.bin
```

#### Exemplo
```bash
ndisasm -b 16 build/boot.bin
```

Saída:
```
00000000  31C0              xor ax,ax
00000002  8ED8              mov ds,ax
00000004  8EC0              mov es,ax
00000006  8ED0              mov ss,ax
00000008  BC007C            mov sp,0x7c00
```

### Disassembly 32-bit (`-b 32`)

```bash
ndisasm -b 32 arquivo.bin
```

### Disassembly 64-bit (`-b 64`)

```bash
ndisasm -b 64 arquivo.bin
```

---

## Especificando Offset de Origem (`-o`)

Por padrão, `ndisasm` assume que o código começa no endereço 0. Para bootloaders que são carregados em 0x7C00:

```bash
ndisasm -b 16 -o 0x7c00 build/boot.bin
```

Saída:
```
00007C00  31C0              xor ax,ax
00007C02  8ED8              mov ds,ax
00007C04  8EC0              mov es,ax
```

Para o stage 2 carregado em 0x1000:

```bash
ndisasm -b 16 -o 0x1000 build/kernel.bin
```

---

## Limitando a Análise

### Pular Bytes Iniciais (`-k`)

Pula um número específico de bytes antes de começar o disassembly:

```bash
# Pular os primeiros 83 bytes (0x53 em hex)
ndisasm -b 32 -k 0x53 build/kernel.bin
```

### Limitar com head/tail

```bash
# Primeiras 50 linhas
ndisasm -b 16 build/boot.bin | head -50

# A partir da linha que contém "jmp"
ndisasm -b 16 build/boot.bin | grep -A 20 "jmp"
```

---

## Análise de Código Multi-Modo

### Bootloader Típico (16-bit → 32-bit)

Um bootloader começa em 16-bit e transiciona para 32-bit. Para analisar:

```bash
# Parte 16-bit (início)
ndisasm -b 16 -o 0x1000 build/kernel.bin | head -40

# Parte 32-bit (após o switch)
# Se o código 32-bit começa no offset 0x53:
ndisasm -b 32 -o 0x1053 -k 0x53 build/kernel.bin | head -40
```

### Identificando o Ponto de Transição

Procure por:
1. `lgdt` - carrega a GDT
2. `mov cr0, ...` com bit PE setado
3. Far jump (`jmp seg:offset`)

```bash
ndisasm -b 16 build/kernel.bin | grep -E "lgdt|cr0|jmp.*:"
```

---

## Comparação: ndisasm vs objdump

### Cenário: Código 16-bit em ELF64

**objdump (incorreto):**
```
1000:       31 c0                   xor    %eax,%eax
1002:       8e d8                   mov    %eax,%ds
1008:       bc 00 7c e8 18          mov    $0x18e87c00,%esp
```

**ndisasm (correto):**
```
00001000  31C0              xor ax,ax
00001002  8ED8              mov ds,ax
00001004  8EC0              mov es,ax
00001006  8ED0              mov ss,ax
00001008  BC007C            mov sp,0x7c00
0000100B  E81800            call 0x1026
```

### Quando Usar Cada Um

| Ferramenta | Usar Quando |
|------------|-------------|
| `objdump` | Arquivos ELF, código C compilado, símbolos necessários |
| `ndisasm` | Binários raw, código 16-bit, bootloaders, análise manual |

---

## Análise de Far Jumps

Far jumps são críticos na transição de modos. Veja como aparecem:

### Far Jump 16→32 bit

```bash
ndisasm -b 16 build/kernel.bin | grep -B2 -A2 "jmp"
```

Saída:
```
0000001E  66EA53100000      jmp dword 0x0:0x1053
00000024  0800              or [bx+si],al
```

Interpretação:
- `66`: Operand size prefix (indica offset de 32-bit)
- `EA`: Far jump opcode
- `53 10 00 00`: Offset = 0x00001053 (little-endian)
- `08 00`: Seletor = 0x0008

**Nota:** O `ndisasm` pode interpretar o seletor como próxima instrução. Verifique os bytes raw.

### Far Jump 32→64 bit

```bash
ndisasm -b 32 -k 0x53 build/kernel.bin | grep -B2 -A2 "jmp"
```

---

## Extraindo Seções para Análise

### Extrair Parte do Binário

```bash
# Extrair bytes 0x53 até 0x100 (173 bytes)
dd if=build/kernel.bin of=code32.bin bs=1 skip=$((0x53)) count=$((0x100-0x53))

# Disassemblar como 32-bit
ndisasm -b 32 -o 0x1053 code32.bin
```

### Script para Análise Multi-Modo

```bash
#!/bin/bash
# analyze_kernel.sh

KERNEL=build/kernel.bin
PM_OFFSET=0x53  # Offset onde começa modo protegido
LM_OFFSET=0x110 # Offset onde começa modo longo

echo "=== MODO REAL (16-bit) ==="
ndisasm -b 16 -o 0x1000 $KERNEL | head -30

echo ""
echo "=== MODO PROTEGIDO (32-bit) ==="
ndisasm -b 32 -o 0x1053 -k $PM_OFFSET $KERNEL | head -30

echo ""
echo "=== MODO LONGO (64-bit) ==="
ndisasm -b 64 -o 0x1110 -k $LM_OFFSET $KERNEL | head -30
```

---

## Identificando Problemas Comuns

### Instruções Inválidas

Se você vê muitas instruções estranhas ou `db` (data bytes), provavelmente:

1. **Modo errado:** Está usando `-b 32` para código 16-bit
2. **Dados, não código:** Está tentando disassemblar GDT, strings, etc.
3. **Offset errado:** O código não começa onde você pensa

### Verificando o Modo

Dicas para identificar o modo correto:

**Código 16-bit típico:**
```
mov ax, 0x0000
mov ds, ax
mov sp, 0x7c00
```

**Código 32-bit típico:**
```
mov eax, 0x00000000
mov ds, ax
mov esp, 0x90000
```

**Código 64-bit típico:**
```
mov rax, 0
mov rsp, 0x90000
xor rdi, rdi
```

### GDT Aparecendo como Código

A GDT é dados, não código. Se você vê algo como:

```
00001035  FF                db 0xff
00001036  FF00              inc word [bx+si]
00001038  0000              add [bx+si],al
```

Isso é a GDT sendo interpretada como código. Pule esses bytes com `-k`.

---

## Formato de Saída

### Colunas do ndisasm

```
00001000  31C0              xor ax,ax
^^^^^^^^  ^^^^              ^^^^^^^^^
   |       |                    |
   |       |                    +-- Instrução assembly
   |       +-- Bytes de máquina (opcodes)
   +-- Endereço

```

### Diferença de Sintaxe

O `ndisasm` usa sintaxe Intel por padrão:

| ndisasm (Intel) | objdump (AT&T) |
|-----------------|----------------|
| `mov ax, 0x10` | `mov $0x10, %ax` |
| `mov [bx], ax` | `mov %ax, (%bx)` |
| `jmp 0x1000` | `jmp 0x1000` |

---

## Referência Rápida

| Opção | Descrição |
|-------|-----------|
| `-b 16` | Modo 16-bit |
| `-b 32` | Modo 32-bit |
| `-b 64` | Modo 64-bit |
| `-o N` | Origem (endereço inicial) |
| `-k N` | Pular N bytes iniciais |
| `-e N` | Parar após processar N bytes |
| `-a` | Sincronização automática |
| `-s N` | Sincronizar no offset N |

---

## Comandos Úteis

### Análise Completa de Bootloader

```bash
# Stage 1 (MBR, 16-bit, carregado em 0x7C00)
ndisasm -b 16 -o 0x7c00 build/boot.bin

# Stage 2 parte 16-bit (carregado em 0x1000)
ndisasm -b 16 -o 0x1000 build/kernel.bin | head -40

# Stage 2 parte 32-bit
ndisasm -b 32 -o 0x1053 -k 0x53 build/kernel.bin | head -50
```

### Encontrar Instruções Específicas

```bash
# Encontrar todas as instruções de controle de fluxo
ndisasm -b 16 build/boot.bin | grep -E "jmp|call|ret|int"

# Encontrar instruções privilegiadas
ndisasm -b 32 -k 0x53 build/kernel.bin | grep -E "lgdt|lidt|mov.*cr|wrmsr"
```

### Verificar Tamanho de Instrução

```bash
# Ver quantos bytes cada instrução ocupa
ndisasm -b 16 build/boot.bin | awk '{print $2, length($2)/2, $3, $4, $5}'
```

---

## Referências

- [NASM Documentation](https://www.nasm.us/doc/)
- [Intel x86 Instruction Set Reference](https://www.felixcloutier.com/x86/)
- [OSDev Wiki - Real Mode](https://wiki.osdev.org/Real_Mode)
- [OSDev Wiki - Protected Mode](https://wiki.osdev.org/Protected_Mode)
