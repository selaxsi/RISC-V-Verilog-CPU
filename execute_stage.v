`default_nettype none

//Inputs, wires, outputs
//_in : input either from previous or later stage
//_out : outputs from the current stage's pipeline register 
// _w : wires , variables created in stage
// no suffix : anything that 'dies' in this stage (will not be input to any stage or pipeline register) (could be a wire or input type)

module execute_stage(
    input clk, rst,
    input jalr, jump, branch, bgef3, ALUSrc,
    input [3:0] ALUControl,
    input [31:0] immediate, rs1_val, rs2_val_in, 
    input [31:0] instruction_in, PC_in,             
    input memRead_in, memWrite_in, regWrite_in,
    input [1:0] resultSrc_in,
    input [4:0] rs1_in, rs2_in, rd_in,

    output [31:0] ALU_result_out, jump_target_out, instruction_out, PC_out, rs2_val_out,
    output PCSel_out, memRead_out, memWrite_out, regWrite_out,
    output [1:0] resultSrc_out,
    output [4:0] rs1_out, rs2_out, rd_out

);



wire [31:0] ALU_in_A, ALU_in_B, ALU_result_w, jump_target_w;
wire PCSel_w, zero, negative, condition_met, ALUSrc_jal;



//ALU , Selection of operands for ALU
assign ALUSrc_jal = (jump && !jalr); //to handle branch calculations in ALU, choose between rs1 as ALU input or PC as ALU input (only for jal)

mux_2x1 ALU_A_mux(.a(rs1_val), .b(PC_in), .s(ALUSrc_jal), .f(ALU_in_A)); // rs1 vs PC for ALU input A
mux_2x1 ALU_B_mux(.a(rs2_val_in), .b(immediate), .s(ALUSrc), .f(ALU_in_B)); //rs2 vs immediate for ALU input B
ALU alu_(.A(ALU_in_A), .B(ALU_in_B), .ALUControl(ALUControl), .result(ALU_result_w), .zero(zero), .negative(negative) );

//Branch and jump logic  -> || && ! single bit , | & ~ multibit
mux_2x1 branch_jump_mux(.a(immediate), .b(ALU_result_w), .s(jalr), .f(jump_target_w));
assign condition_met = (bgef3)? (!negative || zero) : !zero;
assign PCSel_w = ((branch && condition_met || jump));



EX_MEM pipe_reg( 
    .clk(clk), .rst(rst),
    .ALU_result_r(ALU_result_w), 
    .jump_target_r(jump_target_w), 
    .instruction_r(instruction_in),
    .PC_r(PC_in),                   
    .PCSel_r(PCSel_w), 
    .memRead_r(memRead_in), 
    .memWrite_r(memWrite_in), 
    .regWrite_r(regWrite_in), 
    .resultSrc_r(resultSrc_in),
    .rs1_r(rs1_in), .rs2_r(rs2_in), .rd_r(rd_in), .rs2_val_r(rs2_val_in),
    
    .ALU_result(ALU_result_out), .jump_target(jump_target_out), .instruction(instruction_out), 
    .PC(PC_out), .PCSel(PCSel_out), .memRead(memRead_out), .memWrite(memWrite_out), 
    .regWrite(regWrite_out), .resultSrc(resultSrc_out), .rs1(rs1_out), .rs2(rs2_out), 
    .rd(rd_out), .rs2_val(rs2_val_out)
);



endmodule




module ALU( A,B, ALUControl, result, zero, negative);
input [31:0] A,B;
input [3:0] ALUControl;

output [31:0] result;
output zero, negative;

assign result = (ALUControl == 4'd0)? A + B : 
                (ALUControl == 4'd1)? A - B : 
                (ALUControl == 4'd2)? A & B : 
                (ALUControl == 4'd3)? A ^ B : 
                (ALUControl == 4'd4)? A | B : 
                (ALUControl == 4'd5)?  A >> B: 
                (ALUControl == 4'd6)? A >>> B: 
                (A < B); //ALUControl = 7

assign zero = (result == 0);
assign negative = (result < 0);
                

endmodule



module EX_MEM( clk, rst,
ALU_result_r, jump_target_r, instruction_r, PC_r,
 PCSel_r, memRead_r, memWrite_r, regWrite_r, resultSrc_r,
 rs1_r, rs2_r, rd_r, rs2_val_r,
 ALU_result, jump_target, instruction, PC,
 PCSel, memRead, memWrite, regWrite,
 resultSrc, rs1, rs2, rd, rs2_val
);
input clk, rst;
input [31:0] ALU_result_r, jump_target_r, instruction_r, PC_r, rs2_val_r;
input PCSel_r, memRead_r, memWrite_r, regWrite_r;
input [1:0] resultSrc_r;
input [4:0] rs1_r, rs2_r, rd_r;

output reg [31:0] ALU_result, jump_target, instruction, PC, rs2_val;
output reg PCSel, memRead, memWrite, regWrite;
output reg [1:0] resultSrc;
output reg [4:0] rs1, rs2, rd;

always @(posedge clk or posedge rst) begin
        if (rst) begin
            instruction <= 0;
            PC <= 0;

            memRead<= 0;
            memWrite <= 0;

            regWrite <= 0;
            resultSrc <= 0;


            rs2_val <= 0;
            rs1 <= 0;
            rs2 <= 0;
            rd <= 0;

            ALU_result <= 0;
            jump_target <= 0;
            PCSel <= 0;
        end

        else begin
            instruction <= instruction_r;
            PC <= PC_r;

            memRead<= memRead_r;
            memWrite <= memWrite_r;

            regWrite <= regWrite_r;
            resultSrc <= resultSrc_r;


            rs2_val <= rs2_val_r;
            rs1 <= rs1_r;
            rs2 <= rs2_r;
            rd <= rd_r;

            ALU_result <= ALU_result_r;
            jump_target <= jump_target_r;
            PCSel <= PCSel_r;
            
        end
    end



endmodule




