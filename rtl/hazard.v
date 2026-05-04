`default_nettype none

module hazard(
    input clk, rst,
    input [31:0] PC_id, imm_id,
    input branch_id, jump_id, jalr_id,


    input        memRead_ex, branch_ex, jalr_ex, br_result_ex, br_predict_ex, 
    input [31:0] PC_ex, ALU_result_ex, imm_ex,
    input [4:0]  rd_ex,
    input [4:0]  rs1_id,
    input [4:0]  rs2_id,


    output reg IFID_stall, IFID_flush, IDEX_flush,
    output reg [31:0] next_pc_target,
    output reg PCSel,
    output br_predict //to EX stage , which will be sent back here as br_predict_ex

);

wire [31:0] target_id, target_ex;
wire jump_in_id;
wire misprediction;

branch_history_table BHT(.clk(clk), .rst(rst), .tag_id(PC_id[7:2]), .tag_ex(PC_ex[7:2]), .update(branch_ex), .result_ex(br_result_ex), .taken(br_predict));
assign jump_in_id = (branch_id && br_predict || jump_id && !jalr_id);
assign misprediction = (branch_ex && br_result_ex != br_predict_ex);
adder id(.a(PC_id), .b(imm_id), .f(target_id)); //for taken prediction (or jal)
adder ex(.a(PC_ex), .b(imm_ex), .f(target_ex));// for misprediction NT (should be T)


always @(*) begin
    //defaults
        PCSel = 0;
        IFID_stall = 0;
        IFID_flush = 0;
        IDEX_flush = 0;
  
    if (misprediction || jalr_ex) begin   // *** stall = 0 (stall will stop PC update)
        IFID_flush = 1;
        IDEX_flush = 1;
        PCSel = 1;
        if (jalr_ex) next_pc_target = ALU_result_ex;
        else if (br_result_ex) next_pc_target = target_ex; //correct to T
        else next_pc_target = PC_ex + 32'd4; //correct to NT
    end

   else if (jump_in_id) begin
    IFID_flush = 1;
    next_pc_target = target_id;
    PCSel = 1;
    end
        

   else if (memRead_ex && rd_ex != 5'b0 &&
       (rd_ex == rs1_id || rd_ex == rs2_id)) begin
        IFID_stall = 1;
        PCSel = 0;
       end


    
end

endmodule


module branch_history_table( 
input clk, rst,
input [5:0] tag_id, tag_ex, //6 bits 64 entries
input result_ex, update, //update = 1 if were in EX stage and we have resolved branch prediction....
output taken
);

reg [1:0] BHT [0:63];

integer i;
initial begin
    for ( i = 0; i<64; i = i+1) begin
        BHT[i] = 2'b0;
    end
end

always @(posedge clk) begin
    if (update) begin
        if (result_ex) 
        BHT[tag_ex] = (BHT[tag_ex] != 2'b11)? BHT[tag_ex] + 1 : 2'b11;
        else
        BHT[tag_ex] = (BHT[tag_ex] != 2'b00)? BHT[tag_ex] - 1 : 2'b00;
    end
end

assign taken = BHT[tag_id][1]; //msb of BHT, 11 or 10 = taken

endmodule