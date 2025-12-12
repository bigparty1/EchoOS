# --- CONFIGURAÇÃO DA TOOLCHAIN ---
# Caminho absoluto para onde você instalou o GCC
TOOLCHAIN_BIN := $(HOME)/opt/cross/bin

# Ferramentas (Apontando explicitamente para o caminho acima)
ASM := nasm
CC := $(TOOLCHAIN_BIN)/x86_64-elf-gcc
LD := $(TOOLCHAIN_BIN)/x86_64-elf-ld
OBJCOPY := $(TOOLCHAIN_BIN)/x86_64-elf-objcopy
QEMU := qemu-system-x86_64

# --- RESTO DO ARQUIVO (Pode manter igual, mas vou replicar para garantir) ---
BUILD_DIR := build
SRC_DIR := src

# Fontes
BOOT_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot.asm
KERNEL_ENTRY_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot64.asm
KERNEL_C_SRC := $(SRC_DIR)/kernel/main.c

# Objetos e Binários
BOOT_BIN := $(BUILD_DIR)/boot.bin
KERNEL_ENTRY_OBJ := $(BUILD_DIR)/boot64.o
KERNEL_C_OBJ := $(BUILD_DIR)/kernel.o
KERNEL_FULL_OBJ := $(BUILD_DIR)/kernel_full.o
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
OS_BIN := $(BUILD_DIR)/os.bin

# Flags
CFLAGS := -ffreestanding -mno-red-zone -m64 -c
LDFLAGS := -T target/x86_64/linker.ld -n -o $(KERNEL_FULL_OBJ)
QEMU_FLAGS := -drive format=raw,file=$(OS_BIN)
RUN_ENV := LD_LIBRARY_PATH=""

all: $(OS_BIN)

$(OS_BIN): $(BOOT_BIN) $(KERNEL_BIN)
	@echo ">> Montando OS..."
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_BIN)
	dd if=/dev/zero bs=512 count=20 >> $(OS_BIN) 2>/dev/null

$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILD_DIR)
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)

$(KERNEL_ENTRY_OBJ): $(KERNEL_ENTRY_SRC)
	$(ASM) -f elf64 $(KERNEL_ENTRY_SRC) -o $(KERNEL_ENTRY_OBJ)

$(KERNEL_C_OBJ): $(KERNEL_C_SRC)
	@mkdir -p $(dir $(KERNEL_C_OBJ))
	$(CC) $(CFLAGS) $(KERNEL_C_SRC) -o $(KERNEL_C_OBJ)

$(KERNEL_FULL_OBJ): $(KERNEL_ENTRY_OBJ) $(KERNEL_C_OBJ)
	@echo ">> Linkando..."
	$(LD) $(LDFLAGS) $(KERNEL_ENTRY_OBJ) $(KERNEL_C_OBJ)

$(KERNEL_BIN): $(KERNEL_FULL_OBJ)
	@echo ">> Gerando binário do Kernel..."
	$(OBJCOPY) -O binary $(KERNEL_FULL_OBJ) $(KERNEL_BIN)

run: $(OS_BIN)
	$(RUN_ENV) $(QEMU) $(QEMU_FLAGS)

clean:
	rm -rf $(BUILD_DIR)