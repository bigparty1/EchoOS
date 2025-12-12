# Códigos de Exceção x86/x86-64

## Visão Geral

Este documento detalha todos os códigos de exceção (exception vectors) da arquitetura x86/x86-64, incluindo causas comuns, error codes e técnicas de debug.

---

## Tabela Completa de Exceções

| Vector | Hex | Mnemônico | Nome | Tipo | Error Code |
|--------|-----|-----------|------|------|------------|
| 0 | 0x00 | #DE | Division Error | Fault | Não |
| 1 | 0x01 | #DB | Debug Exception | Fault/Trap | Não |
| 2 | 0x02 | NMI | Non-Maskable Interrupt | Interrupt | Não |
| 3 | 0x03 | #BP | Breakpoint | Trap | Não |
| 4 | 0x04 | #OF | Overflow | Trap | Não |
| 5 | 0x05 | #BR | Bound Range Exceeded | Fault | Não |
| 6 | 0x06 | #UD | Invalid Opcode | Fault | Não |
| 7 | 0x07 | #NM | Device Not Available | Fault | Não |
| 8 | 0x08 | #DF | Double Fault | Abort | Sim (sempre 0) |
| 9 | 0x09 | - | Coprocessor Segment Overrun | Fault | Não |
| 10 | 0x0A | #TS | Invalid TSS | Fault | Sim |
| 11 | 0x0B | #NP | Segment Not Present | Fault | Sim |
| 12 | 0x0C | #SS | Stack-Segment Fault | Fault | Sim |
| 13 | 0x0D | #GP | General Protection Fault | Fault | Sim |
| 14 | 0x0E | #PF | Page Fault | Fault | Sim |
| 15 | 0x0F | - | Reservado | - | - |
| 16 | 0x10 | #MF | x87 FPU Error | Fault | Não |
| 17 | 0x11 | #AC | Alignment Check | Fault | Sim (sempre 0) |
| 18 | 0x12 | #MC | Machine Check | Abort | Não |
| 19 | 0x13 | #XM/#XF | SIMD Floating-Point | Fault | Não |
| 20 | 0x14 | #VE | Virtualization Exception | Fault | Não |
| 21 | 0x15 | #CP | Control Protection | Fault | Sim |
| 22-27 | - | - | Reservados | - | - |
| 28 | 0x1C | #HV | Hypervisor Injection | Fault | Não |
| 29 | 0x1D | #VC | VMM Communication | Fault | Sim |
| 30 | 0x1E | #SX | Security Exception | Fault | Sim |
| 31 | 0x1F | - | Reservado | - | - |
| 32-255 | - | - | Interrupções de Usuário | - | - |

---

## Tipos de Exceção

### Fault
- A exceção ocorre **antes** da instrução ser executada
- `EIP/RIP` aponta para a instrução que causou o fault
- Após tratamento, a instrução é **re-executada**

### Trap
- A exceção ocorre **após** a instrução ser executada
- `EIP/RIP` aponta para a **próxima** instrução
- Execução continua normalmente após tratamento

### Abort
- Erro grave, geralmente não recuperável
- O estado do processador pode estar inconsistente
- Tipicamente requer reset ou término do processo

---

## Exceções Detalhadas

### #DE - Division Error (Vector 0)

**Ocorre quando:**
- Divisão por zero (`div`/`idiv` com divisor 0)
- Quociente muito grande para o registrador destino

**Debug:**
```bash
# Encontrar instruções de divisão
ndisasm -b 32 arquivo.bin | grep -E "div|idiv"
```

**Prevenção:**
```asm
; Sempre verificar divisor antes de dividir
test ebx, ebx
jz .division_by_zero
div ebx
```

---

### #DB - Debug Exception (Vector 1)

**Ocorre quando:**
- Hardware breakpoint atingido (DR0-DR3)
- Single-step mode (TF flag)
- Task switch com T flag
- Acesso a debug register

**Uso em debugging:**
```asm
; Habilitar single-step
pushf
or dword [esp], 0x100  ; Set TF (Trap Flag)
popf
```

---

### #BP - Breakpoint (Vector 3)

**Ocorre quando:**
- Instrução `INT 3` é executada
- Opcode: `0xCC` (1 byte)

**Uso comum:**
- Debuggers inserem `0xCC` no código
- Software breakpoints

```asm
; Inserir breakpoint
int 3  ; ou db 0xCC
```

---

### #UD - Invalid Opcode (Vector 6)

**Ocorre quando:**
- Opcode inválido ou não suportado
- Instrução privilegiada em modo usuário
- Prefixo LOCK usado incorretamente
- Instrução não suportada pela CPU

**Causas comuns em OS dev:**
1. Código 64-bit executado em modo 32-bit
2. Instrução SSE sem suporte habilitado
3. Bytes de dados interpretados como código

**Debug:**
```bash
# Ver instruções ao redor do EIP
ndisasm -b 32 -o 0x1000 arquivo.bin | grep -A5 -B5 "ENDERECO"
```

---

### #NM - Device Not Available (Vector 7)

**Ocorre quando:**
- Instrução FPU/MMX/SSE usada com CR0.TS=1
- Instrução x87 com CR0.EM=1

**Solução:**
```asm
; Limpar TS flag antes de usar FPU
clts
; ou
mov eax, cr0
and eax, ~(1 << 3)  ; Clear TS
mov cr0, eax
```

---

### #DF - Double Fault (Vector 8)

**Ocorre quando:**
Uma exceção acontece durante o processamento de outra exceção específica.

**Combinações que causam Double Fault:**

| Primeira Exceção | Segunda Exceção |
|------------------|-----------------|
| #DE, #TS, #NP, #SS, #GP, #PF | #DE, #TS, #NP, #SS, #GP, #PF |
| #DE, #TS, #NP, #SS, #GP, #PF | #PF |

**Causas comuns:**
1. IDT não configurada ou corrompida
2. Stack overflow no handler de exceção
3. Handler de exceção causa outra exceção

**Error code:** Sempre 0

**Debug:**
```
check_exception old: 0xd new 0xe
     0: v=08 e=0000 ...
```
Isso indica: #GP (0xd) seguido de #PF (0xe) → Double Fault

---

### #TS - Invalid TSS (Vector 10)

**Ocorre quando:**
- TSS com limite inválido
- TSS com seletores de segmento inválidos
- Task switch para TSS inválido

**Error code:** Seletor do TSS que causou o erro

**Debug:**
```asm
; Verificar limite do TSS (mínimo 0x67 para 32-bit)
; Verificar se TR foi carregado corretamente
ltr ax  ; Carregar Task Register
```

---

### #NP - Segment Not Present (Vector 11)

**Ocorre quando:**
- Acesso a segmento com bit Present = 0
- Carregamento de seletor para segmento não presente

**Error code:** Seletor do segmento

**Causas comuns:**
1. GDT não configurada corretamente
2. Seletor aponta para descritor inválido
3. Descritor com P=0

**Debug:**
```bash
# Verificar GDT
xxd -s OFFSET_GDT -l 32 arquivo.bin
```

---

### #SS - Stack Segment Fault (Vector 12)

**Ocorre quando:**
- Stack overflow ou underflow
- Carregamento de SS com seletor inválido
- Stack não está presente ou não é writable

**Error code:**
- Novo seletor SS (se erro durante load)
- 0 (se erro durante push/pop)

**Causas comuns:**
1. ESP/RSP aponta para memória inválida
2. Stack muito pequena
3. SS carregado com seletor errado

---

### #GP - General Protection Fault (Vector 13)

**A exceção mais comum em desenvolvimento de OS!**

**Ocorre quando:**
- Violação de proteção de segmento
- Far jump/call para seletor inválido
- Escrita em segmento read-only
- Instrução privilegiada em ring > 0
- Acesso a segmento com DPL incorreto
- Muitas outras violações de proteção

**Error code:**
- Seletor de segmento (se relacionado a segmento)
- 0 (outros casos)

#### Interpretando Error Code de #GP

```
Error Code: 0x0008

Bits 15-3: Índice do seletor (0x0008 >> 3 = 1)
Bit 2 (TI): 0 = GDT, 1 = LDT
Bits 1-0 (RPL): Requested Privilege Level

0x0008 = 0000 0000 0000 1000
         ^^^^ ^^^^ ^^^^ ^        Índice = 1
                         ^       TI = 0 (GDT)
                          ^^     RPL = 0
```

**Causas comuns em OS dev:**

1. **Far jump com seletor inválido:**
```
EIP=0000101e
check_exception ... e=0008
```
Seletor 0x08 (índice 1 na GDT) está inválido ou não é code segment.

2. **GDT mal configurada:**
```asm
; Verificar estrutura do descritor
gdt_code:
    dw 0xFFFF       ; Limite 0-15
    dw 0x0000       ; Base 0-15
    db 0x00         ; Base 16-23
    db 10011010b    ; Access: P=1, DPL=0, S=1, Type=Code, Exec, Read
    db 11001111b    ; Flags + Limite 16-19
    db 0x00         ; Base 24-31
```

3. **Instrução privilegiada em modo usuário:**
```asm
; Estas instruções causam #GP se CPL > 0
lgdt [...]
lidt [...]
mov cr0, eax
cli
sti
```

**Debug de #GP:**
```bash
# Ver estado da CPU no momento do erro
qemu-system-x86_64 -d int,cpu_reset -no-reboot ...

# Verificar:
# 1. EIP - qual instrução causou?
# 2. CS - qual segmento de código?
# 3. GDT - está correta?
# 4. Error code - qual seletor?
```

---

### #PF - Page Fault (Vector 14)

**Ocorre quando:**
- Acesso a página não presente
- Violação de proteção de página
- Escrita em página read-only
- Acesso de usuário a página supervisor

**Error code (bits):**

| Bit | Nome | Significado se 1 | Significado se 0 |
|-----|------|------------------|------------------|
| 0 | P | Violação de proteção | Página não presente |
| 1 | W/R | Escrita | Leitura |
| 2 | U/S | Modo usuário | Modo supervisor |
| 3 | RSVD | Reserved bits violados | - |
| 4 | I/D | Instruction fetch | Data access |
| 5 | PK | Protection key violation | - |
| 6 | SS | Shadow stack access | - |

**CR2:** Contém o endereço linear que causou o page fault

**Exemplo de debug:**
```
v=0e e=0002 ... CR2=00001234
```
- Vector 0x0E = Page Fault
- Error 0x0002 = bit 1 set = Escrita causou o erro
- CR2 = 0x1234 = Tentou escrever no endereço 0x1234

**Causas comuns:**
1. Page tables não configuradas
2. Acesso a memória não mapeada
3. Kernel tentando acessar memória de usuário

---

### #AC - Alignment Check (Vector 17)

**Ocorre quando:**
- Acesso não alinhado com AC habilitado
- Requer: CR0.AM=1, EFLAGS.AC=1, CPL=3

**Alinhamento requerido:**
- Word (2 bytes): endereço par
- Dword (4 bytes): endereço múltiplo de 4
- Qword (8 bytes): endereço múltiplo de 8

---

## Triple Fault

**Não é uma exceção**, mas o resultado fatal de uma sequência de exceções:

1. Exceção original ocorre
2. Durante tratamento, ocorre Double Fault (#DF)
3. Durante tratamento de #DF, outra exceção ocorre
4. CPU não consegue continuar → **Triple Fault → RESET**

**Saída do QEMU:**
```
check_exception old: 0x8 new 0xd
Triple fault
CPU Reset (CPU 0)
```

Interpretação:
- `old: 0x8` = Estava tratando Double Fault
- `new: 0xd` = General Protection Fault ocorreu
- Resultado: Triple Fault

**Causas comuns:**
1. IDT completamente inválida
2. Handler de exceção em endereço inválido
3. Stack corrompida durante tratamento de exceção

---

## Formato de Saída do QEMU

```
check_exception old: 0xffffffff new 0xd
     0: v=0d e=0008 i=0 cpl=0 IP=0008:000000000000101e pc=000000000000101e SP=0010:0000000000007c00
```

| Campo | Descrição |
|-------|-----------|
| `old` | Exceção anterior (0xffffffff = nenhuma) |
| `new` | Nova exceção |
| `v` | Vector da exceção |
| `e` | Error code |
| `i` | Interrupção externa (0 = não) |
| `cpl` | Current Privilege Level |
| `IP` | Segment:Offset do Instruction Pointer |
| `pc` | Program Counter (endereço linear) |
| `SP` | Segment:Offset do Stack Pointer |

---

## Tabela de Debug Rápido

| Sintoma | Exceção Provável | Verificar |
|---------|------------------|-----------|
| Reset após far jump | #GP (0x0D) | GDT, seletores |
| Reset após habilitar paging | #PF (0x0E) | Page tables, CR3 |
| Reset imediato | Triple Fault | IDT, handlers |
| Instrução inválida | #UD (0x06) | Modo CPU, opcodes |
| Stack overflow | #SS (0x0C) ou #DF | ESP, tamanho stack |
| Acesso a memória | #PF (0x0E) | Page tables, mapeamento |

---

## Referências

- [Intel SDM Vol. 3A - Chapter 6: Interrupt and Exception Handling](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [AMD64 Architecture Programmer's Manual Vol. 2](https://www.amd.com/en/support/tech-docs)
- [OSDev Wiki - Exceptions](https://wiki.osdev.org/Exceptions)
- [OSDev Wiki - Page Fault](https://wiki.osdev.org/Page_Fault)
