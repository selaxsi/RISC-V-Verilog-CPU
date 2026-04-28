`timescale 1ns/1ps
`default_nettype none

module EX_tb;

    // 1. Inputs to the ID_EX Pipeline Register (must be reg)
    reg clk, rst,flush;
    reg [31:0] PC, instruction;
    reg ALUSrc, memRead, memWrite, jalr, jump, branch, regWrite;
    reg [1:0] resultSrc;
    reg [3:0] ALUControl;
    reg [31:0] immediate, rs1_val, rs2_val;
    reg bgef3;
    reg [4:0] rs1, rs2, rd;

    // 2. Outputs from ID_EX / Inputs to EX Stage (must be wire)
    wire [31:0] PC_r, instruction_r;
    wire ALUSrc_r, memRead_r, memWrite_r, jalr_r, jump_r, branch_r, regWrite_r;
    wire [1:0] resultSrc_r;
    wire [3:0] ALUControl_r;
    wire [31:0] immediate_r, rs1_val_r, rs2_val_r;
    wire bgef3_r;
    wire [4:0] rs1_r, rs2_r, rd_r;
    wire PCSel_early;
    wire [31:0] jump_target_early; //these two are outputs just from EX stage


    ID_EX pipe_reg (
        .clk(clk), .rst(rst), .flush(flush),
        .PC_r(PC), .instruction_r(instruction),
        .ALUSrc_r(ALUSrc), .memRead_r(memRead), .memWrite_r(memWrite),
        .jalr_r(jalr), .jump_r(jump), .branch_r(branch), .regWrite_r(regWrite),
        .resultSrc_r(resultSrc), .ALUControl_r(ALUControl), 
        .immediate_r(immediate), .rs1_val_r(rs1_val), .rs2_val_r(rs2_val),
        .bgef3_r(bgef3), .rs1_r(rs1), .rs2_r(rs2), .rd_r(rd),
        
        .PC(PC_r), .instruction(instruction_r), .ALUSrc(ALUSrc_r), .memRead(memRead_r), 
        .memWrite(memWrite_r), .jalr(jalr_r), .jump(jump_r), .branch(branch_r), .regWrite(regWrite_r),
        .resultSrc(resultSrc_r), .ALUControl(ALUControl_r), .immediate(immediate_r), 
        .rs1_val(rs1_val_r), .rs2_val(rs2_val_r), .bgef3(bgef3_r), .rs1(rs1_r), .rs2(rs2_r), .rd(rd_r)
    );

    // ex outputs
    wire [31:0] ALU_result, jump_target, instruction_ex, PC_ex, rs2_val_ex;
    wire PCSel, memRead_ex, memWrite_ex, regWrite_ex;
    wire [1:0] resultSrc_ex;
    wire [4:0] rs1_ex, rs2_ex, rd_ex;


execute_stage EX (
    .clk(clk), .rst(rst),
    .jalr(jalr_r),  .jump(jump_r),  .branch(branch_r), .bgef3(bgef3_r), 
    .ALUSrc(ALUSrc_r), .ALUControl(ALUControl_r), .immediate(immediate_r),  .rs1_val(rs1_val_r), .rs2_val_in(rs2_val_r),   
    .instruction_in(instruction_r), .PC_in(PC_r),              
    .memRead_in(memRead_r),  .memWrite_in(memWrite_r), 
    .regWrite_in(regWrite_r), .resultSrc_in(resultSrc_r), .rs1_in(rs1_r),  .rs2_in(rs2_r),  .rd_in(rd_r),
    .ALU_result_out(ALU_result),  .jump_target_out(jump_target),  .instruction_out(instruction_ex), 
    .PC_out(PC_ex), .rs2_val_out(rs2_val_ex), .PCSel_out(PCSel), 
    .memRead_out(memRead_ex),   .memWrite_out(memWrite_ex),  .regWrite_out(regWrite_ex),  .resultSrc_out(resultSrc_ex), 
    .rs1_out(rs1_ex),  .rs2_out(rs2_ex),  .rd_out(rd_ex),
    .PCSel_early_out(PCSel_early), .jump_target_early_out(jump_target_early)
);

 
    always #5 clk = ~clk;

    initial begin
            $dumpfile("EX_tb.vcd");
    $dumpvars(0, EX_tb);
        // Initialize everything
        clk = 0; rst = 1; flush = 0;
        PC = 0; instruction = 0;
        ALUSrc = 0; ALUControl = 0;
        rs1_val = 0; rs2_val = 0;
        immediate = 0;
        memRead = 0; memWrite = 0; 
        jalr = 0; jump = 0; branch = 0;
        resultSrc = 0; bgef3 = 0;
        rs1 = 0; rs2 = 0; rd = 0;
        
        #10 rst = 0;

        // Test ADD: Load values into ID/EX
        @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2_val
        ALUControl = 4'b0000; // add
        rs1_val = 32'd10;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing Add ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b", rs1_val_r, rs2_val_r, ALUSrc_r, ALUControl_r);
        $display("out: ALU_Result: %d", ALU_result);



                // Test BGE (condition is met): Load values into ID/EX
        @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2_val
        ALUControl = 4'b0001; // sub
        PC = 32'd4;
        immediate = 32'd12;
        rs1_val = 32'd30;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        bgef3 = 1;
        branch = 1;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing BGE (condition is met) ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b PC = %d, immediate = %d", rs1_val_r, rs2_val_r, ALUSrc_r, ALUControl_r, PC_r, immediate_r);
        $display("out: ALU_Result %d, PCSel: %d", ALU_result, PCSel);



                        // Test BGE (condition is NOT met): Load values into ID/EX
        @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2_val
        ALUControl = 4'b0001; // sub
        rs1_val = 32'd10;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        bgef3 = 1;
        branch = 1;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing BGE (condition not met) ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b", rs1_val_r, rs2_val_r, ALUSrc_r, ALUControl_r);
        $display("out: ALU_Result %d, PCSel: %d", $signed(ALU_result), PCSel);



                               // Test BNE (condition is met): Load values into ID/EX
        @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2_val
        ALUControl = 4'b0001; // sub
               PC = 32'd4;
        immediate = 32'd12;
        rs1_val = 32'd30;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        bgef3 = 0;
        branch = 1;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing BNE (condition not met) ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b, PC = %d, immediate = %d", rs1_val_r, rs2_val_r, ALUSrc_r, ALUControl_r, PC_r, immediate_r);
        $display("out: ALU_Result %d, PCSel: %d, jump_target", $signed(ALU_result), PCSel, jump_target);


    //TEST BNE
                @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2_val
        ALUControl = 4'b0001; // sub
        rs1_val = 32'd30;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        bgef3 = 0;
        branch = 1;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing BNE (condition not met) ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b", rs1_val_r, rs2_val_r, ALUSrc_r, ALUControl_r);
        $display("out: ALU_Result %d, PCSel: %d", $signed(ALU_result), PCSel);

    //TEST I type
                @(negedge clk);
        ALUSrc = 1'b1;      // Select immediate
        ALUControl = 4'b0100; // OR
        immediate = 32'd12;
        rs1_val = 32'd0;
        rs2_val = 32'b10;
        instruction = 32'h00000000;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing ori ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, ALUSrc: %b, Control: %b, immediate = %d", rs1_val_r, ALUSrc_r, ALUControl_r, immediate_r);
        $display("out: ALU_Result %d", $signed(ALU_result));

            //TEST jalr
                @(negedge clk);
        ALUSrc = 1'b1;      // Select immediate
        ALUControl = 4'b0000; // Add
        immediate = 32'd12;
        rs1_val = 32'd10;
        rs2_val = 32'd20;
        instruction = 32'h00000000;
        jump = 1;
        jalr = 1;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing jalr ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, ALUSrc: %b, Control: %b, PC = %d, immediate = %d", rs1_val_r, ALUSrc_r, ALUControl_r, PC_r, immediate_r);
        $display("out: ALU_Result %d, PCSel: %d, jump_target", $signed(ALU_result), PCSel, jump_target);

                //TEST sra
                @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2
        ALUControl = 4'b0110; //shift right arithmetic (signed)
        rs1_val = 32'hFFFFFFF6; // This is -10 in two's complement  (either this or rs1_val = -10 works but avoid -32'd10)
        rs2_val = 32'd1; //should div by 2
        instruction = 32'h00000000;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing sra ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b", $signed(rs1_val_r), rs2_val_r, ALUSrc_r, ALUControl_r);
        $display("out: ALU_Result %d", $signed(ALU_result));



                        //TEST sltu
                @(negedge clk);
        ALUSrc = 1'b0;      // Select rs2
        ALUControl = 4'b0111;
        rs1_val = 32'hFFFFFFF6; // This is -10 in two's complement  (unsigned --> much larger than rs2_val)
        rs2_val = 32'd100; 
        instruction = 32'h00000000;
        // 2 CC for first pipeline and 2nd pipeline register
        repeat (2) @(posedge clk);
        
        #1; 
        $display("--- Testing sra ---");
        $display("Time: %t", $time);
        $display("in: rs1 val: %d, rs2 val: %d, ALUSrc: %b, Control: %b", $signed(rs1_val_r), rs2_val_r, ALUSrc_r, ALUControl_r);
        $display("out: ALU_Result %d", $signed(ALU_result));



        #10 $finish;
    end

endmodule