`timescale 1ns/1ps
`default_nettype none

module hazard_tb;

    reg        memRead_ex;
    reg [4:0]  rd_ex, rs1_id, rs2_id;
    wire       stall;

    hazard uut(
        .memRead_ex(memRead_ex),
        .rd_ex(rd_ex),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .stall(stall)
    );

    initial begin
        $dumpfile("hazard_tb.vcd");
        $dumpvars(0, hazard_tb);

        //Test1: No hazard
        memRead_ex = 1; rd_ex = 5'd1;
        rs1_id = 5'd2; rs2_id = 5'd3;
        #5;
        $display("--- No hazard ---");
        $display("stall = %b (expected 0)", stall);

        //Test2: Load-use hazard on rs1
        memRead_ex = 1; rd_ex = 5'd1;
        rs1_id = 5'd1; rs2_id = 5'd3;
        #5;
        $display("--- Load-use hazard rs1 ---");
        $display("stall = %b (expected 1)", stall);

        //Test3: Load-use hazard on rs2
        memRead_ex = 1; rd_ex = 5'd1;
        rs1_id = 5'd3; rs2_id = 5'd1;
        #5;
        $display("--- Load-use hazard rs2 ---");
        $display("stall = %b (expected 1)", stall);

        //Test4: memRead=0, no hazard
        memRead_ex = 0; rd_ex = 5'd1;
        rs1_id = 5'd1; rs2_id = 5'd1;
        #5;
        $display("--- memRead=0 no hazard ---");
        $display("stall = %b (expected 0)", stall);

        //Test5: rd=x0, no hazard
        memRead_ex = 1; rd_ex = 5'd0;
        rs1_id = 5'd0; rs2_id = 5'd0;
        #5;
        $display("--- rd=x0 no hazard ---");
        $display("stall = %b (expected 0)", stall);

        $display("hazard tests done.");
        $finish;
    end

endmodule