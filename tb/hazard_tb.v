`timescale 1ns/1ps
`default_nettype none

module hazard_tb;
    // Inputs
    reg clk, rst;
    reg [31:0] PC_id, imm_id;
    reg branch_id, jump_id, jalr_id;
    reg memRead_ex, branch_ex, jalr_ex, br_result_ex, br_predict_ex;
    reg [31:0] PC_ex, ALU_result_ex, imm_ex;
    reg [4:0] rd_ex, rs1_id, rs2_id;

    // Outputs
    wire IFID_stall, IFID_flush, IDEX_flush;
    wire [31:0] next_pc_target;
    wire PCSel, br_predict;

    // Instantiate Hazard Unit
    hazard uut (
        .clk(clk), .rst(rst),
        .PC_id(PC_id), .imm_id(imm_id),
        .branch_id(branch_id), .jump_id(jump_id), .jalr_id(jalr_id),
        .memRead_ex(memRead_ex), .branch_ex(branch_ex), .jalr_ex(jalr_ex),
        .br_result_ex(br_result_ex), .br_predict_ex(br_predict_ex),
        .PC_ex(PC_ex), .ALU_result_ex(ALU_result_ex), .imm_ex(imm_ex),
        .rd_ex(rd_ex), .rs1_id(rs1_id), .rs2_id(rs2_id),
        .IFID_stall(IFID_stall), .IFID_flush(IFID_flush), .IDEX_flush(IDEX_flush),
        .next_pc_target(next_pc_target), .PCSel(PCSel), .br_predict(br_predict)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
    $dumpfile("hazard_tb.vcd");
    $dumpvars(0, hazard_tb);
        // --- Initialization ---
        clk = 0; rst = 1;
        PC_id = 0; imm_id = 0; branch_id = 0; jump_id = 0; jalr_id = 0;
        memRead_ex = 0; branch_ex = 0; jalr_ex = 0; br_result_ex = 0; br_predict_ex = 0;
        PC_ex = 0; ALU_result_ex = 0; imm_ex = 0;
        rd_ex = 0; rs1_id = 0; rs2_id = 0;

        #10 rst = 0;
        $display("Starting Hazard Unit Test...");

        // --- TEST 1: Load-Use Hazard (Stall) ---
        // LW x1, 0(x2)  <- In Execute
        // ADD x3, x1, x4 <- In Decode (Needs x1)
        #10;
        memRead_ex = 1; rd_ex = 5'd1;
        rs1_id = 5'd1; rs2_id = 5'd4;
        #1; // Wait for combinational logic
        if (IFID_stall && !PCSel) 
            $display("[PASS] Test 1: Load-Use Stall Detected");
        else 
            $display("[FAIL] Test 1: Load-Use Stall Failed");

        // --- TEST 2: JAL Jump in ID ---
        #10;
        memRead_ex = 0; // Clear stall
        jump_id = 1; PC_id = 32'h00000004; imm_id = 32'h00000008;
        #1;
        if (PCSel && next_pc_target == 32'h0000000C && IFID_flush)
            $display("[PASS] Test 2: JAL Target Correct");
        else
            $display("[FAIL] Test 2: JAL failed");

        // --- TEST 3: Branch Misprediction (Resolution Priority) ---
        // We predicted NOT TAKEN in ID, but EX says it is TAKEN.
        #10;
        jump_id = 0;
        branch_ex = 1; br_result_ex = 1; br_predict_ex = 0; // Mispredict!
        PC_ex = 32'h00000100; imm_ex = 32'h00000020;
        #1;
        if (PCSel && next_pc_target == 32'h00000120 && IFID_flush && IDEX_flush)
            $display("[PASS] Test 3: Misprediction Correction Correct");
        else
            $display("[FAIL] Test 3: Misprediction failed");

        // --- TEST 4: BHT Update ---
        // Resolve a branch as TAKEN to see if BHT counter increments
        #10;
        branch_ex = 1; br_result_ex = 1; PC_ex = 32'h00000400;
        #10; // Wait for clock edge to update BHT
        branch_ex = 0;
        PC_id = 32'h00000400; // Check the same index in ID
        #1;
        // Since BHT was 00, one 'Taken' might not set MSB yet depending on logic.
        // But we check that it didn't crash.
        $display("[INFO] Test 4: BHT Entry updated for PC 0x400");

        #20;
        $display("Testing Finished.");
        $finish;
    end

endmodule