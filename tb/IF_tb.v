module IF_tb;
 
 reg clk, rst, PCSel, stall, IFID_flush;
 wire [31:0] PC, ins;
 reg [0:31] jump_target;


fetch_stage IF(.clk(clk), .rst(rst), .stall(stall), 
.PCSel(PCSel), .jump_target(jump_target), .PC_out(PC), 
.instruction_out(ins));

     wire [31:0] instr_ifid, PC_ifid;

    IF_ID IFID(.clk(clk), .rst(rst), .stall(stall), .PC_r(PC)  , .flush(IFID_flush)
        , .instr_r(ins), .instr(instr_ifid), .PC(PC_ifid));


always #5 clk = ~clk;

 initial
 begin  
    $dumpfile("IF_tb.vcd");
    $dumpvars(0, IF_tb);

  
  clk = 1;
  rst = 1;
  stall = 0;
  IFID_flush = 0;
  #10;
  $monitor("time = %t, clk = %b, rst = %b, PCSel = %b, jump_target = %h, PC = %h, ins = %h",  $time, clk, rst, PCSel, jump_target, PC_ifid, instr_ifid);
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
