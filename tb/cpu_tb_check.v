`timescale 1ns/1ps
`default_nettype none

module cpu_tb_check;

    reg clk, rst;
    wire [31:0] PC;
    wire [31:0] instruction;
    wire [31:0] WB_result;
    integer fail_count;
        integer cycle_count;
        integer  nop_count;
        integer expected_cycles;
    reg [64*8:1] current_test;
    reg [64*8:1] expected_file;
    reg [64*8:1] expected_mem;


    cpu uut (
        .clk(clk),
        .rst(rst),
        .PC_fetch_out(PC),
        .instr_fetch_out(instruction),
        .WB_result_out(WB_result)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_tb_check.vcd");
        $dumpvars(0, cpu_tb_check);
        fail_count = 0;



        // Arithmetic test 
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 14;
        current_test = "test/bin/arithmetic.txt";
        expected_file = "test/expected/arithmetic.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);

                   // branch test 
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
         expected_cycles = 27;

        current_test = "test/bin/branches.txt";
        expected_file = "test/expected/branches.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);


                           // double data test 
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 8;
        current_test = "test/bin/double_data.txt";
        expected_file = "test/expected/double_data.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);


                           // forwarding test 
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 9;
        current_test = "test/bin/forwarding.txt";
        expected_file = "test/expected/forwarding.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);


                            // jumps test 
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 14;
        current_test = "test/bin/jumps.txt";
        expected_file = "test/expected/jumps.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);



                            // loaduse test 
        clk = 0;
        rst = 1;
        expected_cycles = 11;
        cycle_count = 0; nop_count = 0;
        current_test = "test/bin/loaduse.txt";
        expected_file = "test/expected/loaduse.txt";
        expected_mem = "test/expected/loaduse_mem.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);

      
      if (fail_count == 0) $display("SUCCESSLY PASSED ALL TESTS");
      else $display("FAILED %d TESTS", fail_count);


                            // logical test 
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 11;
        current_test = "test/bin/logical.txt";
        expected_file = "test/expected/logical.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);


                           //loop test
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 35;
        current_test = "test/bin/loop.txt";
        expected_file = "test/expected/loop.txt";
        expected_mem = "test/expected/mem_empty.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);



                        //loop test
        clk = 0;
        rst = 1;
        cycle_count = 0; nop_count = 0;
        expected_cycles = 14;
        current_test = "test/bin/memory.txt";
        expected_file = "test/expected/memory.txt";
        expected_mem = "test/expected/memory_mem.txt";

        cpu_tb_check.uut.IF_STAGE.IM.load_program(current_test);

        #10 rst = 0;

        run_check_test(current_test, expected_file, expected_mem);




        // --- finish tests

      
      if (fail_count == 0) $display("SUCCESSLY PASSED ALL TESTS");
      else $display("FAILED %d TESTS", fail_count);

      $finish;

    end


    task run_check_test(input reg[64*8:1] curr_test, input reg[64*8:1] expected_file, input reg[64*8:1] expected_file_mem);

        reg [31:0] expected_RF [0:31];
        reg [31:0] expected_MEM [0:49];

        integer curr_error_count;
        integer i;

            forever begin
               
                 curr_error_count = 0;
  
                @(posedge clk);
                #1;
                cycle_count = cycle_count + 1;

                if (instruction == 32'h00001014)
                    nop_count = nop_count + 1;
                else 
                    nop_count = 0;
                
                
                if (nop_count >= 4 ) begin

                
                    $readmemh(expected_file, expected_RF);
                    $readmemh(expected_file_mem, expected_MEM);

                    for (i = 0; i<32; i = i+1) begin

                    if (cpu_tb_check.uut.ID_STAGE.RF.register[i] != expected_RF[i]) begin
                        $display("Register File Error at register %d, got: %d, expected: %d", i, cpu_tb_check.uut.ID_STAGE.RF.register[i], expected_RF[i]);
                        curr_error_count = curr_error_count + 1;
                    end
                    end


                    for (i = 0; i<100; i = i+1) begin

                    if (cpu_tb_check.uut.MEM_STAGE.DMEM.memory[i] != expected_MEM[i]) begin
                        $display("Mem error at addr %d, got: %d, expected: %d", i, cpu_tb_check.uut.MEM_STAGE.DMEM.memory[i], expected_MEM[i]);
                        curr_error_count = curr_error_count + 1;
                    end
                    end
                    

                    if (curr_error_count == 0) 
                        $display("\n PASS TEST %s, cycle count = %d, expected cycle count = %d ", curr_test, cycle_count, expected_cycles);
                    else begin
                        $display("\n FAIL TEST %s, error count = %d, cycle count = %d, expected cycle count = %d ", curr_test, curr_error_count, cycle_count, expected_cycles);
                        fail_count = fail_count +1; end
                    

                        disable  run_check_test;
             
            end
            end
    endtask


endmodule