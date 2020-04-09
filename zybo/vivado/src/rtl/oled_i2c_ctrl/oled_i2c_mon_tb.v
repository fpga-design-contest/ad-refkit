`timescale 1ns/1ps
`default_nettype none

module oled_i2c_mon_tb();

    localparam FREQ = 100_000_000;

    reg clk = 1'b0;
    reg reset = 1'b0;
    reg [31:0] dbg_tl, dbg_tr, dbg_bl, dbg_br;
    wire sda_t, sda_o, sda_i;
    wire scl_t, scl_o, scl_i;

    always begin
	#5 clk <= ~clk;
    end

    assign sda_i = 0;

    reg [31:0] state_counter = 32'd0;
    always @(posedge clk) begin
	case(state_counter)
	    0: begin
		reset <= 1'b1;
		state_counter <= state_counter + 1;
		dbg_tl <= 32'hdeadbeaf;
		dbg_tr <= 32'habadcafe;
		dbg_bl <= 32'h34343434;
		dbg_br <= 32'ha5a5a5a5;
	    end
	    10: begin
		reset <= 1'b0;
		state_counter <= state_counter + 1;
	    end
	    default: begin
		if(state_counter < 20000000)
		  state_counter <= state_counter + 1;
		else
		  $finish;
	    end
	endcase
    end

    oled_i2c_mon#(.CLK_DIV(FREQ/100/1000), .FREQ_MHZ(FREQ/1000/1000))
    DUT(.clk(clk),
	.reset(reset),
	.dbg_tl(dbg_tl),
	.dbg_tr(dbg_tr),
	.dbg_bl(dbg_bl),
	.dbg_br(dbg_br),
	.sda_t(sda_t),
	.sda_o(sda_o),
	.sda_i(sda_i),
	.scl_t(scl_t),
	.scl_o(scl_o),
	.scl_i(scl_i)
     );

endmodule // oled_i2c_mon_tb

`default_nettype wire
