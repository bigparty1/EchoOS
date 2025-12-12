# --- CONFIGURAÇÃO DA TOOLCHAIN ---
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
# Encontra todos os arquivos .c recursivamente em src/
C_SRCS := $(shell find $(SRC_DIR) -type f -name '*.c')

# Converte src/path/to/file.c → build/path/to/file.o
C_OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SRCS))

# Boot assembly (manual - ordem importa)
BOOT_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot.asm
KERNEL_ENTRY_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot64.asm

# --- BINÁRIOS ---
BOOT_BIN := $(BUILD_DIR)/boot.bin
KERNEL_ENTRY_OBJ := $(BUILD_DIR)/boot64.o
KERNEL_FULL_OBJ := $(BUILD_DIR)/kernel_full.o
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
OS_BIN := $(BUILD_DIR)/os.bin

# --- FLAGS ---
CFLAGS := -ffreestanding -mno-red-zone -m64 -I$(SRC_DIR)
LDFLAGS := -T target/x86_64/linker.ld -n
QEMU_FLAGS := -drive format=raw,file=$(OS_BIN)
RUN_ENV := LD_LIBRARY_PATH=""

# --- TARGETS ---
all: $(OS_BIN)

# Monta a imagem final do OS
$(OS_BIN): $(BOOT_BIN) $(KERNEL_BIN)
	@echo ">> Montando OS..."
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_BIN)
	dd if=/dev/zero bs=512 count=20 >> $(OS_BIN) 2>/dev/null

# Compila o bootloader stage 1 (binário puro)
$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILD_DIR)
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)

# Compila o bootloader stage 2 (ELF64)
$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	@mkdir -p $(dir $@)
	$(ASM) -f elf64 $(KERNEL_ENTRY_SRC) -o $(KERNEL_ENTRY_OBJ)

# Regra genérica: compila qualquer .c em src/ para .o em build/
# Cria subdiretórios automaticamente
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	@echo ">> Compilando $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Linka todos os objetos
$(KERNEL_FULL_OBJ): $(KERNEL_ENTRY_OBJ) $(C_OBJS)
	@echo ">> Linkando $(words $(C_OBJS)) arquivo(s) C + boot64.o..."
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_ENTRY_OBJ) $(C_OBJS)

# Gera binário do kernel
$(KERNEL_BIN): $(KERNEL_FULL_OBJ)
	@echo ">> Gerando binário do Kernel..."
	$(OBJCOPY) -O binary $(KERNEL_FULL_OBJ) $(KERNEL_BIN)

# Executa no QEMU
run: $(OS_BIN)
	$(RUN_ENV) $(QEMU) $(QEMU_FLAGS)

# Limpa build
clean:
	rm -rf $(BUILD_DIR)

# Debug: mostra arquivos encontrados
info:
	@echo "=== Arquivos C encontrados ==="
	@echo $(C_SRCS) | tr ' ' '\n'
	@echo ""
	@echo "=== Objetos que serão gerados ==="
	@echo $(C_OBJS) | tr ' ' '\n'

.PHONY: all run clean info