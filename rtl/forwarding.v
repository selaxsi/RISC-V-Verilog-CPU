`default_nettype none

module forwarding(
    input [4:0] rs1_ex,
    input [4:0] rs2_ex,
    input [4:0] rs1_id,
    input [4:0] rs2_id,
    input [4:0] rd_mem,
    input [4:0] rd_wb,
    input       regWrite_mem,
    input       regWrite_wb,

    output reg [1:0] forwardA,
    output reg [1:0] forwardB,
    output reg forwardIDA,
    output reg forwardIDB
);



always @(*) begin

    if (regWrite_mem && rd_mem != 5'b0 && rd_mem == rs1_ex)
        forwardA = 2'b10;
    else if (regWrite_wb && rd_wb != 5'b0 && rd_wb == rs1_ex)
        forwardA = 2'b01;
    else
        forwardA = 2'b00;

    if (regWrite_mem && rd_mem != 5'b0 && rd_mem == rs2_ex)
        forwardB = 2'b10;
    else if (regWrite_wb && rd_wb != 5'b0 && rd_wb == rs2_ex)
        forwardB = 2'b01;
    else 
        forwardB = 2'b00;

    if (regWrite_wb && rd_wb != 0 && rd_wb == rs1_id)
    forwardIDA = 1'b1; 
    else
    forwardIDA = 1'b0;

        if (regWrite_wb && rd_wb != 0 && rd_wb == rs2_id)
    forwardIDB = 1'b1; 
    else
    forwardIDB = 1'b0;

end

endmodule