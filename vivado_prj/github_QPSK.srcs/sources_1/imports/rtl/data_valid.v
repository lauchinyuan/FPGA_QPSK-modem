`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 依据设定的帧头和校验和,验证正确的数据 
// 本设计中帧头为8'b1100_1100
//////////////////////////////////////////////////////////////////////////////////
module data_valid
#(parameter HEADER = 8'b1100_1100)
(
    input wire          clk         ,  //500KHz
    input wire          rst_n       ,
    input wire          ser_i       ,  //从iq_comb模块输入的串行数据
    input wire          sync_flag   ,  //同步标志
    
    output wire         header_flag ,  //侦测到正确的帧头
    output wire         valid_flag  ,  //帧头和校验和都正确标志，代表有效数据
    output reg  [39:0]  valid_data_o   //将有效数据进行并行输出
);
    reg [39:0]  shift_reg   ;       //移位寄存器，寄存输入的串行数据
    wire [7:0]  sum         ;       //通过计算得到的校验和
    
    wire    check_sum_valid_flag    ; //校验和正确标志
    
    //移位寄存器
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            shift_reg <= 40'b0;
        end else if(sync_flag) begin
            shift_reg <= {shift_reg[38:0],ser_i}; //IQ数据高位先发,故接收数据由低位向高位移动
        end else begin
            shift_reg <= shift_reg;
        end
    end
    
    //valid_data_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            valid_data_o <= 40'b0;
        end else if(valid_flag) begin
            valid_data_o <= shift_reg;
        end else begin
            valid_data_o <= valid_data_o;
        end
    end
    
    //帧头标志
    assign header_flag = (shift_reg[39:32] == HEADER);
    assign sum = shift_reg[39:32] + shift_reg[31:24] + shift_reg[23:16] + shift_reg[15:8];
    assign check_sum_valid_flag = (sum == shift_reg[7:0])?1'b1: 1'b0;  //校验和
    assign valid_flag = header_flag & check_sum_valid_flag; //校验和以及帧头都正确
    

    
    

endmodule
