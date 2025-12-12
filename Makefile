# --- Variáveis de Configuração ---
# Definimos os programas e pastas aqui para facilitar mudanças futuras
ASM := nasm
QEMU := qemu-system-x86_64
BUILD_DIR := build
SRC_DIR := src

# Arquivos de Entrada e Saída
BOOT_SRC := $(SRC_DIR)/architecture/x86_64/boot/boot.asm
BOOT_BIN := $(BUILD_DIR)/boot.bin
KERNEL_DUMMY := $(BUILD_DIR)/kernel_test.bin
OS_BIN := $(BUILD_DIR)/os.bin

# Flags do QEMU
# Adicionei o LD_LIBRARY_PATH="" para resolver seu problema com bibliotecas do Snap
QEMU_FLAGS := -drive format=raw,file=$(OS_BIN)
RUN_ENV := LD_LIBRARY_PATH=""

# --- Targets (Alvos) ---

# O primeiro target é o padrão (quando você digita apenas 'make')
all: $(OS_BIN)

# 1. Cria a imagem final do SO (Junta Bootloader + Kernel Falso)
$(OS_BIN): $(BOOT_BIN) $(KERNEL_DUMMY)
	@echo ">> Montando a imagem final do OS..."
	cat $^ > $@

# 2. Compila o Bootloader (Assembly -> Binário Puro)
$(BOOT_BIN): $(BOOT_SRC)
	@mkdir -p $(BUILD_DIR)
	@echo ">> Compilando bootloader..."
	$(ASM) -f bin $< -o $@

# 3. Cria um Kernel Falso (Enche de zeros para teste de leitura de disco)
$(KERNEL_DUMMY):
	@mkdir -p $(BUILD_DIR)
	@echo ">> Gerando kernel temporário (dummy)..."
	dd if=/dev/zero of=$@ bs=512 count=2 2>/dev/null

# 4. Target para rodar o emulador
run: $(OS_BIN)
	@echo ">> Iniciando QEMU..."
	$(RUN_ENV) $(QEMU) $(QEMU_FLAGS)

# 5. Limpa a sujeira (arquivos compilados)
clean:
	@echo ">> Limpando build..."
	rm -rf $(BUILD_DIR)

# Declara que esses targets não são arquivos reais
.PHONY: all run clean