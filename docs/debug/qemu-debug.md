# Debug com QEMU

## Visão Geral

O QEMU é um emulador de máquinas virtuais que oferece diversas ferramentas de debug extremamente úteis para desenvolvimento de sistemas operacionais. Este documento cobre as principais técnicas e flags de debug disponíveis.

---

## Flags de Debug Principais

### `-d` (Debug Output)

A flag `-d` habilita diferentes tipos de log de debug. Você pode combinar múltiplas opções separadas por vírgula.

#### Sintaxe
```bash
qemu-system-x86_64 -d <opções> -drive format=raw,file=imagem.bin
```

#### Opções Mais Úteis

| Opção | Descrição |
|-------|-----------|
| `int` | Loga todas as interrupções (hardware e software) |
| `cpu_reset` | Loga informações detalhadas quando a CPU é resetada |
| `in_asm` | Mostra as instruções assembly sendo executadas |
| `exec` | Loga blocos de código sendo executados |
| `cpu` | Mostra o estado da CPU após cada instrução |
| `mmu` | Loga operações da MMU (Memory Management Unit) |
| `pcall` | Loga chamadas de modo protegido |
| `guest_errors` | Mostra erros do guest (sistema operacional) |

#### Exemplo Prático
```bash
qemu-system-x86_64 -d int,cpu_reset -drive format=raw,file=build/os.bin
```

Este comando mostrará:
- Todas as interrupções que ocorrem
- Estado completo da CPU quando houver reset

---

### `-no-reboot`

Esta flag **impede que o QEMU reinicie automaticamente** após um triple fault ou shutdown. Isso é essencial para debug porque:

1. Permite ver o estado da CPU no momento do crash
2. Evita loop infinito de reinicializações
3. Facilita identificar onde o problema ocorreu

#### Sintaxe
```bash
qemu-system-x86_64 -no-reboot -drive format=raw,file=imagem.bin
```

#### Uso Combinado (Recomendado para Debug)
```bash
qemu-system-x86_64 -d int,cpu_reset -no-reboot -drive format=raw,file=build/os.bin
```

---

### `-no-shutdown`

Similar ao `-no-reboot`, mas impede o QEMU de fechar completamente após um shutdown. Útil quando você quer inspecionar o estado final do sistema.

```bash
qemu-system-x86_64 -no-shutdown -drive format=raw,file=build/os.bin
```

---

### `-nographic`

Remove a janela gráfica do QEMU e redireciona toda a saída para o terminal. Muito útil para:

1. Capturar logs extensos
2. Usar com `grep`, `head`, `tail` e outros utilitários
3. Executar em ambientes sem interface gráfica

#### Sintaxe
```bash
qemu-system-x86_64 -nographic -drive format=raw,file=imagem.bin
```

#### Exemplo com Filtro
```bash
qemu-system-x86_64 -d int,cpu_reset -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | grep "Triple fault"
```

**Nota:** Para sair do QEMU em modo `-nographic`, use `Ctrl+A` seguido de `X`.

---

## Interpretando a Saída de Debug

### Estado da CPU (CPU Dump)

Quando ocorre um reset ou você usa `-d cpu_reset`, o QEMU mostra o estado completo da CPU:

```
CPU Reset (CPU 0)
EAX=00000011 EBX=00001000 ECX=00000002 EDX=00000080
ESI=00000000 EDI=00000000 EBP=00000000 ESP=00007c00
EIP=0000101e EFL=00000006 [-----P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0000 00000000 0000ffff 00009300 DPL=0 DS16 [-WA]
CS =0000 00000000 0000ffff 00009b00 DPL=0 CS16 [-RA]
...
GDT=     0000102d 0000001f
IDT=     00000000 000003ff
CR0=00000011 CR2=00000000 CR3=00000000 CR4=00000000
```

#### Campos Importantes

| Campo | Descrição |
|-------|-----------|
| `EAX`, `EBX`, etc. | Registradores de propósito geral |
| `EIP` | Instruction Pointer - endereço da instrução atual |
| `ESP` | Stack Pointer - topo da pilha |
| `EFL` | FLAGS register |
| `CPL` | Current Privilege Level (0 = kernel, 3 = user) |
| `CS`, `DS`, etc. | Segment registers com base, limite e flags |
| `GDT` | Base e limite da Global Descriptor Table |
| `IDT` | Base e limite da Interrupt Descriptor Table |
| `CR0-CR4` | Control Registers |

#### Interpretando Segment Registers

```
CS =0008 00001000 ffffffff 00cf9b00 DPL=0 CS32 [-RA]
```

- `0008`: Seletor do segmento
- `00001000`: Base do segmento
- `ffffffff`: Limite do segmento
- `00cf9b00`: Flags e atributos
- `DPL=0`: Descriptor Privilege Level
- `CS32`: Code Segment de 32 bits
- `[-RA]`: Readable, Accessed

---

## Códigos de Exceção (Exception Vectors)

Quando uma exceção ocorre, o QEMU mostra algo como:

```
check_exception old: 0xffffffff new 0xd
     0: v=0d e=0008 i=0 cpl=0 IP=0000:000000000000101e
```

### Interpretação

| Campo | Significado |
|-------|-------------|
| `v=0d` | Vector da exceção (0x0D = 13 = General Protection Fault) |
| `e=0008` | Error code (específico de cada exceção) |
| `i=0` | Se é interrupção externa (0 = não) |
| `cpl=0` | Privilege level atual |
| `IP=0000:101e` | Segment:Offset onde ocorreu a exceção |

### Tabela de Exception Vectors

| Vector (Hex) | Vector (Dec) | Nome | Descrição |
|--------------|--------------|------|-----------|
| 0x00 | 0 | #DE | Division Error |
| 0x01 | 1 | #DB | Debug Exception |
| 0x02 | 2 | NMI | Non-Maskable Interrupt |
| 0x03 | 3 | #BP | Breakpoint |
| 0x04 | 4 | #OF | Overflow |
| 0x05 | 5 | #BR | Bound Range Exceeded |
| 0x06 | 6 | #UD | Invalid Opcode |
| 0x07 | 7 | #NM | Device Not Available |
| 0x08 | 8 | #DF | Double Fault |
| 0x09 | 9 | - | Coprocessor Segment Overrun (obsoleto) |
| 0x0A | 10 | #TS | Invalid TSS |
| 0x0B | 11 | #NP | Segment Not Present |
| 0x0C | 12 | #SS | Stack-Segment Fault |
| 0x0D | 13 | #GP | General Protection Fault |
| 0x0E | 14 | #PF | Page Fault |
| 0x0F | 15 | - | Reservado |
| 0x10 | 16 | #MF | x87 FPU Floating-Point Error |
| 0x11 | 17 | #AC | Alignment Check |
| 0x12 | 18 | #MC | Machine Check |
| 0x13 | 19 | #XM | SIMD Floating-Point Exception |
| 0x14 | 20 | #VE | Virtualization Exception |
| 0x15-0x1D | 21-29 | - | Reservados |
| 0x1E | 30 | #SX | Security Exception |
| 0x1F | 31 | - | Reservado |

---

## Exceções Comuns em Desenvolvimento de OS

### #GP - General Protection Fault (0x0D)

**Causas mais comuns:**
1. Far jump para seletor de segmento inválido
2. Acesso a segmento com privilégio insuficiente
3. Escrita em segmento read-only
4. Instrução inválida para o modo atual

**Error Code para #GP:**
- Se o error code for um seletor (ex: `e=0008`), indica problema com esse segmento
- O seletor `0x08` aponta para o primeiro descritor após o null (índice 1)

**Como debugar:**
1. Verifique o endereço em `EIP` - qual instrução causou o erro?
2. Examine o seletor no error code
3. Verifique se a GDT está configurada corretamente
4. Confirme que os descritores têm os flags corretos

### #DF - Double Fault (0x08)

Ocorre quando uma exceção acontece durante o tratamento de outra exceção.

**Causas comuns:**
1. IDT não configurada ou inválida
2. Handler de exceção causa outra exceção
3. Stack overflow no handler

### Triple Fault

**Não é uma exceção**, mas sim o resultado de uma exceção ocorrer durante um Double Fault. A CPU não tem como se recuperar e reseta.

O QEMU mostra:
```
check_exception old: 0x8 new 0xd
Triple fault
```

Isso indica:
- `old: 0x8`: Estava tratando Double Fault
- `new: 0xd`: General Protection Fault ocorreu
- Resultado: Triple Fault → CPU Reset

---

## Verificando a GDT

A linha `GDT= 0000102d 0000001f` indica:
- **Base:** `0x0000102d` - endereço onde a GDT começa na memória
- **Limite:** `0x1f` (31 em decimal) - tamanho da GDT - 1

O limite `0x1f` (32 bytes) significa que a GDT tem 4 descritores de 8 bytes cada:
- Índice 0 (seletor 0x00): Null descriptor
- Índice 1 (seletor 0x08): Code segment
- Índice 2 (seletor 0x10): Data segment
- Índice 3 (seletor 0x18): Opcional

**Cálculo do seletor:**
```
Seletor = Índice × 8 + TI + RPL
```
- TI: Table Indicator (0 = GDT, 1 = LDT)
- RPL: Requested Privilege Level (0-3)

Exemplo: Seletor `0x08` = Índice 1, TI=0, RPL=0

---

## Comandos Úteis para Debug

### Verificar Triple Faults
```bash
timeout 3 qemu-system-x86_64 -d int,cpu_reset -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | grep -E "(Triple fault|CPU Reset)"
```

### Ver Exceções
```bash
qemu-system-x86_64 -d int,cpu_reset -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | grep "check_exception"
```

### Capturar Estado no Crash
```bash
qemu-system-x86_64 -d int,cpu_reset -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | tail -80
```

### Filtrar por Tipo de Exceção
```bash
# Apenas General Protection Faults
qemu-system-x86_64 -d int -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | grep "v=0d"

# Apenas Page Faults
qemu-system-x86_64 -d int -no-reboot -nographic \
    -drive format=raw,file=build/os.bin 2>&1 | grep "v=0e"
```

---

## Debug Avançado com GDB

O QEMU pode ser conectado ao GDB para debug interativo:

### Iniciar QEMU em Modo Debug
```bash
qemu-system-x86_64 -s -S -drive format=raw,file=build/os.bin
```

- `-s`: Abre servidor GDB na porta 1234
- `-S`: Pausa a execução no início (freeze)

### Conectar com GDB
```bash
gdb
(gdb) target remote localhost:1234
(gdb) set architecture i8086    # Para código 16-bit
(gdb) break *0x7c00             # Breakpoint no bootloader
(gdb) continue
```

### Comandos GDB Úteis para OS Dev

| Comando | Descrição |
|---------|-----------|
| `info registers` | Mostra todos os registradores |
| `x/10i $eip` | Mostra 10 instruções a partir de EIP |
| `x/16xb 0x7c00` | Mostra 16 bytes em hex a partir de 0x7c00 |
| `stepi` | Executa uma instrução |
| `continue` | Continua execução |
| `break *0x1000` | Breakpoint no endereço |

---

## Referências

- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [Intel® 64 and IA-32 Architectures Software Developer Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [OSDev Wiki - Exceptions](https://wiki.osdev.org/Exceptions)
- [OSDev Wiki - QEMU](https://wiki.osdev.org/QEMU)
