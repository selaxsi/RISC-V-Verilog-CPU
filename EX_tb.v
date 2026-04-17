`timescale 1ns/1ps
`default_nettype none

module EX_tb;

    // 1. Inputs to the ID_EX Pipeline Register (must be reg)
    reg clk, rst;
    reg [31:0] PC, instruction;
    reg ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite;
    reg [1:0] resultSrc;
    reg [3:0] ALUControl;
    reg [31:0] immediate, rs1_val, rs2_val;
    reg bgef3;
    reg [4:0] rs1, rs2, rd;

    // 2. Outputs from ID_EX / Inputs to EX Stage (must be wire)
    wire [31:0] PC_r, instruction_r;
    wire ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r;
    wire [1:0] resultSrc_r;
    wire [3:0] ALUControl_r;
    wire [31:0] immediate_r, rs1_val_r, rs2_val_r;
    wire bgef3_r;
    wire [4:0] rs1_r, rs2_r, rd_r;


    ID_EX pipe_reg (
        .clk(clk), .rst(rst), 
        .PC_r(PC), .instruction_r(instruction),
        .ALUSrc_r(ALUSrc), .memRead_r(memRead), .memWrite_r(memWrite),
        .jalr_r(jalr), .jump_r(jump), .branch_r(branch), .regWrite_r(regWrite),
        .resultSrc_r(resultSrc), .ALUControl_r(ALUControl), 
        .immediate_r(immediate), .rs1_val_r(rs1_val), .rs2_val_r(rs2_val),
        .bgef3_r(bgef3), .rs1_r(rs1), .rs2_r(rs2), .rd_r(rd),
        
        .PC(PC_r), .instruction(instruction_r), .ALUSrc(ALUSrc_r), .memRead(memRead_r), 
        .memWrite(memWrite_r), .jalr(jalr_r), .jump(jump_r), .branch(branch_r), .regWrite(regWrite_r),
        .resultSrc(resultSrc_r), .ALUControl(ALUControl_r), .immediate(immediate_r), 
        .rs1_val(rs1_val_r), .rs2_val(rs2_val_r), .bgef3(bgef3_r), .rs1(rs1_r), .rs2(rs2_r), .rd(rd_r)
    );

    // ex outputs
    wire [31:0] ALU_result, jump_target, instruction_ex, PC_ex, rs2_val_ex;
    wire PCSel, memRead_ex, memWrite_ex, regWrite_ex;
    wire [1:0] resultSrc_ex;
    wire [4:0] rs1_ex, rs2_ex, rd_ex;


execute_stage EX (
    .clk(clk), .rst(rst),
    .jalr(jalr_r),  .jump(jump_r),  .branch(branch_r), .bgef3(bgef3_r), 
    .ALUSrc(ALUSrc_r), .ALUControl(ALUControl_r), .immediate(immediate_r),  .rs1_val(rs1_val_r), .rs2_val_in(rs2_val_r),   
    .instruction_in(instruction_r), .PC_in(PC_r),              
    .memRead_in(memRead_r),  .memWrite_in(memWrite_r), 
    .regWrite_in(regWrite_r), .resultSrc_in(resultSrc_r), .rs1_in(rs1_r),  .rs2_in(rs2_r),  .rd_in(rd_r),
    .ALU_result_r(ALU_result),  .jump_target_r(jump_target),  .instruction_r(instruction_ex), 
    .PC_r(PC_ex), .rs2_val_r(rs2_val_ex), .PCSel_r(PCSel), 
    .memRead_r(memRead_ex),   .memWrite_r(memWrite_ex),  .regWrite_r(regWrite_ex),  .resultSrc_r(resultSrc_ex), 
    .rs1_r(rs1_ex),  .rs2_r(rs2_ex),  .rd_r(rd_ex)
);

 
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk = 0; rst = 1;
        PC = 0; instruction = 0;
        ALUSrc = 0; ALUControl = 0;
        rs1_val = 0; rs2_val = 0;
        immediate = 0;
        
        #10 rst = 0;

        // Load values into ID/EX
        @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2_val
        ALUControl = 4'b0000; // add
        rs1_val = 32'd10;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing EX Stage ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b", rs1_val_r, rs2_val_r, ALUSrc_r, ALUControl_r);
        $display("out: ALU_Result: %d", ALU_result);

        #10 $finish;
    end

endmodule