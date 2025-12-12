# Debug com xxd

## Visão Geral

O `xxd` é uma ferramenta para criar dumps hexadecimais de arquivos binários. É essencial para desenvolvimento de sistemas operacionais porque permite:

1. Examinar bytes raw de binários
2. Verificar estruturas de dados (GDT, IDT, page tables)
3. Confirmar que o assembler/linker gerou o código esperado
4. Analisar o layout do binário final

---

## Comandos Básicos

### Dump Hexadecimal Padrão

```bash
xxd arquivo.bin
```

#### Exemplo de Saída
```
00000000: 31c0 8ed8 8ec0 8ed0 bc00 7ce8 1800 fa0f  1.........|.....
00000010: 0116 4d10 0f20 c066 83c8 010f 22c0 66ea  ..M.. .f....".f.
00000020: 5310 0000 0800 e492 0c02 e692 c300 0000  S...............
```

#### Interpretação das Colunas

| Coluna | Descrição |
|--------|-----------|
| `00000000:` | Offset em hexadecimal |
| `31c0 8ed8...` | Bytes em hexadecimal (agrupados em pares) |
| `1.........\|.....` | Representação ASCII (`.` para não-imprimíveis) |

---

### Limitar Quantidade de Bytes (`-l`)

```bash
# Mostrar apenas os primeiros 64 bytes
xxd -l 64 arquivo.bin

# Mostrar os primeiros 512 bytes (um setor)
xxd -l 512 arquivo.bin
```

---

### Começar de um Offset Específico (`-s`)

```bash
# Começar do byte 0x2D (offset da GDT)
xxd -s 0x2d arquivo.bin

# Combinado com limite
xxd -s 0x2d -l 32 arquivo.bin
```

---

### Formato de Saída

#### Apenas Hexadecimal (`-p`)

```bash
xxd -p arquivo.bin
```

Saída:
```
31c08ed88ec08ed0bc007ce81800fa0f01164d100f20c06683c8010f22c066ea
```

Útil para:
- Scripts que processam os bytes
- Comparações simples
- Copiar bytes para outras ferramentas

#### Uma Coluna por Linha (`-c 1`)

```bash
xxd -c 1 arquivo.bin
```

Saída:
```
00000000: 31  1
00000001: c0  .
00000002: 8e  .
```

#### Bytes Individuais (`-c 1 -g 1`)

```bash
xxd -c 16 -g 1 arquivo.bin
```

Saída:
```
00000000: 31 c0 8e d8 8e c0 8e d0 bc 00 7c e8 18 00 fa 0f  1.........|.....
```

O `-g 1` separa cada byte individualmente (útil para análise detalhada).

---

## Análise de Estruturas de Boot

### Verificar Boot Signature

Todo bootloader MBR deve terminar com `0x55 0xAA` nos bytes 510-511:

```bash
# Verificar assinatura do boot sector
xxd -s 510 -l 2 build/boot.bin
```

Saída esperada:
```
000001fe: 55aa                                     U.
```

### Examinar a GDT

Se sua GDT começa no offset 0x2D do kernel:

```bash
xxd -s 0x2d -l 24 build/kernel.bin
```

Saída (exemplo de GDT com 3 descritores):
```
0000002d: 0000 0000 0000 0000 ffff 0000 009a cf00  ................
0000003d: ffff 0000 0092 cf00                      ........
```

#### Interpretação dos Descritores

**Null Descriptor (8 bytes):**
```
00 00 00 00 00 00 00 00
```

**Code Segment Descriptor (8 bytes):**
```
ff ff 00 00 00 9a cf 00
```
- `ff ff`: Limite bits 0-15 = 0xFFFF
- `00 00`: Base bits 0-15 = 0x0000
- `00`: Base bits 16-23 = 0x00
- `9a`: Access byte = 10011010b (Present, Ring 0, Code, Executable, Readable)
- `cf`: Flags + Limite bits 16-19 = 11001111b (4KB granularity, 32-bit, Limite=0xF)
- `00`: Base bits 24-31 = 0x00

**Data Segment Descriptor (8 bytes):**
```
ff ff 00 00 00 92 cf 00
```
- Similar ao code, mas Access = 0x92 (Data, Writable)

### Verificar Far Jump

O far jump para modo protegido tem a estrutura:

```bash
# Se o far jump está no offset 0x1E
xxd -s 0x1e -l 8 build/kernel.bin
```

Saída esperada:
```
0000001e: 66ea 5310 0000 0800                      f.S.....
```

Interpretação:
- `66`: Operand size prefix (32-bit em modo 16-bit)
- `ea`: Far jump opcode
- `53 10 00 00`: Offset de 32 bits (little-endian) = 0x00001053
- `08 00`: Seletor de 16 bits (little-endian) = 0x0008

---

## Análise de Page Tables

### Page Map Level 4 (PML4)

Se suas page tables começam em 0x2000:

```bash
# Examinar primeira entrada PML4
xxd -s 0x1000 -l 8 build/kernel.bin
```

Para uma entrada que aponta para PDPT em 0x3000:
```
00001000: 0330 0000 0000 0000                      .0......
```

Interpretação:
- `03 30 00 00 00 00 00 00` (little-endian) = 0x0000000000003003
- Bits 0-11: Flags (0x003 = Present + Writable)
- Bits 12-51: Endereço físico do PDPT (0x3000)

---

## Comparação de Binários

### Diff Hexadecimal

```bash
# Gerar dumps
xxd arquivo1.bin > dump1.hex
xxd arquivo2.bin > dump2.hex

# Comparar
diff dump1.hex dump2.hex
```

### Encontrar Diferenças Específicas

```bash
# Comparar seção específica
xxd -s 0x100 -l 64 v1.bin > v1_section.hex
xxd -s 0x100 -l 64 v2.bin > v2_section.hex
diff v1_section.hex v2_section.hex
```

---

## Conversão Reversa (Hex para Binário)

### Criar Binário a partir de Hex Dump

```bash
# Criar dump
xxd arquivo.bin > arquivo.hex

# Editar arquivo.hex manualmente

# Converter de volta para binário
xxd -r arquivo.hex arquivo_modificado.bin
```

### Criar Binário a partir de Hex Plain

```bash
echo "31c08ed8" | xxd -r -p > codigo.bin
```

---

## Uso Combinado com Outras Ferramentas

### Com grep para Encontrar Padrões

```bash
# Encontrar assinatura de boot
xxd build/os.bin | grep "55aa"

# Encontrar padrão de GDT
xxd build/kernel.bin | grep "9acf"
```

### Com head/tail para Seções

```bash
# Primeiro setor (512 bytes = 32 linhas de 16 bytes)
xxd build/os.bin | head -32

# Últimas linhas
xxd build/os.bin | tail -20
```

### Com wc para Tamanho

```bash
# Tamanho em bytes
xxd -p build/kernel.bin | tr -d '\n' | wc -c
# Divida por 2 para obter bytes reais
```

---

## Exemplos Práticos de Debug

### Verificar se o Código 16-bit está Correto

```bash
# Boot sector deve começar com instruções válidas
xxd -l 16 build/boot.bin
```

Saída esperada para `jmp short`:
```
00000000: eb1e ...
```
- `eb`: JMP short opcode
- `1e`: Offset relativo (+30 bytes)

### Verificar Alinhamento de Seções

```bash
# Ver se .text está alinhada em 16 bytes
xxd build/kernel.bin | head -10
```

Se o código não começa imediatamente (offset 0), há padding de alinhamento.

### Verificar LGDT Descriptor

O descriptor do LGDT tem formato:
- 2 bytes: limite (tamanho da GDT - 1)
- 4/8 bytes: base (endereço da GDT)

```bash
# Se o descriptor está no offset 0x4D
xxd -s 0x4d -l 6 build/kernel.bin
```

Saída:
```
0000004d: 1f00 2d10 0000                           ..-.....
```

Interpretação:
- `1f 00`: Limite = 0x001f (32 bytes = 4 descritores de 8 bytes - 1)
- `2d 10 00 00`: Base = 0x0000102d (endereço da GDT)

---

## Tabela de Referência Rápida

| Comando | Descrição |
|---------|-----------|
| `xxd arquivo` | Dump hex padrão |
| `xxd -l N` | Limitar a N bytes |
| `xxd -s N` | Começar do offset N |
| `xxd -c N` | N bytes por linha |
| `xxd -g N` | Agrupar N bytes |
| `xxd -p` | Saída apenas hex (plain) |
| `xxd -i` | Saída como array C |
| `xxd -r` | Reverter (hex → binário) |
| `xxd -r -p` | Reverter de hex plain |
| `xxd -b` | Saída em binário |
| `xxd -u` | Hex em maiúsculas |

---

## Dicas Úteis

### Endianness

x86 usa **little-endian**, então os bytes aparecem "invertidos":

| Valor | Memória (little-endian) |
|-------|------------------------|
| 0x1234 | 34 12 |
| 0x12345678 | 78 56 34 12 |
| 0x1000 | 00 10 |

### Calculando Offsets

Para encontrar onde uma estrutura está no binário:

1. Use `objdump -t` para ver os símbolos e seus endereços
2. Subtraia o endereço base (ex: 0x1000) do endereço do símbolo
3. Use esse offset com `xxd -s`

Exemplo:
- Símbolo `gdt_start` está em 0x102D
- Base do binário é 0x1000
- Offset no arquivo = 0x102D - 0x1000 = 0x2D

```bash
xxd -s 0x2d -l 24 build/kernel.bin
```

---

## Referências

- [xxd Man Page](https://linux.die.net/man/1/xxd)
- [Intel x86 Instruction Reference](https://www.felixcloutier.com/x86/)
- [OSDev Wiki - GDT](https://wiki.osdev.org/GDT)
- [OSDev Wiki - Paging](https://wiki.osdev.org/Paging)
