`timescale 1ns/1ps
`default_nettype none

module cpu_tb;

    reg clk, rst;
    wire [31:0] PC;
    wire [31:0] instruction;
    wire [31:0] WB_result;

    integer cycle_count;
    integer nop_count;

    cpu uut (
        .clk(clk),
        .rst(rst),
        .PC_fetch_out(PC),
        .instr_fetch_out(instruction),
        .WB_result_out(WB_result)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        clk = 0;
        rst = 1;
        cycle_count = 0;
        nop_count = 0;

        #10 rst = 0;

        forever begin
            @(posedge clk);
            #1;
            cycle_count = cycle_count + 1;

            $display("Cycle=%0d | Time=%0t | PC=%h | Instr=%h | WB=%h | PCSel=%b | Target=%h",
                     cycle_count, $time, PC, instruction, WB_result, uut.PCSel_w, uut.next_pc_target_w);

            if (instruction == 32'h00001014) begin
                nop_count = nop_count + 1;
            end else begin
                nop_count = 0;
            end

            if (nop_count >= 4) begin
                $display("Program finished after %0d cycles", cycle_count);
                $finish;
            end
        end
    end

endmodule