//产生500kHz采样时钟
module sam_clk_gen(
        input wire      clk     ,  //50MHz
        input wire      rst_n   ,
        
        output reg      clk_o   
    );
    
    reg [5:0] cnt_clk   ;
    //cnt_clk
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            cnt_clk <= 1'b0;
        end else if(cnt_clk == 6'd24) begin
            cnt_clk <= 1'b0;
        end else begin
            cnt_clk <= cnt_clk + 6'd1;
        end
    end
    
    //clk_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            clk_o <= 1'b0;
        end else if(cnt_clk == 6'd24) begin
            clk_o <= ~clk_o;
        end
    end

endmodule
