# ==============================================================================
#  EchoOS Makefile (Automated)
# ==============================================================================

# --- CONFIGURAÇÃO DA TOOLCHAIN ---
# Ajuste este caminho se necessário
TOOLCHAIN_BIN := $(HOME)/opt/cross/bin

# Ferramentas
ASM := nasm
CC := $(TOOLCHAIN_BIN)/x86_64-elf-gcc
LD := $(TOOLCHAIN_BIN)/x86_64-elf-ld
OBJCOPY := $(TOOLCHAIN_BIN)/x86_64-elf-objcopy
QEMU := qemu-system-x86_64

# --- DIRETÓRIOS ---
BUILD_DIR := build
SRC_DIR := src

# --- FONTES (VARREDURA AUTOMÁTICA) ---

# 1. Encontra todos os arquivos .c recursivamente
C_SRCS := $(shell find $(SRC_DIR) -type f -name '*.c')

# 2. Encontra todos os arquivos .asm recursivamente, 
#    MAS EXCLUI (grep -v) qualquer coisa que tenha "boot" no nome/caminho.
#    Isso evita que o boot.asm e boot64.asm sejam compilados pela regra genérica.
ASM_SRCS := $(shell find $(SRC_DIR) -type f -name '*.asm' | grep -v "boot")

# --- OBJETOS AUTOMÁTICOS ---
# Converte src/path/file.c -> build/path/file.o
C_OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS))

# Converte src/path/file.asm -> build/path/file.o
ASM_OBJS := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.o,$(ASM_SRCS))

# --- ARQUIVOS DE BOOT (MANUAIS) ---
# Estes são tratados separadamente pois são a "chave de ignição"
BOOT_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot.asm
KERNEL_ENTRY_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot64.asm

# --- BINÁRIOS FINAIS ---
BOOT_BIN := $(BUILD_DIR)/boot.bin
KERNEL_ENTRY_OBJ := $(BUILD_DIR)/boot64.o
KERNEL_FULL_OBJ := $(BUILD_DIR)/kernel_full.o
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
OS_BIN := $(BUILD_DIR)/os.bin

# --- FLAGS ---
# -mno-red-zone: Essencial para evitar corrupção de pilha em interrupções
CFLAGS := -ffreestanding -mno-red-zone -m64 -I$(SRC_DIR) -g
LDFLAGS := -T target/x86_64/linker.ld -n -z max-page-size=0x1000
QEMU_FLAGS := -drive format=raw,file=$(OS_BIN)
RUN_ENV := LD_LIBRARY_PATH="" GTK_PATH=""

# ==============================================================================
#  REGRAS DE COMPILAÇÃO
# ==============================================================================

all: $(OS_BIN)

# 1. Monta a imagem final do OS (Boot + Kernel + Padding)
$(OS_BIN): $(BOOT_BIN) $(KERNEL_BIN)
	@echo ">> [OS] Montando imagem final..."
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_BIN)
	# Adiciona padding para garantir leitura de disco segura
	dd if=/dev/zero bs=512 count=20 >> $(OS_BIN) 2>/dev/null

# 2. Compila o Bootloader Stage 1 (Real Mode, Binário Puro)
$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(dir $@)
	@echo ">> [ASM] Compilando Bootloader Stage 1..."
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)

# 3. Compila o Bootloader Stage 2 (Entry Point, ELF64)
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	@mkdir -p $(dir $@)
	@echo ">> [ASM] Compilando Bootloader Stage 2..."
	$(ASM) -f elf64 $(KERNEL_ENTRY_SRC) -o $(KERNEL_ENTRY_OBJ)

# 4. Regra Genérica para C (Kernel, Drivers, CPU...)
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	@echo ">> [CC]  Compilando $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# 5. Regra Genérica para Assembly (GDT flush, IDT flush, ISRs...)
#    Nota: Usa elf64 pois será linkado com o Kernel C
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@mkdir -p $(dir $@)
	@echo ">> [ASM] Montando $<..."
	$(ASM) -f elf64 $< -o $@

# 6. Linkagem Final (Entry + Objetos C + Objetos ASM)
$(KERNEL_FULL_OBJ): $(KERNEL_ENTRY_OBJ) $(C_OBJS) $(ASM_OBJS)
	@echo ">> [LD]  Linkando Kernel..."
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_ENTRY_OBJ) $(C_OBJS) $(ASM_OBJS)

# 7. Extrai binário puro do objeto linkado
$(KERNEL_BIN): $(KERNEL_FULL_OBJ)
	@echo ">> [OBJ] Extraindo binário flat..."
	$(OBJCOPY) -O binary $(KERNEL_FULL_OBJ) $(KERNEL_BIN)

# ==============================================================================
#  UTILITÁRIOS
# ==============================================================================

run: $(OS_BIN)
	@echo ">> Executando QEMU..."
	$(RUN_ENV) $(QEMU) $(QEMU_FLAGS)

clean:
	@echo ">> Limpando build..."
	rm -rf $(BUILD_DIR)

# Mostra informações de debug sobre os arquivos encontrados
info:
	@echo "========================================"
	@echo "       ECHO OS BUILD INFO"
	@echo "========================================"
	@echo " [C] Fontes Encontrados:"
	@echo $(C_SRCS) | tr ' ' '\n'
	@echo ""
	@echo " [C] Objetos a gerar:"
	@echo $(C_OBJS) | tr ' ' '\n'
	@echo "----------------------------------------"
	@echo " [ASM] Fontes Auxiliares (Kernel):"
	@echo $(ASM_SRCS) | tr ' ' '\n'
	@echo ""
	@echo " [ASM] Objetos a gerar:"
	@echo $(ASM_OBJS) | tr ' ' '\n'
	@echo "----------------------------------------"
	@echo " [BOOT] Bootloader (Manual):"
	@echo " Stage 1: $(BOOT_SRC)"
	@echo " Stage 2: $(KERNEL_ENTRY_SRC)"
	@echo "========================================"

.PHONY: all run clean info