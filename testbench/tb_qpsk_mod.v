`timescale 1ns / 1ps
module tb_qpsk_mod();
    reg         clk     ;
    reg         rst_n   ;
    reg [39:0]  para_i  ;
    
    wire [28:0] qpsk    ;
    
    initial begin
        clk = 1'b1;
        para_i <= 40'b11111111_00010111_00011000_00011001_11111111;
        rst_n <= 1'b0;
    #50
        rst_n <= 1'b1;
    end
    
    always #10 clk = ~clk; //50Mhz时钟
    
    qpsk_mod qpsk_mod_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .para_in    (para_i     ),

        .qpsk       (qpsk       )
    );

endmodule
