`default_nettype none
`timescale 1ns/1ps

//Naming convention:
//_in : input either from previous or later stage
//_out : outputs from the current stage's pipeline register 
// _w : wires , variables created in stage
// no suffix : anything that 'dies' in this stage (will not be input to any stage or pipeline register) (could be a wire or input type)
// _r : input parameters of the pipeline registers, connect _w or _in to them

module decode_stage(
    input clk,rst, regWrite_in,
input flush, stall,
input [4:0] rd_in, //for writing to reg from prev instruction
input [31:0] instruction_in, PC_in, WB_result,

output [31:0] PC_out, instruction_out,
output ALUSrc_out, memRead_out, memWrite_out, jalr_out, jump_out, branch_out, regWrite_out,
output [1:0] resultSrc_out,
output [3:0] ALUControl_out,
output [31:0] immediate_out, rs1_val_out, rs2_val_out,
output bgef3_out, // = msb of funct3
output [4:0] rs1_out, rs2_out, rd_out,

output [31:0] PC_early, imm_early,
output branch_early, jump_early, jalr_early,
output [4:0] rs1_early, rs2_early


);



wire ALUSrc_w, memRead_w, memWrite_w, jalr_w, jump_w, branch_w, regWrite_w; 
wire [1:0] ALUOp, resultSrc_w, immSrc;
wire [3:0] ALUControl_w;
wire [31:0] immediate_w, rs1_val_w, rs2_val_w;
wire [4:0] rs1_w, rs2_w, rd_w;


assign rs1_w = instruction_in[19:15];
assign rs2_w = instruction_in[24:20];
assign rd_w  = instruction_in[11:7];

control_unit CU(
    .opcode(instruction_in[6:0]),
    .funct3(instruction_in[14:12]),
    .funct7(instruction_in[31:25]),
    .ALUSrc(ALUSrc_w),
    .ALUOp(ALUOp),
    .memRead(memRead_w),
     .memWrite(memWrite_w),
     .jalr(jalr_w), 
     .jump(jump_w),
     .branch(branch_w), 
     .regWrite(regWrite_w),
     .resultSrc(resultSrc_w),
     .immSrc(immSrc)

);

imm_gen IMM( .inst(instruction_in), .immSrc(immSrc), 
.immediate(immediate_w)
);

register_file RF(
.clk(clk), .rst(rst), .regWrite(regWrite_in),
.rs1(rs1_w), .rs2(rs2_w), .rd(rd_in), .WB_result(WB_result),
.rs1_val(rs1_val_w), .rs2_val(rs2_val_w)
);

ALU_control ALUControl(
    .funct3(instruction_in[14:12]),
    .funct7(instruction_in[31:25]),
    .ALUOp(ALUOp),
    .ALUControl(ALUControl_w)

);

assign imm_early = immediate_w;
assign branch_early = branch_w;
assign jalr_early = jalr_w;
assign jump_early = jump_w;
assign rs1_early = rs1_w;
assign rs2_early = rs2_w;
assign PC_early = PC_in;

ID_EX pipe_reg (
    .clk(clk), .rst(rst), .flush(flush),
    .PC_r(PC_in),
    .instruction_r(instruction_in),
    .ALUSrc_r(ALUSrc_w), .memRead_r(memRead_w), .memWrite_r(memWrite_w),
    .jalr_r(jalr_w), .jump_r(jump_w), .branch_r(branch_w), .regWrite_r(regWrite_w),
    .resultSrc_r(resultSrc_w), .ALUControl_r(ALUControl_w),
    .immediate_r(immediate_w), .rs1_val_r(rs1_val_w), .rs2_val_r(rs2_val_w),
    .bgef3_r(instruction_in[14]), .rs1_r(rs1_w), .rs2_r(rs2_w), .rd_r(rd_w),

    .instruction(instruction_out), .PC(PC_out),
    .ALUSrc(ALUSrc_out), .memRead(memRead_out), .memWrite(memWrite_out),
    .jalr(jalr_out), .jump(jump_out), .branch(branch_out), .regWrite(regWrite_out),
    .resultSrc(resultSrc_out), .ALUControl(ALUControl_out), .immediate(immediate_out),
    .rs1_val(rs1_val_out), .rs2_val(rs2_val_out), .bgef3(bgef3_out),
    .rs1(rs1_out), .rs2(rs2_out), .rd(rd_out)
);

//always @(PC_in) $display("from decode : PC %h : ALUSrc %d", PC_in, ALUSrc_w);

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

assign ALUSrc = (opcode == 7'h34 || opcode == 7'h64) ? 1'b0 : 1'b1; //R type = 0, o.w = 1 , this is for ALU
assign memRead = (opcode == 7'h14 & funct3 == 3'h3)? 1'b1  : 1'b0; //only load needs this
assign memWrite = (opcode == 7'h24)? 1'b1 : 1'b0; //only sw
assign jalr = (opcode == 7'h68)? 1'b1 : 1'b0;
assign jump = (opcode == 7'h68 | opcode == 7'h70)? 1'b1 : 1'b0; //jalr and jal
assign branch = (opcode == 7'h64)? 1'b1 : 1'b0;
assign regWrite = (opcode == 7'h64 | opcode == 7'h24)? 1'b0 : 1'b1; //only sw and beq/bne dont WB to reg
assign resultSrc = (opcode == 7'h68 | opcode == 7'h70)? 2'b10 : 
                   (opcode == 7'h14 & funct3 == 3'h3)? 2'b01 : 
                   2'b00; //this is for WB mux

assign ALUOp = (opcode == 7'h34)? 2'b00 :
               (opcode == 7'h64)? 2'b10 :
               (opcode == 7'h14) ? 2'b11 :
               2'b01; //R type = 00, branch = 10 (sub), o.w 01 (add)

assign immSrc = (opcode == 7'h14 | opcode == 7'h68)? 2'b00 : (opcode == 7'h24)? 2'b01 : (opcode == 7'h64)? 2'b10 : 2'b11;


endmodule

module ALU_control (funct3, funct7, ALUOp, ALUControl);
    input [2:0] funct3;
    input [6:0] funct7;
    input [1:0] ALUOp;
    output reg [3:0] ALUControl;

    always @(*) begin
        case (ALUOp)
            2'b00: begin  // R‑type instructions
                case ({funct7, funct3})
                    // addw:  funct7=10, funct3=1
                    {7'h10, 3'h1}: ALUControl = 4'd0;
                    // and: funct7=10, funct3=0
                    {7'h10, 3'h0}: ALUControl = 4'd2;
                    // xor: funct7=10, funct3=5
                    {7'h10, 3'h5}: ALUControl = 4'd3;
                    // or: funct7=10, funct3=7
                    {7'h10, 3'h7}: ALUControl = 4'd4;
                    // sltu: funct7=1, funct3=4
                    {7'h01, 3'h4}: ALUControl = 4'd7;
                    // srl: funct7=10, funct3=6
                    {7'h10, 3'h6}: ALUControl = 4'd5;
                    // sra: funct7=30, funct3=6
                    {7'h30, 3'h6}: ALUControl = 4'd6;
                    default: ALUControl = 4'd0;
                endcase
            end
            2'b01: ALUControl = 4'd0;   // I‑type addi
            2'b10: ALUControl = 4'd1;   // branch (sub)
            2'b11: begin
            case (funct3)
                3'h0: ALUControl = 4'd2;   // andi (AND)
                3'h1: ALUControl = 4'd0;   // addi (ADD)
                3'h4: ALUControl = 4'd3;   // xori (XOR)  – from your table
                3'h5: ALUControl = 4'd3;   // also xori (funct3=5 in some encodings)
                3'h6: ALUControl = 4'd5;   // slli? Not in your table, but keep safe
                3'h7: ALUControl = 4'd4;   // ori (OR)
                default: ALUControl = 4'd0;
            endcase
        end
            default: ALUControl = 4'd0;
        endcase
    end
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
            $display("---in ID RF: rd %d, WB_result %d, time %t", rd, WB_result, $time);
            end
    end

    always @ (*)
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
    clk, rst, flush, ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r,
    resultSrc_r,  ALUControl_r, immediate_r, rs1_val_r, rs2_val_r, bgef3_r, 
    rs1_r, rs2_r, rd_r,
    instruction, PC,
    ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite,
    resultSrc, ALUControl, immediate, rs1_val, rs2_val,
    bgef3, rs1, rs2, rd

);

input [31:0] PC_r, instruction_r;
input clk, rst, flush, ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r;
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
            instruction <= 0; PC <= 0;
            ALUSrc <= 0; memRead <= 0; memWrite <= 0;
            jalr <= 0; jump <= 0; branch <= 0; regWrite <= 0;
            resultSrc <= 0; ALUControl <= 0;
            immediate <= 0; rs1_val <= 0; rs2_val <= 0;
            bgef3 <= 0; rs1 <= 0; rs2 <= 0; rd <= 0;
        end

        else if (flush) begin  
            instruction <= 0; PC <= 0;
            ALUSrc <= 0; memRead <= 0; memWrite <= 0;
            jalr <= 0; jump <= 0; branch <= 0; regWrite <= 0;
            resultSrc <= 0; ALUControl <= 0;
            immediate <= 0; rs1_val <= 0; rs2_val <= 0;
            bgef3 <= 0; rs1 <= 0; rs2 <= 0; rd <= 0;
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
                        $display("---in IDEX--- : PC %h, rs2_val %d, time %t", PC, rs2_val, $time);

        end
    end


endmodule