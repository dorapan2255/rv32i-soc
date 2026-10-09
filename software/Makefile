RISCV_PREFIX ?= riscv64-unknown-elf-

CC      := $(RISCV_PREFIX)gcc
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump

ARCH_FLAGS := -march=rv32i -mabi=ilp32 -mno-relax
LINK_FLAGS := -nostdlib -nostartfiles -ffreestanding \
	-Wl,-T,linker.ld -Wl,--no-relax -Wl,--build-id=none
C_FLAGS := $(ARCH_FLAGS) -O2 -Wall -Wextra -fno-builtin \
	-fno-stack-protector -msmall-data-limit=0
ASM_FLAGS := $(ARCH_FLAGS) -x assembler-with-cpp

ASM_PROGRAMS := integration_test timer_test
C_PROGRAMS   := uart_test system_demo
PROGRAMS     := $(ASM_PROGRAMS) $(C_PROGRAMS)
BUILD_DIR    := build

.PHONY: all clean check-tools

all: check-tools $(PROGRAMS:%=%.hex) $(PROGRAMS:%=%.data.hex) \
	$(PROGRAMS:%=$(BUILD_DIR)/%.disasm)

check-tools:
	@for tool in "$(CC)" "$(OBJCOPY)" "$(OBJDUMP)"; do \
		command -v "$$tool" >/dev/null 2>&1 || { \
			echo "ERROR: required RISC-V tool not found: $$tool" >&2; \
			echo "Install a RISC-V GNU toolchain or override the prefix, for example:" >&2; \
			echo "  make RISCV_PREFIX=/custom/path/riscv64-unknown-elf-" >&2; \
			exit 1; \
		}; \
	done

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(ASM_PROGRAMS:%=$(BUILD_DIR)/%.elf): $(BUILD_DIR)/%.elf: %.S linker.ld | $(BUILD_DIR)
	$(CC) $(ASM_FLAGS) $(LINK_FLAGS) -Wl,-Map,$(@:.elf=.map) -o $@ $<

$(C_PROGRAMS:%=$(BUILD_DIR)/%.elf): $(BUILD_DIR)/%.elf: crt0.S %.c linker.ld | $(BUILD_DIR)
	$(CC) $(C_FLAGS) $(LINK_FLAGS) -Wl,-Map,$(@:.elf=.map) -o $@ crt0.S $*.c

$(BUILD_DIR)/%.imem.bin: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O binary --only-section=.text $< $@

$(BUILD_DIR)/%.dmem.bin: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O binary --only-section=.data $< $@

%.hex: $(BUILD_DIR)/%.imem.bin bin_to_hex.py
	python3 bin_to_hex.py --size 1024 $< $@

%.data.hex: $(BUILD_DIR)/%.dmem.bin bin_to_hex.py
	python3 bin_to_hex.py --size 1024 $< $@

$(BUILD_DIR)/%.disasm: $(BUILD_DIR)/%.elf check_instruction_subset.py
	$(OBJDUMP) -d -M no-aliases,numeric $< > $@
	python3 check_instruction_subset.py $@

clean:
	rm -rf $(BUILD_DIR) $(PROGRAMS:%=%.hex) $(PROGRAMS:%=%.data.hex)
