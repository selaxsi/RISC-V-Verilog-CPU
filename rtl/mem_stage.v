`default_nettype none

module MEM_WB(
    input clk, rst,
    input [31:0] ALU_result_r, mem_result_r, PC_plus_4_r,
    input [1:0] resultSrc_r,
    input memRead_r, regWrite_r,
    input [4:0] rd_r,
    output reg [31:0] ALU_result, mem_result, PC_plus_4,
    output reg [1:0] resultSrc,
    output reg memRead, regWrite,
    output reg [4:0] rd
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ALU_result <= 32'b0;
            mem_result <= 32'b0;
            PC_plus_4  <= 32'b0;
            resultSrc  <= 2'b0;
            memRead    <= 1'b0;
            regWrite   <= 1'b0;
            rd         <= 5'b0;
        end else begin
            ALU_result <= ALU_result_r;
            mem_result <= mem_result_r;
            PC_plus_4  <= PC_plus_4_r;
            resultSrc  <= resultSrc_r;
            memRead    <= memRead_r;
            regWrite   <= regWrite_r;
            rd         <= rd_r;
        end
    end
endmodule


module mem_stage(
    input clk,
    input rst,

    input memRead_in,
    input memWrite_in,
    input regWrite_in,
    input [1:0] resultSrc_in,
    input [4:0] rd_in,

    input [31:0] ALU_result_in,
    input [31:0] rs2_val_in,
    input [31:0] PC_in,

    output [31:0] ALU_result_out,
    output [31:0] mem_result_out,
    output [31:0] PC_plus_4_out,
    output [1:0]  resultSrc_out,
    output        regWrite_out,
    output [4:0]  rd_out,
    output        memRead_out
);

    wire [31:0] mem_result_w;
    wire [31:0] PC_plus_4_w;

    assign PC_plus_4_w = PC_in + 32'd4;

    data_memory DMEM (
        .clk(clk), .rst(rst),
        .memRead(memRead_in),
        .memWrite(memWrite_in),
        .ALU_result(ALU_result_in),
        .rs2_val(rs2_val_in),
        .mem_result(mem_result_w)
    );

    MEM_WB pipe_reg (
        .clk(clk), .rst(rst),
        .ALU_result_r(ALU_result_in),
        .mem_result_r(mem_result_w),
        .PC_plus_4_r(PC_plus_4_w),
        .resultSrc_r(resultSrc_in),
        .memRead_r(memRead_in),
        .regWrite_r(regWrite_in),
        .rd_r(rd_in),
        .ALU_result(ALU_result_out),
        .mem_result(mem_result_out),
        .PC_plus_4(PC_plus_4_out),
        .resultSrc(resultSrc_out),
        .memRead(memRead_out),
        .regWrite(regWrite_out),
        .rd(rd_out)
    );

endmodule