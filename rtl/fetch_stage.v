`default_nettype none

//Naming convention:
//_in : input either from previous or later stage
//_out : outputs from the current stage's pipeline register 
// _w : wires , variables created in stage
// no suffix : anything that 'dies' in this stage (will not be input to any stage or pipeline register) (could be a wire or input type)
// _r : input parameters of the pipeline registers, connect _w or _in to them

module fetch_stage(clk, rst, stall, PCSel, jump_target, PC_out, instruction_out, rs1_out, rs2_out);
    input clk, rst, stall, PCSel; //PCSel generated at EX stage = (branch && condition || jump )
    input [31:0] jump_target;
    wire [31:0] PC_w, instruction_w;
    output [4:0] rs1_out, rs2_out;
    output [31:0] PC_out, instruction_out;

    wire [31:0] PC_plus_4;
    wire [31:0] next_PC_val;

   adder adder_4(.a(PC_w), .b(32'd4), .f(PC_plus_4));

    mux_2x1 mux(.a(PC_plus_4), .b(jump_target), .s(PCSel), .f(next_PC_val));
  
    program_counter PC_Reg (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .PC_mux_output(next_PC_val),
        .PC(PC_w)
    );

    instruction_memory IM (
        .PC(PC_w),
        .instruction(instruction_w)
    );

    IF_ID IFID(.clk(clk), .rst(rst), .stall(stall), .PC_r(PC_w)
        , .instr_r(instruction_w), .instr(instruction_out), .PC(PC_out),
        .rs1_out(rs1_out), .rs2_out(rs2_out));

endmodule

module instruction_memory(PC, instruction); 

input [31:0] PC;
output [31:0] instruction;

reg [31:0] temp_mem [0:16383]; // 16k words = 64k bytes
reg [7:0] memory [0:65535]; //64k x 1byte, enough for 16k instructions


integer i;

initial
 begin
  // fill everything with NOP first so uninitialized slots don't go X
  for ( i = 0; i<16384; i = i+1)
    temp_mem[i] = 32'h00001014; // NOP = addiw x0, x0, 0

  $readmemb("program.txt", temp_mem);

  for ( i = 0; i<16384; i = i+1) begin
    memory[i*4]   = temp_mem[i][7:0];
    memory[i*4+1] = temp_mem[i][15:8];
    memory[i*4+2] = temp_mem[i][23:16];
    memory[i*4+3] = temp_mem[i][31:24];
  end
 end

 assign instruction =  {memory[PC+3], memory[PC+2], memory[PC+1], memory[PC]}; 


endmodule


    module program_counter( clk, PC_mux_output, rst, stall, PC);  
    input clk, rst, stall;
    input [31:0]PC_mux_output;
    output reg [31:0]PC;
    always @(posedge clk)
    begin
        if (rst == 1'b1) PC <= 32'b0;
        else if (!stall)  PC <= PC_mux_output;
    end
    endmodule

    module IF_ID(clk, rst, stall, PC_r, instr_r, PC, instr, rs1_out, rs2_out);
    input wire clk, rst, stall;
    input wire [31:0] PC_r , instr_r;
    output reg [31:0] instr, PC;
    output wire [4:0] rs1_out, rs2_out;
    assign rs1_out = instr_r[19:15];
    assign rs2_out = instr_r[24:20];
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                PC <= 32'b0; 
                instr <= 32'b0; 
            end
            else if (!stall) begin
                PC <= PC_r;
                instr <= instr_r;
            end
        end
    endmodule



