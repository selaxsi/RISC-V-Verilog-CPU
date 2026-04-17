`default_nettype none
`timescale 1ns/1ps
module decode_stage( clk, rst, regWrite_in, instruction, PC, WB_result, rd_in,
 PC_r, instruction_r, ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r,
 resultSrc_r , ALUControl_r, immediate_r, rs1_val_r, rs2_val_r, bgef3_r, rs1_r, rs2_r, rd_r //25 parameters
);
//_out = written to pipeline register
// _r = output from pipeline register

input clk,rst, regWrite_in;
input [4:0] rd_in; //for writing to reg from prev instruction
input [31:0] instruction, PC, WB_result;

wire ALUSrc_out, memRead_out, memWrite_out, jalr_out, jump_out, branch_out, regWrite_out; 
wire [1:0] ALUOp, resultSrc_out, immSrc;
wire [3:0] ALUControl_out;
wire [31:0] immediate_out, rs1_val_out, rs2_val_out;
wire [4:0] rs1_out, rs2_out, rd_out;


output [31:0] PC_r, instruction_r;
output ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r;
output [1:0] resultSrc_r;
output [3:0] ALUControl_r;
output [31:0] immediate_r, rs1_val_r, rs2_val_r;
output bgef3_r; // = msb of funct3
output [4:0] rs1_r, rs2_r, rd_r;

assign rs1_out = instruction[19:15];
assign rs2_out = instruction[24:20];
assign rd_out  = instruction[11:7];

control_unit CU(
    .opcode(instruction[6:0]),
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),
    .ALUSrc(ALUSrc_out),
    .ALUOp(ALUOp),
    .memRead(memRead_out),
     .memWrite(memWrite_out),
     .jalr(jalr_out), 
     .jump(jump_out),
     .branch(branch_out), 
     .regWrite(regWrite_out),
     .immSrc(immSrc)

);

imm_gen IMM( .inst(instruction), .immSrc(immSrc), 
.immediate(immediate_out)
);

register_file RF(
.clk(clk), .rst(rst), .regWrite(regWrite_in),
.rs1(rs1_out), .rs2(rs2_out), .rd(rd_in), .WB_result(WB_result),
.rs1_val(rs1_val_out), .rs2_val(rs2_val_out)
);

ALU_control ALUControl(
    .funct3(instruction[14:12]),
    .funct7(instruction[31:25]),
    .ALUOp(ALUOp),
    .ALUControl(ALUControl_out)

);

ID_EX pipe_reg (
    .clk(clk), .rst(rst), .PC_r(PC), .instruction_r(instruction),
    .ALUSrc_r(ALUSrc_out), .memRead_r(memRead_out), .memWrite_r(memWrite_out),
    .jalr_r(jalr_out), .jump_r(jump_out), .branch_r(branch_out), .regWrite_r(regWrite_out),
    .resultSrc_r(resultSrc_out), .ALUControl_r(ALUControl_out), 
    .immediate_r(immediate_out), .rs1_val_r(rs1_val_out), .rs2_val_r(rs2_val_out),
    .bgef3_r(instruction[14]), .rs1_r(instruction[19:15]), .rs2_r(instruction[24:20]), .rd_r(instruction[11:7]),
    
    .PC(PC_r), .instruction(instruction_r) , .ALUSrc(ALUSrc_r), .memRead(memRead_r), 
    .memWrite(memWrite_r), .jalr(jalr_r), .jump(jump_r), .branch(branch_r), .regWrite(regWrite_r),
    .resultSrc(resultSrc_r), .ALUControl(ALUControl_r), .immediate(immediate_r), 
    .rs1_val(rs1_val_r), .rs2_val(rs2_val_r), .bgef3(bgef3_r), .rs1(rs1_r), .rs2(rs2_r), .rd(rd_r)
);


endmodule



module control_unit( 
opcode, funct7, funct3, 
ALUSrc, ALUOp, memRead, memWrite, 
jalr, jump, branch, regWrite, resultSrc, immSrc
);

input [6:0] opcode, funct7;
input [2:0] funct3;
output ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite;
output [1:0] ALUOp, resultSrc, immSrc;

assign ALUSrc = (opcode == 7'h34)? 1'b0 : 1'b1; //R type = 0, o.w = 1 , this is for ALU
assign memRead = (opcode == 7'h34 & funct3 == 7'h3)? 1'b1  : 1'b0; //only load needs this
assign memWrite = (opcode == 7'h24)? 1'b1 : 1'b0; //only sw
assign jalr = (opcode == 7'h68)? 1'b1 : 1'b0;
assign jump = (opcode == 7'h68 | opcode == 7'h70)? 1'b1 : 1'b0; //jalr and jal
assign branch = (opcode == 7'h64)? 1'b1 : 1'b0;
assign regWrite = (opcode == 7'h64 | opcode == 7'h24)? 1'b0 : 1'b1; //only sw and beq/bne dont WB to reg

assign resultSrc = (opcode == 7'h68 | opcode == 7'h70)? 2'b10 : (opcode == 7'h34 & funct3 == 7'h3)? 2'b01 : 2'b00; //this is for WB mux

assign ALUOp = (opcode == 7'h34)? 2'b00 : (opcode == 7'h64 )? 2'b10 : 2'b01; //R type = 00, branch = 10 (sub), o.w 01 (add)

assign immSrc = (opcode == 7'h14 | opcode == 7'h68)? 2'b00 : (opcode == 7'h24)? 2'b01 : (opcode == 7'h64)? 2'b10 : 2'b11;


endmodule

module ALU_control (funct3, funct7, ALUOp, ALUControl);

input [6:0] funct7;
input [2:0] funct3;
input [1:0] ALUOp;
output [3:0] ALUControl;

assign ALUControl = (ALUOp == 2'b00)? 4'b0 : (ALUOp == 2'b01)? 4'b1 :
                    (funct3 == 3'd1)? 4'b0 :
                    (funct3 == 3'd0)? 4'b10 :
                    (funct3 == 3'd5)? 4'b11 :
                    (funct3 == 3'd7)? 4'b100 :
                    (funct3 == 3'd4)? 4'b111 :
                    (funct3 == 3'd6 & funct7 == 7'h10)? 4'b101 :
                    4'b110 ; //funct7 == 70
                    


endmodule


module imm_gen( inst, immSrc, immediate

);

input [31:0] inst;
input [1:0] immSrc;
output [31:0] immediate;

assign immediate = (immSrc == 2'd0)?  { {20{inst[31]}}, inst[31:20] } : 
                   (immSrc == 2'd1)? { {20{inst[31]}}, inst[31:25], inst[11:7] } :
                   (immSrc == 2'd2)? { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 } :
                   { {11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0 };  //immsrc = 3

endmodule


module register_file(
clk, rst, regWrite,
rs1, rs2, rd,
WB_result,
rs1_val, rs2_val

);
   input clk,rst, regWrite;
    input [4:0] rs1, rs2, rd; //rd from prev instruction
    input [31:0] WB_result;
    output reg [31:0] rs1_val , rs2_val;

    reg [31:0] register [31:0];

    always @ (posedge clk)
    begin
 
            if (regWrite & rd !=5'b0) begin
            register[rd] <= WB_result;
            end
    end

    always @ (negedge clk)
    begin
     rs1_val = (rst==1'b1) ? 32'd0 : register[rs1];
     rs2_val = (rst==1'b1) ? 32'd0 : register[rs2];
    end

  integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) register[i] = 32'h0;
    end

endmodule



module ID_EX(
   PC_r, instruction_r,
    clk, rst, ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r,
    resultSrc_r,  ALUControl_r, immediate_r, rs1_val_r, rs2_val_r, bgef3_r, 
    rs1_r, rs2_r, rd_r,
    instruction, PC,
    ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite,
    resultSrc, ALUControl, immediate, rs1_val, rs2_val,
    bgef3, rs1, rs2, rd

);

input [31:0] PC_r, instruction_r;
input clk, rst, ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r;
input [1:0] resultSrc_r;
input [3:0] ALUControl_r;
input [31:0] immediate_r, rs1_val_r, rs2_val_r;
input bgef3_r;
input [4:0] rs1_r, rs2_r, rd_r;

output reg [31:0]  PC, instruction;
output reg ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite;
output reg [1:0] resultSrc;
output reg [3:0] ALUControl;
output reg [31:0] immediate, rs1_val, rs2_val;
output reg bgef3;
output reg [4:0] rs1, rs2, rd;

always @(posedge clk or posedge rst) begin
        if (rst) begin
            instruction <= 0;
            PC <= 0;
            ALUSrc <= 0;
            memRead<= 0;
            memWrite <= 0;
            jalr <= 0;
            jump <= 0;
            branch <= 0;
            regWrite <= 0;
            resultSrc <= 0;
            ALUControl <= 0;
            immediate <= 0;
            rs1_val <= 0;
            rs2_val <= 0;
            bgef3 <= 0;
            rs1 <= 0;
            rs2 <= 0;
            rd <= 0;
        end

        else begin
            instruction <= instruction_r;
            PC <= PC_r;
            ALUSrc <= ALUSrc_r;
            memRead<= memRead_r;
            memWrite <= memWrite_r;
            jalr <= jalr_r;
            jump <= jump_r;
            branch <= branch_r;
            regWrite <= regWrite_r;
            resultSrc <= resultSrc_r;
            ALUControl <= ALUControl_r;
            immediate <= immediate_r;
            rs1_val <= rs1_val_r;
            rs2_val <= rs2_val_r;
            bgef3 <= bgef3_r;
            rs1 <= rs1_r;
            rs2 <= rs2_r;
            rd <= rd_r;
            
        end
    end


endmodule