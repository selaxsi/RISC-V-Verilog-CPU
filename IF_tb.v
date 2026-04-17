

module IF_tb;
 
 reg clk, rst, PCSel;
 wire [31:0] PC, ins;
 reg [0:31] jump_target;

  fetch_stage IF(clk, rst, PCSel, jump_target, PC, ins);

always #5 clk = ~clk;

 initial
 begin
  $monitor("time = %t, clk = %b, rst = %b, PCSel = %b, PC = %b, ins = %b",  $time, clk, rst, PCSel, PC, ins);
  clk = 1;
  rst = 1;
  #10;
  rst = 0;
  PCSel = 1;
  jump_target = 32'd20;
  #10;
  rst = 0;
  PCSel = 0;
  #30;
 $finish;

 end

endmodule 
// iverilog -o [outputfilename].out [filestocompile].v  //or *.v
// vvp [outputfilename].out
