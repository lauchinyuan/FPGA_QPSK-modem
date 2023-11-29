//////////////////////////////////////////////////////////////////////////////////
// Dependencies: 生成40bit数据帧，并行输出
//////////////////////////////////////////////////////////////////////////////////
module data_gen
#(parameter HEADER = 8'hcc)  //帧头
(
    input wire [7:0]    dec_s   ,
    input wire [7:0]    dec_m   ,
    input wire [7:0]    dec_h   ,
    
    output wire [39:0]  para_o  
);

    wire [7:0]  valid   ; //校验和
    
    //帧头定为1100_1100,在IQ分流后两路数据都将会是1010，交替的0/1有利于Gardner位同步
    assign valid = HEADER + dec_s + dec_m + dec_h; //计算校验和
    assign para_o = {HEADER, dec_h, dec_m, dec_s, valid};

endmodule
