`timescale 1ns / 1ps

module tb_dec2bcd();
    reg         clk     ;
    reg         rst_n   ;
    reg [7:0]   data_i  ;
    
    wire [3:0]  unit    ;
    wire [3:0]  ten     ;
    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        data_i <= 8'b0011_1011; //59
    #30 
        rst_n <= 1'b1;
    end
    
    always #10 clk = ~clk;
    
    dec2bcd dec2bcd_inst(
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dec_in     (data_i ),  

        .unit       (unit   ),
        .ten        (ten    )   
    );
endmodule
