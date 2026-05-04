`default_nettype none

module cpu(
    input clk,
    input rst,

    output [31:0] PC_fetch_out,
    output [31:0] instr_fetch_out,
    output [31:0] WB_result_out
);

    wire PCSel_w;
    wire PCSel_early_w;
    wire flush_w;
    wire [31:0] jump_target_w;
    wire [31:0] jump_target_early_w;

    assign PCSel_w       = PCSel_early_w;
    assign flush_w       = PCSel_early_w;
    assign jump_target_w = jump_target_early_w;

    wire [31:0] PC_if_w;
    wire [31:0] instr_if_w;

    fetch_stage IF_STAGE (
        .clk(clk),
        .rst(rst),
        .PCSel(PCSel_w),
        .jump_target(jump_target_w),
        .PC_out(PC_if_w),
        .instruction_out(instr_if_w)
    );

      wire [31:0] instr_ifid, PC_ifid;

    IF_ID IFID(.clk(clk), .rst(rst), .stall(stall), .PC_r(PC_if_w)  , .flush(IFID_flush),
        , .instr_r(instr_if_w), .instr(instr_ifid), .PC(PC_ifid),
        .rs1_out(rs1_out), .rs2_out(rs2_out));

    assign PC_fetch_out    = PC_ifid;
    assign instr_fetch_out = instr_ifid;

    wire [31:0] PC_id_w, instr_id_w;
    wire ALUSrc_id_w, memRead_id_w, memWrite_id_w;
    wire jalr_id_w, jump_id_w, branch_id_w, regWrite_id_w;
    wire [1:0] resultSrc_id_w;
    wire [3:0] ALUControl_id_w;
    wire [31:0] immediate_id_w, rs1_val_id_w, rs2_val_id_w;
    wire bgef3_id_w;
    wire [4:0] rs1_id_w, rs2_id_w, rd_id_w;

// write-back path back into register file
    wire regWrite_wb_w;
    wire [4:0] rd_wb_w;
    wire [31:0] WB_result_w;

    decode_stage ID_STAGE (
        .clk(clk),
        .rst(rst),
        .flush(flush_w),
        .regWrite_in(regWrite_wb_w),
        .instruction_in(instr_if_w),
        .PC_in(PC_if_w),
        .WB_result(WB_result_w),
        .rd_in(rd_wb_w),

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
        .rd_out(rd_id_w)
    );

    wire [31:0] ALU_result_ex_w, jump_target_ex_w;
    wire [31:0] instr_ex_w, PC_ex_w, rs2_val_ex_w;
    wire PCSel_ex_w;
    wire memRead_ex_w, memWrite_ex_w, regWrite_ex_w;
    wire [1:0] resultSrc_ex_w;
    wire [4:0] rs1_ex_w, rs2_ex_w, rd_ex_w;

    execute_stage EX_STAGE (
        .clk(clk),
        .rst(rst),
        .jalr(jalr_id_w),
        .jump(jump_id_w),
        .branch(branch_id_w),
        .bgef3(bgef3_id_w),
        .ALUSrc(ALUSrc_id_w),
        .ALUControl(ALUControl_id_w),
        .immediate(immediate_id_w),
        .rs1_val(rs1_val_id_w),
        .rs2_val_in(rs2_val_id_w),
        .instruction_in(instr_id_w),
        .PC_in(PC_id_w),
        .memRead_in(memRead_id_w),
        .memWrite_in(memWrite_id_w),
        .regWrite_in(regWrite_id_w),
        .resultSrc_in(resultSrc_id_w),
        .rs1_in(rs1_id_w),
        .rs2_in(rs2_id_w),
        .rd_in(rd_id_w),

        .ALU_result_out(ALU_result_ex_w),
        .jump_target_out(jump_target_ex_w),
        .jump_target_early_out(jump_target_early_w),
        .instruction_out(instr_ex_w),
        .PC_out(PC_ex_w),
        .rs2_val_out(rs2_val_ex_w),
        .PCSel_out(PCSel_ex_w),
        .PCSel_early_out(PCSel_early_w),
        .memRead_out(memRead_ex_w),
        .memWrite_out(memWrite_ex_w),
        .regWrite_out(regWrite_ex_w),
        .resultSrc_out(resultSrc_ex_w),
        .rs1_out(rs1_ex_w),
        .rs2_out(rs2_ex_w),
        .rd_out(rd_ex_w)
    );
    
    // connect branch/jump decision back to IF
    wire [31:0] ALU_result_mem_w, mem_result_mem_w, PC_plus_4_mem_w;
    wire [1:0] resultSrc_mem_w;
    wire regWrite_mem_w;
    wire [4:0] rd_mem_w;

    mem_stage MEM_STAGE (
        .clk(clk),
        .rst(rst),
        .memRead_in(memRead_ex_w),
        .memWrite_in(memWrite_ex_w),
        .regWrite_in(regWrite_ex_w),
        .resultSrc_in(resultSrc_ex_w),
        .rd_in(rd_ex_w),
        .ALU_result_in(ALU_result_ex_w),
        .rs2_val_in(rs2_val_ex_w),
        .PC_in(PC_ex_w),

        .ALU_result_out(ALU_result_mem_w),
        .mem_result_out(mem_result_mem_w),
        .PC_plus_4_out(PC_plus_4_mem_w),
        .resultSrc_out(resultSrc_mem_w),
        .regWrite_out(regWrite_mem_w),
        .rd_out(rd_mem_w)
    );


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

    assign WB_result_out = WB_result_w;

endmodule