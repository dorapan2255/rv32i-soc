IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
VERILATOR ?= verilator

IVERILOG_FLAGS := -g2012 -Wall
BUILD_DIR      := build
WAVEFORM_DIR   := waveforms

CORE_RTL := \
	rtl/cpu/pc.sv \
	rtl/cpu/decoder.sv \
	rtl/cpu/control_unit.sv \
	rtl/cpu/reg_file.sv \
	rtl/cpu/imm_gen.sv \
	rtl/cpu/alu.sv \
	rtl/cpu/branch_jump_unit.sv \
	rtl/cpu/rv32i_core.sv

MEM_RTL := \
	rtl/mem/instruction_memory.sv \
	rtl/mem/data_memory.sv

SOC_RTL := $(CORE_RTL) $(MEM_RTL) \
	rtl/soc/mmio_interconnect.sv \
	rtl/soc/uart_tx.sv \
	rtl/soc/timer.sv \
	rtl/soc/rv32i_soc.sv

.PHONY: software software-clean lint test regression test-soc test-alu test-reg-file test-imm-gen test-decoder
.PHONY: test-control test-pc test-branch test-imem test-dmem test-uart test-timer
.PHONY: test-mmio test-uart-mmio test-timer-mmio test-system-demo wave-soc wave-system-demo
.PHONY: synth-core timing pnr-core clean

test: software test-alu test-reg-file test-imm-gen test-decoder test-control \
	test-pc test-branch test-imem test-dmem test-uart test-mmio \
	test-timer test-soc test-uart-mmio test-timer-mmio test-system-demo

regression: test

lint:
	@command -v "$(VERILATOR)" >/dev/null 2>&1 || { \
		echo "ERROR: Verilator not found: $(VERILATOR)" >&2; \
		echo "Install Verilator or run: make VERILATOR=/custom/path/verilator lint" >&2; \
		exit 1; \
	}
	$(VERILATOR) --lint-only -Wall --top-module rv32i_core $(CORE_RTL)
	$(VERILATOR) --lint-only -Wall --top-module rv32i_soc $(SOC_RTL)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(WAVEFORM_DIR):
	mkdir -p $(WAVEFORM_DIR)

test-alu test-reg-file test-imm-gen test-decoder test-control test-pc \
	test-branch test-imem test-dmem test-uart test-timer test-mmio \
	test-soc test-uart-mmio test-timer-mmio test-system-demo: | $(WAVEFORM_DIR)

software:
	$(MAKE) -C software all

software-clean:
	$(MAKE) -C software clean

test-alu: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s alu_tb -o $(BUILD_DIR)/alu_sim \
		rtl/cpu/alu.sv tb/alu_tb.sv
	$(VVP) $(BUILD_DIR)/alu_sim

test-reg-file: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s reg_file_tb -o $(BUILD_DIR)/reg_file_sim \
		rtl/cpu/reg_file.sv tb/reg_file_tb.sv
	$(VVP) $(BUILD_DIR)/reg_file_sim

test-imm-gen: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s imm_gen_tb -o $(BUILD_DIR)/imm_gen_sim \
		rtl/cpu/imm_gen.sv tb/imm_gen_tb.sv
	$(VVP) $(BUILD_DIR)/imm_gen_sim

test-decoder: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s decoder_tb -o $(BUILD_DIR)/decoder_sim \
		rtl/cpu/decoder.sv tb/decoder_tb.sv
	$(VVP) $(BUILD_DIR)/decoder_sim

test-control: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s control_unit_tb \
		-o $(BUILD_DIR)/control_unit_sim \
		rtl/cpu/control_unit.sv tb/control_unit_tb.sv
	$(VVP) $(BUILD_DIR)/control_unit_sim

test-pc: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s pc_tb -o $(BUILD_DIR)/pc_sim \
		rtl/cpu/pc.sv tb/pc_tb.sv
	$(VVP) $(BUILD_DIR)/pc_sim

test-branch: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s branch_jump_unit_tb \
		-o $(BUILD_DIR)/branch_jump_unit_sim \
		rtl/cpu/branch_jump_unit.sv tb/branch_jump_unit_tb.sv
	$(VVP) $(BUILD_DIR)/branch_jump_unit_sim

test-imem: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s instruction_memory_tb \
		-o $(BUILD_DIR)/instruction_memory_sim \
		rtl/mem/instruction_memory.sv tb/instruction_memory_tb.sv
	$(VVP) $(BUILD_DIR)/instruction_memory_sim

test-dmem: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s data_memory_tb \
		-o $(BUILD_DIR)/data_memory_sim \
		rtl/mem/data_memory.sv tb/data_memory_tb.sv
	$(VVP) $(BUILD_DIR)/data_memory_sim

test-uart: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s uart_tx_tb \
		-o $(BUILD_DIR)/uart_tx_sim rtl/soc/uart_tx.sv tb/uart_tx_tb.sv
	$(VVP) $(BUILD_DIR)/uart_tx_sim

test-timer: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s timer_tb \
		-o $(BUILD_DIR)/timer_sim rtl/soc/timer.sv tb/timer_tb.sv
	$(VVP) $(BUILD_DIR)/timer_sim

test-mmio: | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s mmio_interconnect_tb \
		-o $(BUILD_DIR)/mmio_interconnect_sim \
		rtl/soc/mmio_interconnect.sv tb/mmio_interconnect_tb.sv
	$(VVP) $(BUILD_DIR)/mmio_interconnect_sim

test-soc: software | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s rv32i_soc_tb \
		-o $(BUILD_DIR)/rv32i_soc_sim $(SOC_RTL) tb/rv32i_soc_tb.sv
	$(VVP) $(BUILD_DIR)/rv32i_soc_sim

test-uart-mmio: software | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s uart_mmio_tb \
		-o $(BUILD_DIR)/uart_mmio_sim $(SOC_RTL) tb/uart_mmio_tb.sv
	$(VVP) $(BUILD_DIR)/uart_mmio_sim

test-timer-mmio: software | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s timer_mmio_tb \
		-o $(BUILD_DIR)/timer_mmio_sim $(SOC_RTL) tb/timer_mmio_tb.sv
	$(VVP) $(BUILD_DIR)/timer_mmio_sim

test-system-demo: software | $(BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -s system_demo_tb \
		-o $(BUILD_DIR)/system_demo_sim $(SOC_RTL) tb/system_demo_tb.sv
	$(VVP) $(BUILD_DIR)/system_demo_sim

wave-soc: test-soc
	$(GTKWAVE) waveforms/rv32i_soc.vcd

wave-system-demo: test-system-demo
	$(GTKWAVE) waveforms/system_demo.vcd

synth-core:
	bash scripts/run_synthesis.sh

timing:
	bash scripts/run_timing.sh

pnr-core: timing
	bash scripts/run_pnr.sh

clean: software-clean
	rm -rf $(BUILD_DIR) $(WAVEFORM_DIR) results
	find reports -type f \
		! -name synthesis_summary.txt \
		! -name timing_summary.txt \
		! -name pnr_summary.txt -delete
	find reports -mindepth 1 -type d -empty -delete
