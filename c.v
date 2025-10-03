`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.10.2025 18:48:19
// Design Name: 
// Module Name: c
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

module PC(clk,rst,pc,pcnext);
input clk,rst;
input[31:0] pcnext;
output reg[31:0] pc;
always @(posedge clk or posedge rst) begin
    if(rst == 1'b1)begin
        pc = 32'b0;
    end
    else 
    pc = pcnext;
end
    endmodule

module MUX2_1(a,b,s,c);
input[31:0] a,b;
input s;
output[31:0] c;
assign c = s?a:b;
endmodule

module IMEM(rst,a,rd);
input rst;
input[31:0] a;
output[31:0] rd;
reg[31:0] mem [1023:0];
assign rd = (~rst)?{32{1'b1}}: mem[a[31:2]];
initial begin
    $readmemh("memfile.hex",mem);
end
endmodule

module PC4(a,c);
input[31:0]a;
output[31:0]c;
assign c = a + 3'b100;
endmodule

module IF(
    input clk,rst,pcsrce,
input [31:0] pctargete,
output[31:0] instd,pcd,pc4d
);
wire[31:0] pcfb,pcf,pc4f,rdf;
reg[31:0] instf_reg,pcf_reg,pc4f_reg;

MUX2_1 m1(.a(pc4f), .b(pctargete), .s(pcsrce), .c(pcfb));

PC p1(.clk(clk), .rst(rst), .pc(pcfb), .pcnext(pcf));

IMEM I1(.rst(rst), .a(pcf), .rd(rdf));

PC4 pc4(.a(pcf), .c(pc4f));

always @(posedge clk or posedge rst)begin
    if(rst==1)begin
        instf_reg <= 32'b00000;
        pc4f_reg<= 32'b00000;
        pcf_reg <= 32'b000000;
    end
        else begin
            instf_reg <= rdf;
            pc4f_reg <= pc4f;
            pcf_reg <= pcf;
        end
    end

assign instd = (rst == 1'b0)?instf_reg : 32'b00000;
assign pcd = (rst ==1'b0)? pcf_reg : 32'b0;
assign pc4d = (rst ==1'b0)? pc4f_reg : 32'b0;
endmodule
