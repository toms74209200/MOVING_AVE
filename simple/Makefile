###############################################################################
# Title		: Moving average
# Auther	: toms74209200 <https://github.com/toms74209200>
# Created	: 2023/05/05
# License	: MIT License.
#			http://opensource.org/licenses/mit-license.php
###############################################################################

# Project
PROJECT = MOVING_AVE
# Directory
QUARTUS_DIR = ~/fpga/intelFPGA_lite/19.1
QUARTUS_BIN_DIR = $(QUARTUS_DIR)/quartus/bin
MODELSIM_BIN_DIR = $(QUARTUS_DIR)/modelsim_ase/bin
PLD_DIR = ./pld
PRG_DIR = ./output_files
TB_DIR = ./testbench

PRG = $(PRG_DIR)/$(PROJECT).sof
TB_SRC = $(TB_DIR)/TB_$(PROJECT).sv

MODELSIM_LIB_FLAGS = -work work
MODELSIM_SIM_FLAGS = -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"
MODELSIM_DO_FLAGS = -do "add wave -unsigned *; \
					view structure; \
					view signals; \
					run -all"

lib_exist := $(shell find -maxdepth 1 -name rtl_work -type d)

all: $(PRG) check

$(PRG) : $(PLD_DIR)/*.vhd
	$(QUARTUS_BIN_DIR)/quartus_sh --flow compile $(PROJECT)

check: ./rtl_work/
	$(MODELSIM_BIN_DIR)/vmap work rtl_work
#	$(MODELSIM_BIN_DIR)/vcom -93 $(MODELSIM_LIB_FLAGS) $(PLD_DIR)/PAC_*.vhd
	$(MODELSIM_BIN_DIR)/vcom -93 $(MODELSIM_LIB_FLAGS) $(PLD_DIR)/*.vhd
	$(MODELSIM_BIN_DIR)/vlog -sv $(MODELSIM_LIB_FLAGS) +incdir+$(TB_DIR) $(TB_SRC)
	$(MODELSIM_BIN_DIR)/vsim $(MODELSIM_SIM_FLAGS) -msgmode both -displaymsgmode both TB_$(PROJECT) $(MODELSIM_DO_FLAGS)

./rtl_work/: $(TB_SRC)
	$(if $(lib_exist),$(MODELSIM_BIN_DIR)/vdel -lib rtl_work -all)
	$(MODELSIM_BIN_DIR)/vlib rtl_work

.PHONY: all check