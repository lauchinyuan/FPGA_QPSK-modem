`timescale 1ns / 1ps

module tb_para2ser();
    reg         clk     ;
    reg         rst_n   ;
    reg [39:0]  para_i  ;
    
    wire        ser_o   ;
    
    initial begin
        clk = 1'b1;
        para_i <= 40'b11111111_00010111_00011000_00011001_11111111;
        rst_n <= 1'b0;
    #50
        rst_n <= 1'b1;
    
    end
    
    always #10 clk = ~clk; //50Mhz时钟

    para2ser
    #(.DIV(14'd12500))
    para2ser_inst
    (
        .clk            (clk    ),
        .rst_n          (rst_n  ),
        .para_i         (para_i ),

        .ser_o          (ser_o  )
    );
endmodule
