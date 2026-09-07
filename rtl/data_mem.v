`default_nettype none

module data_memory(
    input clk, rst,
    input memRead, memWrite,
    input [31:0] ALU_result, rs2_val,
    output reg [31:0] mem_result
);

    reg [31:0] memory [0:1023];

    integer i;
    always @(posedge rst) begin
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h0;
    end

    always @(posedge clk) begin
        if (memWrite)
            memory[ALU_result >> 2] <= rs2_val;
    end

    always @(*) begin
        if (memRead)
            mem_result = memory[ALU_result >> 2];
        else
            mem_result = 32'h0;
    end

endmodule
