`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.10.2025 11:41:05
// Design Name: 
// Module Name: ID
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module immediate_extend(
    input [31:0] instruction,
    input [1:0] imm_src,
    output reg [31:0] immediate_extended
  );
    always @(*) begin
        case(imm_src)
            // I-type immediate
            2'b00: immediate_extended = {{20{instruction[31]}}, instruction[31:20]};
            // S-type immediate
            2'b01: immediate_extended = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            // B-type immediate
            2'b10: immediate_extended = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            // U-type and J-type immediate
            2'b11: begin
                if (instruction[6:0] == 7'b1101111) begin // JAL
                    immediate_extended = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                end else begin // LUI, AUIPC
                    immediate_extended = {instruction[31:12], 12'b0};
                end
            end
            default: immediate_extended = 32'bx;
        endcase
    end
endmodule

module reg_file (
    input clk,
    input rst,
    input we3,
    input [4:0] a1, a2, a3,
    input [31:0] wd3,
    output [31:0] rd1, rd2
  );

    reg [31:0] register [31:0];
  integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i+1) begin
                register[i] <= 32'b0;
            end
        end else if (we3 && (a3 != 5'b0)) begin
            register[a3] <= wd3;
        end
    end
    
    assign rd1 = (a1 == 5'b0) ? 32'b0 : register[a1];
    assign rd2 = (a2 == 5'b0) ? 32'b0 : register[a2];
endmodule

module control_unit(op,func3,func7,regwrite,resultsrc,memwrite,jump,branch,aluctrl,alusrc,immsrc);
 input[6:0] op,func7;
 input[2:0] func3;
 output regwrite,alusrc,memwrite,resultsrc,branch,jump;
 output [1:0] immsrc;
 output[3:0] aluctrl;
 wire[1:0]aluop;

 main_decoder main1(.op(op),
 .resultsrc(resultsrc),
 .memwrite(memwrite),
 .branch(branch),
 .alusrc(alusrc),
 .regwrite(regwrite),
 .jump(jump),
 .aluop(aluop),
 .immsrc(immsrc));

 alu_decoder alu1(.aluop(aluop),
 .func3(func3),
 .func7(func7),
 .op(op),
 .aluctrl(aluctrl));
endmodule

module alu_decoder (aluop,func3,func7,op,aluctrl);
 input[6:0]op,func7;
 input[2:0]func3;
 input[1:0] aluop;
 output reg [3:0] aluctrl;
 wire r_sub;
 assign r_sub = op[5]&&func7[5];

 always@(*) begin
    case(aluop)
    2'b00 : aluctrl = 4'b000;
    2'b01 : begin
        case(func3)
        3'b110 : aluctrl = 4'b0111;
        3'b111 : aluctrl = 4'b0111;
        default : aluctrl = 4'b0001;
        endcase
    end
    2'b11 : aluctrl = 4'b0000;
    default : begin
        case(func3)
        3'b000 : aluctrl = r_sub?4'b0001:4'b0000;//sub or add
        3'b001 : aluctrl = 4'b0101;//sll
        3'b010: aluctrl = 4'b0110;//slt
        3'b011: aluctrl = 4'b0111;//sltu
        3'b100: aluctrl = 4'b0100;//xor
        3'b101: aluctrl = func7[5]? 4'b1000:4'b1001;//sra
        3'b110: aluctrl = 4'b0011;//or
        3'b111: aluctrl = 4'b0010;//and
        default: aluctrl = 4'bxxxx;
        endcase
    end
    endcase
 end    
endmodule

module main_decoder(op,resultsrc,memwrite,branch,alusrc,regwrite,jump,aluop,immsrc);
 input[6:0] op;
 output reg[1:0] resultsrc,immsrc,aluop;
 output reg memwrite,branch,alusrc,regwrite,jump;
  always @(*) begin
        case(op)
            // R-type instructions
            7'b0110011: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_00_0_0_00_0_10_0;

            // I-type ALU instructions
            7'b0010011: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_00_1_0_00_0_10_0;

            // Load instructions
            7'b0000011: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_00_1_0_01_0_00_0;

            // Store instructions
            7'b0100011: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b0_01_1_1_00_0_00_0;

            // Branch instructions
            7'b1100011: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b0_10_0_0_00_1_01_0;

            // LUI
            7'b0110111: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_11_1_0_00_0_11_0;

            // AUIPC
            7'b0010111: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_11_1_0_00_0_11_0;

            // JAL
            7'b1101111: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_11_0_0_10_0_00_1;

            // JALR
            7'b1100111: {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b1_00_1_0_10_0_00_1;

            default:    {regwrite, immsrc, alusrc, memwrite, resultsrc, branch, aluop, jump} = 11'b0_00_0_0_00_0_00_0;
        endcase
    end
endmodule


module ID(clk,rst,instrd,pcd,pc4d,resultw,rdw,regwritew,regwritee,resultsrce,memwritee,jumpe,branche,alusrce,aluctrle,rd1e,rd2e,immexte,rdde,pcde,pc4de);
 input clk,rst,regwritew;
 input[4:0] rdw;
 input[31:0] instrd,pcd,pc4d,resultw;
 output regwritee,resultsrce,memwritee,jumpe,branche,alusrce;
 output[2:0]aluctrle;
 output[31:0] rd1e, rd2e,immexte;
 output[4:0] rdde;
 output[31:0] pcde,pc4de;

 wire regwrited,resultsrcd,memwrited,jumpd,branchd,alusrcd;
 wire[2:0] aluctrld;
 wire[1:0] immsrcd;
 wire[31:0] rd1d, rd2d,immextd;
 wire[4:0] rdd;

  control_unit cu1(
    .op(instrd[6:0]),
     .func3(instrd[14:12]),
     .func7(instrd[31:25]),
     .regwrite(regwrited),
     .resultsrc(resultsrcd),
     .memwrite(memwrited),
     .jump(jumpd),
     .branch(branchd),
     .aluctrl(aluctrld),
     .alusrc(alusrcd),
     .immsrc(immsrcd));
  
  reg_file reg1(
    .clk(clk),
     .rst(rst),
     .we3(regwritew),
     .a1(instrd[19:15]),
     .a2(instrd[24:20]),
     .a3(rdw),
     .wd3(resultw),
     .rd1(rd1d),
     .rd2(rd2d));

 immediate_extend immex(
     .instruction(instrd[31:7]),
     .imm_src(immsrcd),
     .immediate_extended(immextd));
 //instruction decoder unit
     reg regwritedr,resultsrcdr,memwritedr,jumpdr,branchdr,alusrcdr;
     reg[2:0]aluctrldr;
     reg[31:0] rd1dr, rd2dr,immextdr;
     reg[4:0] rddr;
     reg[31:0] pcdr,pc4dr;

 //logic for instruction decoder
     always@(posedge clk or posedge rst)begin
        if(rst)begin
            regwritedr <= 1'b0;
            resultsrcdr <= 1'b0;
            memwritedr <= 1'b0;
            jumpdr <= 1'b0;
            branchdr <= 1'b0;
            alusrcdr <= 1'b0;
            aluctrldr <= 3'b000;
            rd1dr <= 32'b0;
            rd2dr <= 32'b0;
            immextdr <= 32'b0;
            rddr <= 5'b0;
            pcdr <= 32'b0;
            pc4dr <= 32'b0;
        end
        else
         regwritedr <= regwrited;
            resultsrcdr <= resultsrcd;
            memwritedr <= memwrited;
            jumpdr <= jumpd;
            branchdr <= branchd;
            alusrcdr <= alusrcd;
            aluctrldr <= aluctrld;
            rd1dr <= rd1d;
            rd2dr <= rd2d;
            immextdr <= immextd;
            rddr <= instrd[11:7];
            pcdr <= pcd;
            pc4dr <= pc4d;
     end
 //output logic
     assign regwritee = regwritedr;
     assign resultsrce = resultsrcdr;
     assign memwritee = memwritedr;
     assign jumpe = jumpdr;
     assign branche = branchdr;
     assign alusrce = alusrcdr;
     assign aluctrle = aluctrldr;
     assign rd1e = rd1dr;
     assign rd2e = rd2dr;
     assign immexte = immextdr;
     assign rdde = rddr;
     assign pcde = pcdr;
     assign pc4de = pc4dr;

endmodule
