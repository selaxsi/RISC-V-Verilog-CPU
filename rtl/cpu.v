`default_nettype none

module cpu(
    input clk, rst,
    output [31:0] PC_fetch_out,
    output [31:0] instr_fetch_out,
    output [31:0] WB_result_out
);

    // Fetch stage control
    wire        IFID_stall_w, IFID_flush_w;
    wire        IDEX_flush_w;
    wire        PCSel_w;
    wire [31:0] next_pc_target_w;
    wire [31:0] PC_fetch_w, instr_fetch_w;

    fetch_stage IF_STAGE (
        .clk(clk),
        .rst(rst),
        .stall(IFID_stall_w),
        .flush(IFID_flush_w),
        .PCSel(PCSel_w),
        .jump_target(next_pc_target_w),
        .PC_out(PC_fetch_w),
        .instruction_out(instr_fetch_w)
    );

    assign PC_fetch_out   = PC_fetch_w;
    assign instr_fetch_out = instr_fetch_w;


       // Decode stage
    wire [31:0] PC_id_w, instr_id_w;
    wire ALUSrc_id_w, memRead_id_w, memWrite_id_w, jalr_id_w, jump_id_w, branch_id_w, regWrite_id_w;
    wire [1:0] resultSrc_id_w;
    wire [3:0] ALUControl_id_w;
    wire [31:0] immediate_id_w, rs1_val_id_w, rs2_val_id_w;
    wire bgef3_id_w;
    wire [4:0] rs1_id_w, rs2_id_w, rd_id_w;

    wire        regWrite_wb_w;
    wire [4:0]  rd_wb_w;
    wire [31:0] WB_result_w;

    wire [31:0] PC_early_id_w, imm_early_id_w;
    wire branch_early_id_w, jump_early_id_w, jalr_early_id_w;
    wire [4:0] rs1_early_id_w, rs2_early_id_w;


    decode_stage ID_STAGE (
        .clk(clk),
        .rst(rst),
        .flush(IDEX_flush_w),
        .stall(IFID_stall_w),
        .regWrite_in(regWrite_wb_w),
        .instruction_in(instr_fetch_w),
        .PC_in(PC_fetch_w),
        .WB_result(WB_result_w),
        .rd_in(rd_wb_w),

        .forwardA(forwardIDA_w), .forwardB(forwardIDB_w),
        .WB_result_wb(WB_result_w),

        .PC_out(PC_id_w),
        .instruction_out(instr_id_w),
        .ALUSrc_out(ALUSrc_id_w),
        .memRead_out(memRead_id_w),
        .memWrite_out(memWrite_id_w),
        .jalr_out(jalr_id_w),
        .jump_out(jump_id_w),
        .branch_out(branch_id_w),
        .regWrite_out(regWrite_id_w),
        .resultSrc_out(resultSrc_id_w),
        .ALUControl_out(ALUControl_id_w),
        .immediate_out(immediate_id_w),
        .rs1_val_out(rs1_val_id_w),
        .rs2_val_out(rs2_val_id_w),
        .bgef3_out(bgef3_id_w),
        .rs1_out(rs1_id_w),
        .rs2_out(rs2_id_w),
        .rd_out(rd_id_w),

        .PC_early(PC_early_id_w),
        .imm_early(imm_early_id_w),
        .branch_early(branch_early_id_w),
        .jump_early(jump_early_id_w),
        .jalr_early(jalr_early_id_w),
        .rs1_early(rs1_early_id_w),
        .rs2_early(rs2_early_id_w)
    );



    // Forwarding
    wire [1:0] forwardA_w, forwardB_w;
    wire forwardIDA_w, forwardIDB_w;

    forwarding FWD (
        .rs1_ex(rs1_id_w), .rs2_ex(rs2_id_w), //wire outputs from id/ex
        .rs1_id(rs1_early_id_w), .rs2_id(rs2_early_id_w), 
        .rd_mem(rd_ex_w), .rd_wb(rd_wb_w), //outputs
        .regWrite_mem(regWrite_ex_w), .regWrite_wb(regWrite_wb_w),
        .forwardA(forwardA_w), .forwardB(forwardB_w), 
        .forwardIDA(forwardIDA_w), .forwardIDB(forwardIDB_w)
    );

    // Execute stage
    wire [31:0] ALU_result_ex_w;
    wire [31:0] instr_ex_w, PC_ex_w, rs2_val_ex_w;
    wire PCSel_ex_w, PCSel_early_w, branch_ex_w, jalr_ex_w;
    wire memRead_ex_w, memWrite_ex_w, regWrite_ex_w;
    wire [1:0] resultSrc_ex_w;
    wire [4:0] rs1_ex_w, rs2_ex_w, rd_ex_w;

    wire memRead_early_ex_w, branch_early_ex_w, jalr_early_ex_w, br_predict_ex_w;
    wire [31:0] PC_early_ex_w, ALU_result_early_ex_w, imm_early_ex_w;
    wire [4:0] rd_early_ex_w;

    execute_stage EX_STAGE (
        .clk(clk), .rst(rst),
        .jalr(jalr_id_w), .jump(jump_id_w), .branch_in(branch_id_w), .bgef3(bgef3_id_w),
        .br_predict_hazard(br_predict_h_w),
        .ALUSrc(ALUSrc_id_w), .ALUControl(ALUControl_id_w),
        .immediate(immediate_id_w), .rs1_val(rs1_val_id_w), .rs2_val_in(rs2_val_id_w),
        .instruction_in(instr_id_w), .PC_in(PC_id_w),
        .memRead_in(memRead_id_w), .memWrite_in(memWrite_id_w), .regWrite_in(regWrite_id_w),
        .resultSrc_in(resultSrc_id_w), .rs1_in(rs1_id_w), .rs2_in(rs2_id_w), .rd_in(rd_id_w),
        .forwardA(forwardA_w), .forwardB(forwardB_w),
        .ALU_result_mem(ALU_result_ex_w), .WB_result_wb(WB_result_w),
        .ALU_result_out(ALU_result_ex_w), 
        .instruction_out(instr_ex_w),
        .PC_out(PC_ex_w), .rs2_val_out(rs2_val_ex_w), .PCSel_out(PCSel_ex_w),
        .PCSel_early_out(PCSel_early_w), .branch_out(branch_ex_w), .jalr_out(jalr_ex_w),
        .memRead_out(memRead_ex_w), .memWrite_out(memWrite_ex_w), .regWrite_out(regWrite_ex_w),
        .resultSrc_out(resultSrc_ex_w), .rs1_out(rs1_ex_w), .rs2_out(rs2_ex_w), .rd_out(rd_ex_w),
        .memRead_early(memRead_early_ex_w), .branch_early(branch_early_ex_w), 
        .jalr_early(jalr_early_ex_w), .br_predict(br_predict_ex_w),
        .PC_early(PC_early_ex_w), .ALU_result_early(ALU_result_early_ex_w),
        .imm_early(imm_early_ex_w), .rd_early(rd_early_ex_w)
 

    );

    // Memory stage
    wire [31:0] ALU_result_mem_w, mem_result_mem_w, PC_plus_4_mem_w;
    wire [1:0] resultSrc_mem_w;
    wire regWrite_mem_w;
    wire [4:0] rd_mem_w;

    mem_stage MEM_STAGE (
        .clk(clk), .rst(rst),
        .memRead_in(memRead_ex_w), .memWrite_in(memWrite_ex_w),
        .regWrite_in(regWrite_ex_w), .resultSrc_in(resultSrc_ex_w), .rd_in(rd_ex_w),
        .ALU_result_in(ALU_result_ex_w), .rs2_val_in(rs2_val_ex_w), .PC_in(PC_ex_w),
        .ALU_result_out(ALU_result_mem_w), .mem_result_out(mem_result_mem_w),
        .PC_plus_4_out(PC_plus_4_mem_w), .resultSrc_out(resultSrc_mem_w),
        .regWrite_out(regWrite_mem_w), .rd_out(rd_mem_w)
    );

    // Writeback stage 
    wb_stage WB_STAGE (
        .ALU_result_in(ALU_result_mem_w),
        .mem_result_in(mem_result_mem_w),
        .PC_plus_4_in(PC_plus_4_mem_w),
        .resultSrc_in(resultSrc_mem_w),
        .regWrite_in(regWrite_mem_w),
        .rd_in(rd_mem_w),
        .WB_result_out(WB_result_w),
        .regWrite_out(regWrite_wb_w),
        .rd_out(rd_wb_w)
    );

    //    // Hazard unit
    wire br_predict_h_w;



    hazard HDU (
        .clk(clk),
        .rst(rst),
        .PC_id(PC_early_id_w),
        .imm_id(imm_early_id_w),
        .branch_id(branch_id_w),
        .jump_id(jump_early_id_w),
        .jalr_id(jalr_early_id_w),
        .memRead_ex(memRead_early_ex_w),
        .branch_ex(branch_early_ex_w),
        .jalr_ex(jalr_early_ex_w),
        .br_result_ex(PCSel_early_w),
        .br_predict_ex(br_predict_ex_w),
        .PC_ex(PC_early_ex_w),
        .ALU_result_ex(ALU_result_early_ex_w),
        .imm_ex(immediate_id_w),
        .rd_ex(rd_early_ex_w),
        .rs1_id(rs1_early_id_w),
        .rs2_id(rs2_early_id_w),
        .IFID_stall(IFID_stall_w),
        .IFID_flush(IFID_flush_w),
        .IDEX_flush(IDEX_flush_w),
        .next_pc_target(next_pc_target_w),
        .PCSel(PCSel_w),
        .br_predict(br_predict_h_w)
    );
    assign WB_result_out = WB_result_w;

endmodule