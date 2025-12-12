ASM := nasm
QEMU := qemu-system-x86_64
BUILD_DIR := build
SRC_DIR := src

# Arquivos
BOOT_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot.asm
BOOT64_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot64.asm 

BOOT_BIN := $(BUILD_DIR)/boot.bin
BOOT64_BIN := $(BUILD_DIR)/boot64.bin
OS_BIN := $(BUILD_DIR)/os.bin

QEMU_FLAGS := -drive format=raw,file=$(OS_BIN)
RUN_ENV := LD_LIBRARY_PATH=""

all: $(OS_BIN)

$(OS_BIN): $(BOOT_BIN) $(BOOT64_BIN)
	@echo ">> Montando imagem final..."
	cat $(BOOT_BIN) $(BOOT64_BIN) > $(OS_BIN)
	dd if=/dev/zero bs=512 count=50 >> $(OS_BIN)

$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILD_DIR)
	@echo ">> Compilando Stage 1 (MBR)..."
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)

$(BOOT64_BIN): $(BOOT64_SRC)
	@echo ">> Compilando Stage 2 (Long Mode)..."
	$(ASM) -f bin $(BOOT64_SRC) -o $(BOOT64_BIN)

run: $(OS_BIN)
	@echo ">> Rodando QEMU..."
	$(RUN_ENV) $(QEMU) $(QEMU_FLAGS)

clean:
	rm -rf $(BUILD_DIR)