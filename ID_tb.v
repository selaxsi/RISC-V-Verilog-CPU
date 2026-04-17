`timescale 1ns/1ps


module ID_tb;

    // Inputs
    reg clk;
    reg rst;
    reg regWrite_prev;
    reg [4:0] rd_in;
    reg [31:0] instruction;
    reg [31:0] PC;
    reg [31:0] PC_plus_4;
    reg [31:0] WB_result;

    // Outputs
    wire [31:0] instruction_r, PC_r;
    wire ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r;
    wire [1:0] resultSrc_r;
    wire [3:0] ALUControl_r;
    wire [31:0] immediate_r, rs1_val_r, rs2_val_r;
    wire bgef3_r;
    wire [4:0] rs1_r, rs2_r, rd_r;

   
    decode_stage uut (
        .clk(clk), .rst(rst), .regWrite_in(regWrite_prev), .rd_in(rd_in),
        .instruction(instruction), .PC(PC), .WB_result(WB_result),
        .instruction_r(instruction_r), .PC_r(PC_r), 
        .ALUSrc_r(ALUSrc_r), .memRead_r(memRead_r), .memWrite_r(memWrite_r), 
        .jalr_r(jalr_r), .jump_r(jump_r), .branch_r(branch_r), .regWrite_r(regWrite_r),
        .resultSrc_r(resultSrc_r), .ALUControl_r(ALUControl_r), 
        .immediate_r(immediate_r), .rs1_val_r(rs1_val_r), .rs2_val_r(rs2_val_r), 
        .bgef3_r(bgef3_r), .rs1_r(rs1_r), .rs2_r(rs2_r), .rd_r(rd_r)
    );

  
    always #5 clk = ~clk;

    initial 
    begin
        // Initialize
       
        clk = 0;
        rst = 1;
        regWrite_prev = 0;
        
        instruction = 32'b0;
        PC = 32'h0000_0000;
        WB_result = 32'b0;

        #10 rst = 0;

        // write the value 100 into register x1 (rs1)
        // This simulates a previous instruction finishing Write-Back
        @(posedge clk);
        rd_in = 5'b1;
        regWrite_prev = 1'b1;
        instruction = 32'b00000000111100001000001000010100 ; //ANDI
        WB_result = 32'd100;        
      
      

        //  TEST AN ANDI INSTRUCTION ---
        // andi  x4, x1, 15 
 
    @(negedge clk);
        regWrite_prev = 0;

        
        $display("--- Testing ANDI ---");
        $display("Time: %t | Inst: %h | Imm: %d | rs1_val: %d |  RegWrite: %b", 
                 $time, instruction_r, immediate_r, rs1_val_r, regWrite_r);
#10;

        
        $display("--- Testing ANDI ---");
        $display("Time: %t | Inst: %h | Imm: %d | rs1_val: %d |  RegWrite: %b", 
                 $time, instruction_r, immediate_r, rs1_val_r, regWrite_r);

        //  TEST A BNE INSTRUCTION ---
        // bne   x3, x5, l2    
        instruction = 32'b00000000010100011010010001100100; 

        #10;
        $display("--- Testing BNE ---");
        $display("Inst: %h | Branch: %b | Jump: %b | rs2_r: %d", 
                  instruction_r, branch_r, jump_r, rs2_r);

        #20;
        $finish;
    end

endmodule