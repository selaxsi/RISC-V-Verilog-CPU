`default_nettype none



module fetch_stage(clk, rst, PCSel, jump_target, PC_r, instruction_r);
    input clk, rst, PCSel; //PCSel generated at EX stage = (branch && condition || jump )
    input [31:0] jump_target;
    wire [31:0] PC_out, instruction_out;
    output [31:0] PC_r, instruction_r;

    wire [31:0] pc_plus_4;
    wire [31:0] next_pc_val;

   adder adder_4(.a(PC_out), .b(32'd4), .f(pc_plus_4));

    mux_2x1 mux(.a(pc_plus_4), .b(jump_target), .s(PCSel), .f(next_pc_val));
  
    program_counter PC_Reg (
        .clk(clk),
        .rst(rst),
        .PC_mux_output(next_pc_val),
        .PC(PC_out)
    );

    instruction_memory IM (
        .PC(PC_out),
        .instruction(instruction_out)
    );

    IF_ID IFID(.clk(clk), .rst(rst), .pc_in(PC_out)
    , .instr_in(instruction_out), .instr(instruction_r), .pc(PC_r) );

endmodule

module instruction_memory(PC, instruction); 

input [31:0] PC;
output [31:0] instruction;

reg [31:0] temp_mem [0:16383]; // 16k words = 64k bytes
reg [7:0] memory [0:65535]; //64k x 1byte, enough for 16k instructions


integer i;
 initial
 begin
  $readmemb("program.txt", temp_mem); //need to divide each word into 4 bytes...

  for ( i = 0; i<16383;i = i+1) begin
    memory[i*4]   = temp_mem[i][7:0];   // Byte 0   little endian lsb at least address
    memory[i*4+1] = temp_mem[i][15:8];  // Byte 1
    memory[i*4+2] = temp_mem[i][23:16]; // Byte 2
    memory[i*4+3] = temp_mem[i][31:24]; // Byte 3
  end
 end

 assign instruction =  {memory[PC+3], memory[PC+2], memory[PC+1], memory[PC]}; 


endmodule


module program_counter( clk, PC_mux_output, rst, PC);  

input clk, rst;
input [31:0]PC_mux_output;
output reg [31:0]PC;

always @(posedge clk)
begin
    if (rst == 1'b1) PC <= 32'b0;
    else PC <= PC_mux_output;
end

endmodule


module IF_ID(clk, rst, pc_in, instr_in, pc, instr);

input wire clk, rst;
input wire [31:0] pc_in , instr_in;

output reg [31:0] instr, pc;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
           
            pc <= 32'b0; 
            instr <= 32'b0; 
        end

        else begin
            pc <= pc_in;
            instr <= instr_in;
        end
    end


endmodule



