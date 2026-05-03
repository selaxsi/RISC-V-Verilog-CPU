module IF_tb;
 
 reg clk, rst, PCSel, stall;
 wire [31:0] PC, ins;
 reg [0:31] jump_target;

wire [4:0] rs1_if, rs2_if;
fetch_stage IF(.clk(clk), .rst(rst), .stall(stall), .PCSel(PCSel), .jump_target(jump_target), .PC_out(PC), .instruction_out(ins), .rs1_out(rs1_if), .rs2_out(rs2_if));

always #5 clk = ~clk;

 initial
 begin  
    $dumpfile("IF_tb.vcd");
    $dumpvars(0, IF_tb);

  
  clk = 1;
  rst = 1;
  stall = 0;
  #10;
  $monitor("time = %t, clk = %b, rst = %b, PCSel = %b, jump_target = %h, PC = %h, ins = %h",  $time, clk, rst, PCSel, jump_target, PC, ins);
  rst = 0;
  PCSel = 0;
  jump_target = 32'd20;
  #30;
  rst = 0;
  PCSel = 1;
  #10;
 $finish;

 end

endmodule 
// iverilog -o [outputfilename].out [filestocompile].v  //or *.v
// vvp [outputfilename].out
