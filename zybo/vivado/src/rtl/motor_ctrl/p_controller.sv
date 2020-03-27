/*
 MIT License

 Copyright (c) 2020 Yuya Kudo

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

module p_controller
  #(parameter
    BAND_WIDTH         = 32,
    CLK_FREQ           = 100_000_000,
    ONE_ROTATION_PULSE = 630, // pulse/rotate
    SAMPLING_RATE      = 100, // sample/s
    localparam
    PI_FIXED           = 804, // 3.14 << 8
    RESOLUTION         = 2 * PI_FIXED * SAMPLING_RATE / ONE_ROTATION_PULSE,
    UPDATE_INTERVAL    = CLK_FREQ / SAMPLING_RATE)
   (input  logic [31:0]           target_rot_v,
    input  logic [31:0]           p_gain,
    input  logic [31:0]           rot_cnt,
    output logic [BAND_WIDTH-1:0] pulse_width,
    input  logic                  clk,
    input  logic                  rstn);

   typedef enum logic [1:0] {STT_GET_ERROR,
                             STT_CALC_TERM,
                             STT_CALC_PULSE,
                             STT_WAIT} p_statetype;

   p_statetype  p_state;
   logic [31:0] cnt_r;
   logic        update_flag;

   logic [31:0] rot_cnt_r;

   logic signed [BAND_WIDTH*2-1:0] pulse_width_r, pulse_width_w;
   logic signed [BAND_WIDTH*2-1:0] rotate_samp_cnt_r;
   logic signed [BAND_WIDTH*2-1:0] error_w;
   logic signed [BAND_WIDTH*2-1:0] error_r, p_error_r;
   logic signed [BAND_WIDTH*2-1:0] p_term_r;
   logic signed [BAND_WIDTH*2-1:0] p_term_w;

   always_comb begin
      update_flag   = (cnt_r == UPDATE_INTERVAL) ? 1 : 0;
      error_w       = $signed(target_rot_v) - (rotate_samp_cnt_r * $signed(RESOLUTION));
      p_term_w      = ($signed(p_gain) * error_r);
      pulse_width_w = pulse_width_r + p_term_r;
      pulse_width   = pulse_width_r;
   end

   always_ff @(posedge clk) begin
      if(!rstn) begin
         p_state           <= STT_WAIT;
         cnt_r             <= 0;
         pulse_width_r     <= 0;
         rotate_samp_cnt_r <= 0;
         rot_cnt_r         <= 0;
         error_r           <= 0;
         p_error_r         <= 0;
         p_term_r          <= 0;
      end
      else begin
         if(update_flag) begin
            cnt_r <= 0;
         end
         else begin
            cnt_r <= cnt_r + 1;
         end

         //-----------------------------------------------------------------------------
         // 4 state FSM
         case(p_state)
           STT_GET_ERROR: begin
              p_error_r <= error_r;
              error_r   <= error_w;
              p_state <= STT_CALC_TERM;
           end
           STT_CALC_TERM: begin
              p_term_r <= p_term_w >>> 16;
              p_state  <= STT_CALC_PULSE;
           end
           STT_CALC_PULSE: begin
              pulse_width_r <= (target_rot_v != 0) ? pulse_width_w : 0;
              p_state       <= STT_WAIT;
           end
           STT_WAIT: begin
              if(update_flag) begin
                 rotate_samp_cnt_r <= $signed(rot_cnt) - $signed(rot_cnt_r);
                 rot_cnt_r         <= rot_cnt;
                 p_state           <= STT_GET_ERROR;
              end
           end
         endcase
      end
   end

endmodule
