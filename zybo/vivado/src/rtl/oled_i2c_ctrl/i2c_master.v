`default_nettype none

module i2c_master
  #(
    parameter CLK_DIV = 16'd10
    )
   (
    input wire 	      clk,
    input wire 	      reset,
   
    input wire 	      kick,
    output reg 	      busy = 1'b1,
    input wire [6:0]  slave_addr, // 7-bit
    input wire 	      read_mode,
    input wire [15:0] din,
    output reg [63:0] dout = 64'h0,
    input wire [7:0]  send_len,
    input wire [7:0]  recv_len,
   
    output reg 	      sda_t = 1'b0, // '0' indicates sda_o is enabled
    output reg 	      sda_o = 1'b1,
    input wire 	      sda_i,

    output reg 	      scl_t = 1'b0, // '0' indicates sda_o is enabled
    output reg 	      scl_o = 1'b1,
    input wire 	      scl_i
    );
   
   reg 		      enable = 0;
   reg 		      running = 0;
   
   reg [6:0] 	      slave_addr_reg = 0;
   reg 		      read_mode_reg = 0;
   reg [15:0] 	      din_reg = 0;
   reg [7:0] 	      send_len_reg = 0;
   reg [7:0] 	      recv_len_reg = 0;
   
   wire i2c_clk_en;
   clk_div clk_div_i (.clk(clk), .rst(reset), .div(CLK_DIV), .clk_out(i2c_clk_en));
   
   reg [7:0] i2c_state = 0;
   reg [7:0] i2c_state_next = 0;
   reg [7:0] i2c_sub_counter = 0;
   reg [7:0] i2c_bit_counter = 0;

   localparam IDLE              = 8'd0;
   localparam START_CONDITION   = 8'd1;
   localparam START_CONDITION2  = 8'd2;
   localparam SEND_SLAVE_ADDR   = 8'd3;
   localparam SEND_DATA         = 8'd4;
   localparam RECV_DATA         = 8'd5;
   localparam SEND_ACK          = 8'd6;
   localparam RECV_ACK          = 8'd7;
   localparam STOP_CONDITION    = 8'd8;

   reg [7:0] send_buf = 0;
   reg 	     nack_reg = 0;

   always @(posedge clk) begin
      if(reset == 1) begin
	 busy <= 1;
	 read_mode_reg <= 0;
	 slave_addr_reg <= 0;
	 send_len_reg <= 0;
	 recv_len_reg <= 0;
	 din_reg <= 0;
	 
	 scl_t <= 0; // scl_o is enabled
	 scl_o <= 1;
	 sda_t <= 0; // sda_o is enabled
	 sda_o <= 1;
	 i2c_state <= IDLE;
	 i2c_state_next <= IDLE;
	 i2c_sub_counter <= 0;
	 i2c_bit_counter <= 0;
	 
	 dout <= 0;
	 send_buf <= 0;
      end else if(i2c_clk_en == 1) begin
	 case(i2c_state)
	   
	   IDLE: begin
	      if(kick == 1) begin
		 busy <= 1;
		 i2c_state <= START_CONDITION;
		 i2c_state_next <= SEND_SLAVE_ADDR;
		 i2c_sub_counter <= 0;
		 dout <= 0;
		 slave_addr_reg <= slave_addr;
		 read_mode_reg <= read_mode;
		 din_reg <= din;
		 send_len_reg <= send_len > 0 ? send_len : 8'd1;
		 recv_len_reg <= recv_len > 0 ? recv_len : 8'd1;
	      end else begin
		 busy <= 0;
	      end
	   end

	   START_CONDITION: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 1;
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 0; // high -> low during scl == 1
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 0;
		 i2c_sub_counter <= 0;
		 i2c_bit_counter <= 0;
		 send_buf <= {slave_addr_reg, 1'b0}; // slave_addr + 'W'
		 i2c_state <= i2c_state_next;
		 i2c_state_next <= SEND_DATA;
	      end
	   end // case: START_CONDITION
	   
	   SEND_SLAVE_ADDR: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 // sdo should be changed
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= send_buf[7]; // set data during scl=0
		 send_buf <= {send_buf[6:0], 1'b0};
		 i2c_sub_counter <= i2c_sub_counter + 1;
		 i2c_bit_counter <= i2c_bit_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1; // fix data by rising scl_o
		 //sda_t <= 0;     // data should not be changed
		 //sda_o <= sda_o; // data should not be changed
		 i2c_sub_counter <= 0;
		 if(i2c_bit_counter == 8) begin
		    i2c_state <= RECV_ACK;
		    i2c_bit_counter <= 0;
		 end
	      end
	   end // case: SEND_SLAVE_ADDR

	   RECV_ACK: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 0; // sda_o is still enabled
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0; // still LOW
		 sda_t <= 1; // sda_i is enabled, sda_o is disabled
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 2) begin
		 // I2C-device should return ACK with rising scl
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1;
		 sda_t <= 1; // sda_i is enabled, sda_o is disabled
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 1; // sda_i is enabled, sda_o is disabled
		 i2c_sub_counter <= 0;
		 i2c_state <= i2c_state_next;
	      end // else: !if(i2c_sub_counter == 1)
	   end // case: RECV_ACK

	   SEND_DATA: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 // sda should be changed
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= din_reg[15]; // set data during scl=0
		 din_reg <= {din_reg[14:0], 1'b0};
		 i2c_sub_counter <= i2c_sub_counter + 1;
		 i2c_bit_counter <= i2c_bit_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1; // fix data by rising scl_o
		 //sda_t <= 0;     // data should not be changed
		 //sda_o <= sda_o; // data should not be changed
		 i2c_sub_counter <= 0;
		 if(i2c_bit_counter == 8) begin
		    send_len_reg <= send_len_reg - 1;
		    i2c_state <= RECV_ACK;
		    i2c_bit_counter <= 0;
		    i2c_state_next <= send_len_reg > 1 ? SEND_DATA :
				     STOP_CONDITION;
		 end
	      end
	   end // case: SEND_DATA

	   STOP_CONDITION: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 0; // ready to generate stop condtion
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1; // fix data by rising scl_o
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 0; // sda_o is still '0'
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1; // fix data by rising scl_o
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 1; // low -> high during scl == 1
		 i2c_sub_counter <= 0;
		 if(read_mode_reg == 0)
		   i2c_state <= IDLE;
		 else begin
		    i2c_state <= START_CONDITION2;
		    i2c_state_next <= SEND_SLAVE_ADDR;
		 end
	      end
	   end

	   START_CONDITION2: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 1;
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 0; // high -> low during scl == 1
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 0; // sda_o is enabled
		 sda_o <= 0;
		 i2c_sub_counter <= 0;
		 i2c_bit_counter <= 0;
		 send_buf <= {slave_addr_reg, 1'b1}; // slave_addr + 'R'
		 i2c_state <= i2c_state_next;
		 i2c_state_next <= RECV_DATA;
	      end
	   end // case: START_CONDITION
	   
	   RECV_DATA: begin
	      if(i2c_sub_counter == 0) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 // sda should be changed
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 1; // sda_o is disabled
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 2) begin
		 // I2C-device shold prepare data
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1; // fix data by rising scl_o
		 sda_t <= 1; // sda_o is disabled
		 i2c_sub_counter <= i2c_sub_counter + 1;
		 i2c_bit_counter <= i2c_bit_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0;
		 sda_t <= 1; // sda_o is disabled
		 dout[63:1] <= dout[62:0];
		 dout[0] <= sda_i;
		 i2c_sub_counter <= 0;
		 if(i2c_bit_counter == 8) begin
		    recv_len_reg <= recv_len_reg - 1;
		    i2c_state <= SEND_ACK;
		    i2c_bit_counter <= 0;
		    if(recv_len_reg > 1) begin
		       i2c_state_next <= RECV_DATA;
		       nack_reg <= 1'b0;
		    end else begin
		       read_mode_reg <= 0; // read_mode_reg iconsumed
		       i2c_state_next <= STOP_CONDITION;
		       nack_reg <= 1'b1;
		    end
		 end
	      end
	   end // case: SEND_DATA
	   
	   SEND_ACK: begin
	      if(i2c_sub_counter == 0) begin
		 // prepare ACK (should be in scl is LOW)
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0; // stil LOW
		 sda_t <= 0; // sda_i is enabled
		 sda_o <= nack_reg; // prepare ACK
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else if(i2c_sub_counter == 1) begin
		 // fix ACK with rising scl
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 1;
		 sda_t <= 0; // sda_i is enabled
		 sda_o <= nack_reg; // prepare ACK
		 i2c_sub_counter <= i2c_sub_counter + 1;
	      end else begin
		 scl_t <= 0; // scl_o is enabled
		 scl_o <= 0; // HIGH->LOW
		 // sda must not be changed
		 i2c_sub_counter <= 0;
		 i2c_state <= i2c_state_next;
	      end // else: !if(i2c_sub_counter == 1)
	   end // case: SEND_ACK
	   
	 endcase // case (i2c_state)
      end // if (i2c_clk_en == 1)
   end // always @ (posedge clk)

endmodule // i2c_master

`default_nettype wire
