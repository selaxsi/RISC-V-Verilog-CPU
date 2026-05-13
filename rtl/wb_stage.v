module wb_stage(
    input [31:0] ALU_result_in,
    input [31:0] mem_result_in,
    input [31:0] PC_plus_4_in,
    input [1:0]  resultSrc_in,
    input        regWrite_in,
    input [4:0]  rd_in,
    output [31:0] WB_result_out,
    output        regWrite_out,
    output [4:0]  rd_out
);

    wire [31:0] selected;
    assign selected = (resultSrc_in == 2'b00) ? ALU_result_in :
                      (resultSrc_in == 2'b01) ? mem_result_in :
                      (resultSrc_in == 2'b10) ? PC_plus_4_in : 32'b0;

    assign WB_result_out = selected;
    assign regWrite_out = regWrite_in;
    assign rd_out = rd_in;

    // always @(*) begin
    //  //   $display("WB_DEBUG: rd=%d, src=%d, ALU=%h, mem=%h, PC=%h, out=%h", 
    //              rd_in, resultSrc_in, ALU_result_in, mem_result_in, PC_plus_4_in, selected);
    // end

endmodule