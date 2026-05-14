# --- Variables ---
# Simulator and Viewer
VERILOG = iverilog
SIM = vvp
VIEWER = gtkwave

# Folders
RTL_DIR = rtl
TB_DIR = tb
SIM_DIR = sim

# Common shared modules needed by most stages (adders, muxes, etc.)
SHARED = $(RTL_DIR)/shared_modules.v

# --- Rules ---

# Default target: list the options
help:
	@echo "Usage: make [stage]"
	@echo "Example: make fetch  -> runs IF_tb"
	@echo "Example: make forward -> runs forwarding_tb"
	@echo "Example: make clean  -> cleans sim folder"

# 1. Fetch Stage
fetch:
	mkdir -p $(SIM_DIR) 
	$(VERILOG) -o $(SIM_DIR)/fetch.out $(SHARED) $(RTL_DIR)/fetch_stage.v $(TB_DIR)/IF_tb.v
	$(SIM) $(SIM_DIR)/fetch.out
	mv IF_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/IF_tb.vcd &

# 2. Decode Stage
decode:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/decode.out $(SHARED) $(RTL_DIR)/decode_stage.v $(RTL_DIR)/fetch_stage.v $(TB_DIR)/ID_tb.v
	$(SIM) $(SIM_DIR)/decode.out
	mv ID_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/ID_tb.vcd &

# 3. Execute Stage
execute:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/execute.out $(SHARED) $(RTL_DIR)/execute_stage.v  $(RTL_DIR)/decode_stage.v $(RTL_DIR)/fetch_stage.v $(TB_DIR)/EX_tb.v
	$(SIM) $(SIM_DIR)/execute.out
	mv EX_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/EX_tb.vcd &

# 4. Memory  Stage
memory:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/mem.out $(SHARED) $(RTL_DIR)/mem_stage.v $(RTL_DIR)/data_mem.v $(TB_DIR)/MEM_tb.v
	$(SIM) $(SIM_DIR)/mem.out
	mv MEM_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/MEM_tb.vcd &


# 5. Writeback  Stage
writeback:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/WB.out $(SHARED) $(RTL_DIR)/wb_stage.v $(TB_DIR)/WB_tb.v
	$(SIM) $(SIM_DIR)/WB.out
	mv WB_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/WB_tb.vcd &


# 6. Full CPU Integration
cpu:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/cpu.out $(RTL_DIR)/*.v $(TB_DIR)/cpu_tb.v
	$(SIM) $(SIM_DIR)/cpu.out
	mv cpu_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/cpu_tb.vcd &

# 7. Forwarding Unit
forward:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/forward.out $(RTL_DIR)/forwarding.v $(TB_DIR)/forwarding_tb.v
	$(SIM) $(SIM_DIR)/forward.out
	mv forwarding_tb.vcd $(SIM_DIR)/ 
	$(VIEWER) $(SIM_DIR)/forwarding_tb.vcd &

hazard:
	mkdir -p $(SIM_DIR)
	$(VERILOG) -o $(SIM_DIR)/hazard.out $(RTL_DIR)/hazard.v $(RTL_DIR)/shared_modules.v $(TB_DIR)/hazard_tb.v
	$(SIM) $(SIM_DIR)/hazard.out
	mv hazard_tb.vcd $(SIM_DIR)/ 


# Clean sim folder
clean:
	rm -rf $(SIM_DIR)/*.out $(SIM_DIR)/*.vcd
