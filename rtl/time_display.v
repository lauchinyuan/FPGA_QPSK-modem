`timescale 1ns / 1ps
//将40bit数据中的时分秒数据进行解析并动态显示在数码管上
module time_display
(
    input   wire        clk     ,
    input   wire        rst_n   ,
    input   wire[39:0]  dat_i   ,
    
    output  wire[5:0]   sel     ,  //数码管选择信号
    output  wire[7:0]   dig        //数码管数据
);
    //时分秒原始数据
    wire [7:0]      dec_h       ;
    wire [7:0]      dec_m       ;
    wire [7:0]      dec_s       ;
    
    //时分秒对应的bcd数据
    wire [3:0]      bcd_h_ten   ;
    wire [3:0]      bcd_h_unit  ;
    wire [3:0]      bcd_m_ten   ;
    wire [3:0]      bcd_m_unit  ;
    wire [3:0]      bcd_s_ten   ;
    wire [3:0]      bcd_s_unit  ;
    
    //依据对应数据位解析时分秒
    assign dec_h = dat_i[31:24] ;
    assign dec_m = dat_i[23:16] ;
    assign dec_s = dat_i[15:8]  ;
    
    
    //将原始数据转换为BCD编码
    //时
    dec2bcd dec2bcd_h(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (dec_h  ),  

        .unit       (bcd_h_unit ),
        .ten        (bcd_h_ten  )   
    );
    
    //分
    dec2bcd dec2bcd_m(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (dec_m  ),  

        .unit       (bcd_m_unit ),
        .ten        (bcd_m_ten  )   
    );
    
    //秒
    dec2bcd dec2bcd_s(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (dec_s  ),  

        .unit       (bcd_s_unit ),
        .ten        (bcd_s_ten  )   
    );
    
    //数码管显示控制信号生成
    seg_display 
    #(.CNT_SEL_MAX(10'd999))
    seg_display_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .in0        (bcd_s_unit ),
        .in1        (bcd_s_ten  ),
        .in2        (bcd_m_unit ),
        .in3        (bcd_m_ten  ),
        .in4        (bcd_h_unit ),
        .in5        (bcd_h_ten  ),

        .sel        (sel    ),
        .dig        (dig    )
    );

    
endmodule
