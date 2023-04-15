module qpsk_mod_demod
(
	input wire 			clk			,
	input wire 			rst_n		,
	input wire [39:0]	para_in		,
	
	output wire [39:0]	para_out
);
	wire [32:0]			qpsk	;
	
	//调制
	qpsk_mod qpsk_mod_inst
	(
		.clk		(clk		),
		.rst_n		(rst_n		),
		.para_in	(para_in	),

		.qpsk	    (qpsk	    )
    );
	
	//解调
	qpsk_demod qpsk_demod_inst
	(
		.clk		(clk		),
		.rst_n		(rst_n		),
		.qpsk		(qpsk[21:0]	),  //经过仿真确认高位没有使用到

		.para_out	(para_out	)
    );
endmodule
