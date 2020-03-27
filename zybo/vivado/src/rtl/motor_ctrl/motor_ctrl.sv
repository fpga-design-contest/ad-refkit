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

module motor_ctrl
  #(parameter
    CLK_FREQ = 100_000_000,
    localparam
    BAND_WIDTH         = 32,
    ONE_ROTATION_PULSE = 630, // angular resolution = 360 / ONE_ROTATION_PULSE
    SAMPLING_RATE      = 100, // per sec
    PWM_PERIOD         = 40,  // us
    PWM_PERIOD_CYCLE   = (CLK_FREQ / 100_000) * PWM_PERIOD)
   (output logic                  pwm,
    output logic                  dir,
    output logic [BAND_WIDTH-1:0] pulse_width,
    output logic [BAND_WIDTH-1:0] rot_cnt,
    input  logic [31:0]           target_rot_v,
    input  logic [31:0]           p_gain,
    input  logic                  sa,
    input  logic                  sb,
    input  logic                  clk,
    input  logic                  rstn);

   logic [BAND_WIDTH-1:0] pwm_pulse_width;
   logic [BAND_WIDTH-1:0] p_gain;

   pwm_generator #(.BAND_WIDTH(BAND_WIDTH),
                   .PWM_PERIOD_CYCLE(PWM_PERIOD_CYCLE))
   pwm_gen_inst(.width(pwm_pulse_width),
                .pwm(pwm),
                .clk(clk),
                .rstn(rstn));

   rot_encoder #(.BAND_WIDTH(BAND_WIDTH))
   rot_encoder_inst(.sa(sa),
                    .sb(sb),
                    .count(rot_cnt),
                    .clk(clk),
                    .rstn(rstn));

   p_controller #(.BAND_WIDTH(BAND_WIDTH),
                  .CLK_FREQ(CLK_FREQ),
                  .ONE_ROTATION_PULSE(ONE_ROTATION_PULSE),
                  .SAMPLING_RATE(SAMPLING_RATE))
   p_ctrl_inst(.target_rot_v(target_rot_v),
               .p_gain(p_gain),
               .rot_cnt(rot_cnt),
               .pulse_width(pulse_width),
               .clk(clk),
               .rstn(rstn));

   always_comb begin
      dir             = pulse_width[31:31] ? 1'b1 : 1'b0;
      pwm_pulse_width = pulse_width[31:31] ? ~pulse_width : pulse_width;
   end

endmodule
