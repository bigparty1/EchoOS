# EchoOS

Um sistema operacional minimalista de 64-bits (x86_64) escrito em C, focado no aprendizado de arquitetura de computadores.

## 🛠️ Dependências do Sistema (Host: Ubuntu/Debian)

Ferramentas necessárias para build, emulação e criação da imagem ISO.

```bash
sudo apt update
sudo apt install build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo nasm qemu-system-x86 xorriso grub-pc-bin grub-common mtools
```

## ⚙️ Toolchain (Cross-Compiler)

O projeto requer um compilador cruzado específico para garantir a geração de código independente de sistema operacional (Freestanding).

  * **Target:** `x86_64-elf`
  * **Binutils:** Versão `2.43.1`
  * **GCC:** Versão `14.2.0`

### Configuração de Build do GCC

O GCC deve ser compilado com as seguintes flags críticas:

  * `--target=x86_64-elf`
  * `--without-headers`
  * `--enable-languages=c`
  * `--disable-nls`
  * `--disable-werror`
