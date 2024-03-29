`default_nettype none

module oled_i2c_mon#(parameter CLK_DIV = 16'd1000, parameter FREQ_MHZ = 16'd100)
    (
     input wire clk,
     input wire reset,

     input wire [31:0] dbg_tl,
     input wire [31:0] dbg_tr,
     input wire [31:0] dbg_bl,
     input wire [31:0] dbg_br,

     output wire sda_t, // '0' indicates sda_o is enabled
     output wire sda_o,
     input wire sda_i,
     
     output wire scl_t, // '0' indicates sda_o is enabled
     output wire scl_o,
     input wire scl_i
     );

    function [7:0] bit4char;
	input [3:0] vec;
	case (vec)
            4'h0: bit4char=8'h30;
            4'h1: bit4char=8'h31;
            4'h2: bit4char=8'h32;
            4'h3: bit4char=8'h33;
            4'h4: bit4char=8'h34;
            4'h5: bit4char=8'h35;
            4'h6: bit4char=8'h36;
            4'h7: bit4char=8'h37;
            4'h8: bit4char=8'h38;
            4'h9: bit4char=8'h39;
            4'ha: bit4char=8'h41;
            4'hb: bit4char=8'h42;
            4'hc: bit4char=8'h43;
            4'hd: bit4char=8'h44;
            4'he: bit4char=8'h45;
            4'hf: bit4char=8'h46;
            default: bit4char=0;
	endcase
    endfunction

    (* mark_debug="true" *) reg         i2c_kick;
    (* mark_debug="true" *) wire        i2c_busy;
    wire [6:0]  i2c_slave_addr = 7'b0111100; // SA0 = 0
    wire        i2c_read_mode = 1'b0; // write only
    (* mark_debug="true" *) reg  [15:0] i2c_din;
    wire [63:0] i2c_dout;
    reg  [7:0]  i2c_send_len;
    reg  [7:0]  i2c_recv_len;

    (* mark_debug="true" *) reg [31:0] sleep_value;
    (* mark_debug="true" *) reg        sleep_kick;
    (* mark_debug="true" *) wire       sleep_out;

    (* mark_debug="true" *) reg [127:0] print_data;
    (* mark_debug="true" *) reg [7:0] print_cnt;

    (* mark_debug="true" *) reg [7:0] state, next_state;
    localparam IDLE          = 8'h00;
    localparam S_I2C_KICK    = 8'h01;
    localparam S_I2C_WAIT    = 8'h02;
    localparam S_WAIT_SLEEP  = 8'h03;
    localparam S_CLR_DISP    = 8'h04;
    localparam S_WAIT_SLEEP1 = 8'h05;
    localparam S_RET_HOME    = 8'h06;
    localparam S_WAIT_SLEEP2 = 8'h07;
    localparam S_DISP_ON     = 8'h08;
    localparam S_WAIT_SLEEP3 = 8'h09;
    localparam S_CLR_DISP2   = 8'h0a;
    localparam S_WAIT_SLEEP4 = 8'h0b;
    localparam S_FETCH_DATA  = 8'h0c;
    localparam S_PRINT_DATA  = 8'h0d;

    always @(posedge clk) begin
	if(reset) begin
	    state <= IDLE;
	    next_state <= IDLE;
	    i2c_kick <= 1'b0;
	    i2c_din <= 16'h0;
	    i2c_send_len <= 8'd2;
	    i2c_recv_len <= 8'd0;
	end else begin
	    case(state)
		IDLE: begin
		    state <= S_WAIT_SLEEP;
		end
		S_I2C_KICK: begin // assert i2c_kick
		    if(i2c_busy == 1'b1) begin // detect i2c'running
			i2c_kick <= 1'b0;
			state <= S_I2C_WAIT;
		    end else begin
			i2c_kick <= 1'b1; // keep i2c_kick
		    end
		end
		S_I2C_WAIT: begin // wait for i2c operation
		    if(i2c_busy == 1'b0) begin // done i2c operation
			state <= next_state; // goto preserved next state
		    end
		end
		S_WAIT_SLEEP: begin
		    sleep_value <= 100000; // 100ms
		    state <= S_CLR_DISP;
		end

		S_CLR_DISP: begin
		    if(sleep_out) begin
			i2c_kick <= 1;
			i2c_din <= {8'h00, 8'h01};
			state <= S_I2C_KICK;
			next_state <= S_WAIT_SLEEP1;
		    end
		end

		S_WAIT_SLEEP1: begin
		    sleep_value <= 20000;  // 20ms
		    state <= S_RET_HOME;
		end

		S_RET_HOME: begin
		    if(sleep_out) begin
			i2c_kick <= 1;
			i2c_din <= {8'h00, 8'h02};
			state <= S_I2C_KICK;
			next_state <= S_WAIT_SLEEP2;
		    end
		end

		S_WAIT_SLEEP2: begin
		    sleep_value <= 2000; // 2ms
		    state <= S_DISP_ON;
		end

		S_DISP_ON: begin
		    if(sleep_out) begin
			i2c_kick <= 1;
			i2c_din <= {8'h00, 8'h0C};
			state <= S_I2C_KICK;
			next_state <= S_WAIT_SLEEP3;
		    end
		end

		S_WAIT_SLEEP3: begin
		    sleep_value <= 2000; // 2ms
		    state <= S_CLR_DISP2;
		end

		S_CLR_DISP2:begin
		    if(sleep_out) begin
			i2c_kick <= 1;
			i2c_din <= {8'h00, 8'h01};
			state <= S_I2C_KICK;
			next_state <= S_WAIT_SLEEP4;
		    end
		end

		S_WAIT_SLEEP4: begin
		    sleep_value <= 20000; // 20ms
		    state <= S_FETCH_DATA;
		end

		S_FETCH_DATA: begin
		    if(sleep_out) begin
			print_data <= {dbg_tl, dbg_tr, dbg_bl, dbg_br};
			print_cnt <= 32;
			state <= S_PRINT_DATA;
		    end
		end
		
		S_PRINT_DATA: begin
		    if(print_cnt == 0) begin
			state <= S_FETCH_DATA;
		    end else begin
			print_cnt <= print_cnt - 1;
			i2c_kick <= 1'b1;
			i2c_din <= {8'h40, bit4char(print_data[127:124])};
			print_data <= {print_data[123:0], 4'h0};
			state <= S_I2C_KICK;
			next_state <= S_PRINT_DATA; // to return here
		    end
		end

	    endcase
	end
    end // always @ (posedge clk)

    always @(posedge clk)
      if(state == S_WAIT_SLEEP ||
	 state == S_WAIT_SLEEP1 ||
	 state == S_WAIT_SLEEP2 ||
	 state == S_WAIT_SLEEP3 ||
	 state == S_WAIT_SLEEP4)
	sleep_kick <= 1;
      else
	sleep_kick <= 0;

    i2c_master#(.CLK_DIV(CLK_DIV)) i2c_master_i
      (.clk(clk),
       .reset(reset),
   
       .kick(i2c_kick),
       .busy(i2c_busy),
       .slave_addr(i2c_slave_addr), // 7-bit
       .read_mode(i2c_read_mode),
       .din(i2c_din),
       .dout(i2c_dout),
       .send_len(i2c_send_len),
       .recv_len(i2c_recv_len),
       .sda_t(sda_t),
       .sda_o(sda_o),
       .sda_i(sda_i),
       .scl_t(scl_t), // '0' indicates sda_o is enabled
       .scl_o(scl_o),
       .scl_i(scl_i));

    simple_sleep#(.FREQ_MHZ(FREQ_MHZ))
    simple_sleep_i(.clk(clk),
		   .reset(reset),
		   .sleep_value(sleep_value),
		   .sleep_kick(sleep_kick), 
		   .sleep_out(sleep_out));

endmodule // oled_i2c_mon

module simple_sleep#(parameter FREQ_MHZ = 16'd100)
    (
     input wire clk,
     input wire reset,
     input wire [31:0] sleep_value,
     input wire sleep_kick,
     output wire sleep_out
     );

    reg [31:0] sleep_rest;
    assign sleep_out = (sleep_rest == 17'd0 && sleep_kick == 1'b0) ? 1'b1 : 1'b0;

    reg us_pulse;
    reg [15:0] us_counter = 16'd0;
    always @(posedge clk) begin
	if(us_counter < FREQ_MHZ) begin
	    us_counter <= us_counter + 1;
	    us_pulse <= 0;
	end else begin
	    us_counter <= 0;
	    us_pulse <= 1;
	end
    end

    always @(posedge clk) begin
	if(reset) begin
	    sleep_rest <= 32'd0;
	end else begin
	    if(sleep_kick)
	      sleep_rest[31:0] <= sleep_value;
	    else if(sleep_rest > 0 && us_pulse)
	      sleep_rest <= sleep_rest - 1;
	end
    end

endmodule // simple_sleep

`default_nettype wire
