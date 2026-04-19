`timescale 1ns/1ps


module ID_tb;

    // Inputs to IF/ID & to decode stage
    reg clk;
    reg rst;
    reg regWrite_prev;
    reg [4:0] rd_in;
    reg [31:0] instruction_in;
    reg [31:0] PC_in;
    reg [31:0] WB_result;

    // Outputs from IF/ID to decode
      wire [31:0]instruction_r;
      wire [31:0] PC_r;

    // Outputs from decode
    wire [31:0] instruction, PC;
    wire ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite;
    wire [1:0] resultSrc;
    wire [3:0] ALUControl;
    wire [31:0] immediate, rs1_val, rs2_val;
    wire bgef3;
    wire [4:0] rs1, rs2, rd;

    IF_ID pipe_reg (
        .clk(clk), .rst(rst), .PC_r(PC_in), .instr_r(instruction_in), .PC(PC_r), .instr(instruction_r)
    );
    decode_stage uut (
        .clk(clk), .rst(rst), .regWrite_in(regWrite_prev), .rd_in(rd_in),
        .instruction_in(instruction_r), .PC_in(PC_r), .WB_result(WB_result),
        .instruction_out(instruction), .PC_out(PC), 
        .ALUSrc_out(ALUSrc), .memRead_out(memRead), .memWrite_out(memWrite), 
        .jalr_out(jalr), .jump_out(jump), .branch_out(branch), .regWrite_out(regWrite),
        .resultSrc_out(resultSrc), .ALUControl_out(ALUControl), 
        .immediate_out(immediate), .rs1_val_out(rs1_val), .rs2_val_out(rs2_val), 
        .bgef3_out(bgef3), .rs1_out(rs1), .rs2_out(rs2), .rd_out(rd)
    );

  
    always #5 clk = ~clk;

    initial 
    begin
        // Initialize everything
       
        clk = 0;
        rst = 1;
                
        instruction_in = 32'b0;
        PC_in = 32'h0000_0000;

        regWrite_prev = 0;
        WB_result = 32'b0;

        #20 rst = 0;

        // write the value 100 into register x1 (rs1)
        // This simulates a previous instruction finishing Write-Back
        @(posedge clk);
        rd_in = 5'b1;
        regWrite_prev = 1'b1;
        instruction_in = 32'b00000000111100001000001000010100 ; //ANDI
        WB_result = 32'd100;        
      
      

        //  TEST AN ANDI INSTRUCTION ---
        // andi  x4, x1, 15 
 
        repeat (2) @(posedge clk); 
        regWrite_prev = 0;


        
        $display("--- Testing ANDI ---");
        $display("Time: %t | Inst: %h | Imm: %d | rs1_val: %d |  RegWrite: %b", 
                 $time, instruction, immediate, rs1_val, regWrite);

        //  TEST A BNE INSTRUCTION ---
        // bne   x3, x5, l2    
        instruction_in = 32'b00000000010100011010010001100100; 
        repeat (2) @(posedge clk); 
    
        $display("--- Testing BNE ---");
        $display("Time: %t | Inst: %h | Branch: %b | Jump (jal or jalr): %b | rs2: %d", 
                 $time, instruction, branch, jump, rs2);

        #20;
        $finish;
    end

endmodule