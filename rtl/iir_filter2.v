`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: iir_filter2
// Description: 二阶IIR滤波器,用作载波同步中的环路滤波器
//////////////////////////////////////////////////////////////////////////////////
module iir_filter2
#(parameter c1 = 16'b)
    (
        input wire          clk         , //500kHz
        input wire          rst_n       , 
        input wire  [16:0]  phase_error , //相位误差
        
        output wire [23:0]  nco_o       
    );
    
    always
    
    
endmodule
