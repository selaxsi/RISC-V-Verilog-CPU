`timescale 1ns/1ps
`default_nettype none

module cpu_tb;

    reg clk, rst;
    wire [31:0] PC;
    wire [31:0] instruction;
    wire [31:0] WB_result;
    integer i;
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
            cycle_count = cycle_count + 1;

            $display("Cycle=%0d | Time=%0t | PC=%h | Instr=%h | WB=%h | PCSel=%b | Target=%h",
                     cycle_count, $time, PC, instruction, WB_result, uut.PCSel_w, uut.next_pc_target_w);

            if (instruction == 32'h00001014) begin
                nop_count = nop_count + 1;
            end else begin
                nop_count = 0;
            end

            if (nop_count >= 4) begin
                $display("Program finished after %0d cycles\n", cycle_count);
            
                    $display("\n--- FINAL REGISTER FILE CONTENTS ---");

            for (i = 0; i < 32; i = i + 1) begin
                $display("x%0d: %d", i, cpu_tb.uut.ID_STAGE.RF.register[i]);
            end

            $writememh("test/final_register_file.txt", cpu_tb.uut.ID_STAGE.RF.register);
            $writememh("test/final_memory.txt", cpu_tb.uut.MEM_STAGE.DMEM.memory);
            $display("Register file contents written to test/final_register_file.txt");
            $display("Memory contents written to test/final_memory.txt");



                $finish;
            end
        end

    end

endmodule