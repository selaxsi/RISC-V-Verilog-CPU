`default_nettype none

//Inputs, wires, outputs
//_in : input either from previous or later stage
//_out : outputs from the current stage's pipeline register 
// _w : wires , variables created in stage
// no suffix : anything that 'dies' in this stage (will not be input to any stage or pipeline register) (could be a wire or input type)

module execute_stage(
    input clk, rst,
    input jalr, jump, branch_in, bgef3, ALUSrc,
    input [3:0] ALUControl,
    input [31:0] immediate, rs1_val, rs2_val_in,
    input [31:0] instruction_in, PC_in,
    input memRead_in, memWrite_in, regWrite_in,
    input [1:0] resultSrc_in,
    input [4:0] rs1_in, rs2_in, rd_in,
    // Forwarding inputs:
    input [1:0]  forwardA,
    input [1:0]  forwardB,
    input [31:0] ALU_result_mem,
    input [31:0] WB_result_wb,

    input br_predict_hazard,

    output [31:0] ALU_result_out, instruction_out, PC_out, rs2_val_out, 
    output jalr_out,
    output PCSel_out, PCSel_early_out, memRead_out, memWrite_out, regWrite_out, branch_out,
    output [1:0] resultSrc_out,
    output [4:0] rs1_out, rs2_out, rd_out,

    output memRead_early, branch_early, jalr_early, br_predict,
    output [31:0] PC_early, ALU_result_early, imm_early,
    output [4:0] rd_early

);



wire [31:0] ALU_in_A, ALU_in_B, ALU_result_w;
wire [31:0] rs2_val_forwarded;
wire PCSel_w, zero, negative, condition_met;

// 3-to-1 mux for ALU input A
mux_3x1 fwd_A_mux(
    .a(rs1_val),
    .b(ALU_result_mem),
    .c(WB_result_wb),
    .s(forwardA),
    .f(ALU_in_A)
);

// 3-to-1 mux for rs2 forwarding
mux_3x1 fwd_B_mux(
    .a(rs2_val_in),
    .b(ALU_result_mem),
    .c(WB_result_wb),
    .s(forwardB),
    .f(rs2_val_forwarded)
);

//ALU , Selection of operands for ALU
mux_2x1 ALU_B_mux(.a(rs2_val_forwarded), .b(immediate), .s(ALUSrc), .f(ALU_in_B)); //rs2 vs immediate for ALU input B
ALU alu_(.A(ALU_in_A), .B(ALU_in_B), .ALUControl(ALUControl), .result(ALU_result_w), .zero(zero), .negative(negative) );


//Branch and jump logic  
//wire [31:0] PC_plus_imm;
//adder branch_adder(.a(PC_in), .b(immediate), .f(PC_plus_imm));
//mux_2x1 branch_jump_mux(.a(PC_plus_imm), .b(ALU_result_w), .s(jalr), .f(jump_target_w));
assign condition_met = (bgef3)? (!negative || zero) : !zero;
assign PCSel_w = ((branch_in && condition_met) || jump);

assign PCSel_early_out = PCSel_w; 
assign jalr_early = jalr;
assign branch_early = branch_in;
assign rd_early = rd_in;
assign memRead_early = memRead_in;
assign ALU_result_early = ALU_result_w;
assign imm_early = immediate;
assign PC_early = PC_in;
assign br_predict = br_predict_hazard;


EX_MEM pipe_reg( 
    .clk(clk), .rst(rst),
    .ALU_result_r(ALU_result_w), 
    .instruction_r(instruction_in),
    .jalr_r(jalr),
    .PC_r(PC_in),                   
    .PCSel_r(PCSel_w), 
    .branch_r(branch_in),
    .memRead_r(memRead_in), 
    .memWrite_r(memWrite_in), 
    .regWrite_r(regWrite_in), 
    .resultSrc_r(resultSrc_in),
    .rs1_r(rs1_in), .rs2_r(rs2_in), .rd_r(rd_in), .rs2_val_r(rs2_val_forwarded),
    
    .ALU_result(ALU_result_out), .instruction(instruction_out), 
    .PC(PC_out), .PCSel(PCSel_out), .branch(branch_out), .memRead(memRead_out), .memWrite(memWrite_out), 
    .regWrite(regWrite_out), .resultSrc(resultSrc_out), .rs1(rs1_out), .rs2(rs2_out), 
    .rd(rd_out), .rs2_val(rs2_val_out), .jalr(jalr_out)
);



endmodule




module ALU( A,B, ALUControl, result, zero, negative);
input [31:0] A,B;
input [3:0] ALUControl;

output [31:0] result;
output zero, negative;

assign result = (ALUControl == 4'd0)? A + B : 
                (ALUControl == 4'd1)? $signed(A) - $signed(B) : 
                (ALUControl == 4'd2)? A & B : 
                (ALUControl == 4'd3)? A ^ B : 
                (ALUControl == 4'd4)? A | B : 
                (ALUControl == 4'd5)?  A >> B: 
                (ALUControl == 4'd6)? $signed($signed(A) >>> B) :
                (A < B); //ALUControl = 7

assign zero = (result == 32'b0);
assign negative = result[31];
                

endmodule



module EX_MEM(
input clk, rst,
input [31:0] ALU_result_r, instruction_r, PC_r, rs2_val_r,
input PCSel_r, memRead_r, memWrite_r, regWrite_r, branch_r, jalr_r,
input [1:0] resultSrc_r,
input [4:0] rs1_r, rs2_r, rd_r,
output reg [31:0] ALU_result, instruction, PC, rs2_val,
output reg PCSel, memRead, memWrite, regWrite, branch, jalr,
output reg [1:0] resultSrc,
output reg [4:0] rs1, rs2, rd
);


always @(posedge clk or posedge rst) begin
    if (rst) begin
        instruction <= 0; PC <= 0;
        memRead <= 0; memWrite <= 0;
        regWrite <= 0; resultSrc <= 0;
        rs2_val <= 0; rs1 <= 0; rs2 <= 0; rd <= 0;
        ALU_result <= 0;  PCSel <= 0;
        branch <=0;
        jalr <=0;
    end
    else begin
        instruction <= instruction_r; PC <= PC_r;
        memRead <= memRead_r; memWrite <= memWrite_r;
        regWrite <= regWrite_r; resultSrc <= resultSrc_r;
        rs2_val <= rs2_val_r; rs1 <= rs1_r; rs2 <= rs2_r; rd <= rd_r;
        ALU_result <= ALU_result_r; 
        PCSel <= PCSel_r;
        branch <= branch_r;
        jalr <= jalr_r;
    end
end

endmodule

