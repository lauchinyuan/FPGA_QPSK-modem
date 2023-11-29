`timescale 1ns / 1ps
module tb_data_valid();
    reg         clk         ;
    reg         rst_n       ;
    reg         ser_i       ;
    reg         sync_flag   ;
    reg [39:0]  data        ;
    
    wire        header_flag ;
    wire        valid_flag  ;
    wire [39:0] valid_data_o;
    
    integer i;
    
    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        //帧头和校验和都正确的数据
        data <= 40'b1100_1100_0001_0111_0001_1000_0001_1001_0001_0100;
        sync_flag <= 1'b0;
        ser_i <= 1'b0;
    #2000
        rst_n <= 1'b1;
        for(i=0;i<=39;i=i+1) begin
            #8000
            ser_i <= data[39 - i]; //高位先入
            sync_flag <= 1'b1;
            #2000  //sync_flag设置为持续一个周期
            sync_flag <= 1'b0;
        end
    end
    
    always #1000 clk = ~clk;  //500kHz
        
    
    data_valid 
    #(.HEADER(8'b1100_1100))
    valid_data_inst
    (
        .clk            (clk            ),  //500KHz
        .rst_n          (rst_n          ),
        .ser_i          (ser_i          ),  //从iq_comb模块输入的串行数据
        .sync_flag      (sync_flag      ),  //同步标志
 
        .header_flag    (header_flag    ),  //侦测到正确的帧头
        .valid_flag     (valid_flag     ),  //帧头和校验和都正确标志，代表有效数据
        .valid_data_o   (valid_data_o   )   //将有效数据进行并行输出
    );

endmodule
