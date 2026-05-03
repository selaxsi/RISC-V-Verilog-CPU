`default_nettype none

module hazard(
    input        memRead_ex,
    input [4:0]  rd_ex,
    input [4:0]  rs1_id,
    input [4:0]  rs2_id,
    output reg stall
);

always @(*) begin
    if (memRead_ex && rd_ex != 5'b0 &&
       (rd_ex == rs1_id || rd_ex == rs2_id))
        stall = 1;
    else
        stall = 0;
end

endmodule