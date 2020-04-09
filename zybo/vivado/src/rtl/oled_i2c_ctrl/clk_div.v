`default_nettype none

module clk_div
  (
   input wire clk,
   input wire rst,
   input wire [31:0] div,
   output reg clk_out
   );
   
   reg [31:0] counter = 0;

   always @(posedge clk) begin
      if(rst == 1) begin
         counter <= 0;
         clk_out  <= 0;
      end else if(counter == div) begin
         counter <= 0;
	 clk_out <= 1;
      end else begin
         counter <= counter + 1;
         clk_out <= 0;
      end
   end

endmodule // clk_div

`default_nettype wire

