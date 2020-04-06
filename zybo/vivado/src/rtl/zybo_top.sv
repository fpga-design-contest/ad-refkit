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

module zybo_top
  #(localparam
    CLK_FREQ = 200_000_000)
   (output logic [3:0]  led,
    input  logic [3:0]  btn, sw,
    inout  logic        ja1, ja2, ja3, ja4, ja7, ja8, ja9, ja10,
    inout  logic        jb1, jb2, jb3, jb4, jb7, jb8, jb9, jb10,
    inout  logic        jc1, jc2, jc3, jc4, jc7, jc8, jc9, jc10,
    inout  logic        jd1, jd2, jd3, jd4, jd7, jd8, jd9, jd10,
    inout  logic        je1, je2, je3, je4, je7, je8, je9, je10,
    input  logic        dphy_hs_clock_clk_p, dphy_hs_clock_clk_n,
    input  logic        dphy_clk_lp_p, dphy_clk_lp_n,
    input  logic [1:0]  dphy_data_hs_p, dphy_data_hs_n,
    input  logic [1:0]  dphy_data_lp_p, dphy_data_lp_n,
    inout  logic        cam_iic_scl_io, cam_iic_sda_io,
    inout  logic [0:0]  cam_gpio_tri_io);

   logic        clk200M;
   logic        rstn;
   logic [31:0] r_target_rot_v, l_target_rot_v;
   logic [31:0] r_p_gain, l_p_gain;
   logic [31:0] r_rot_cnt, l_rot_cnt;
   
   logic [31:0] btns_tri;

   design_1_wrapper design_1_wrapper(.mipi_phy_if_0_clk_hs_p(dphy_hs_clock_clk_p),
                                     .mipi_phy_if_0_clk_hs_n(dphy_hs_clock_clk_n),
                                     .mipi_phy_if_0_clk_lp_p(dphy_clk_lp_p),
                                     .mipi_phy_if_0_clk_lp_n(dphy_clk_lp_n),
                                     .mipi_phy_if_0_data_hs_p(dphy_data_hs_p),
                                     .mipi_phy_if_0_data_hs_n(dphy_data_hs_n),
                                     .mipi_phy_if_0_data_lp_p(dphy_data_lp_p),
                                     .mipi_phy_if_0_data_lp_n(dphy_data_lp_n),
                                     .cam_iic_scl_io(cam_iic_scl_io),
                                     .cam_iic_sda_io(cam_iic_sda_io),
                                     .cam_gpio_tri_io(cam_gpio_tri_io),
                                     .r_target_rot_v(r_target_rot_v),
                                     .l_target_rot_v(l_target_rot_v),
                                     .r_p_gain(r_p_gain),
                                     .l_p_gain(l_p_gain),
                                     .r_rot_cnt(r_rot_cnt),
                                     .l_rot_cnt(l_rot_cnt),
                                     .btns_tri_i(btns_tri),
                                     .clk200M(clk200M),
                                     .rstn(rstn));

   //-----------------------------------------------------------------------------
   // motor ctrl
   logic        r_pwm, l_pwm;
   logic        r_dir, l_dir;
   logic [31:0] r_pulse_width, l_pulse_width;
   logic        r_sa, r_sb, l_sa, l_sb;
   logic        r_sa_q1, r_sa_q2, r_sa_q3;
   logic        r_sb_q1, r_sb_q2, r_sb_q3;
   logic        l_sa_q1, l_sa_q2, l_sa_q3;
   logic        l_sb_q1, l_sb_q2, l_sb_q3;

   motor_ctrl #(.CLK_FREQ(CLK_FREQ))
   right_motor_ctrl_inst(.pwm(r_pwm),
                         .dir(r_dir),
                         .pulse_width(r_pulse_width),
                         .rot_cnt(r_rot_cnt),
                         .target_rot_v(r_target_rot_v),
                         .p_gain(r_p_gain),
                         .sa(r_sa_q3),
                         .sb(r_sb_q3),
                         .clk(clk200M),
                         .rstn(rstn));

   motor_ctrl #(.CLK_FREQ(CLK_FREQ))
   left_motor_ctrl_inst(.pwm(l_pwm),
                        .dir(l_dir),
                        .pulse_width(l_pulse_width),
                        .rot_cnt(l_rot_cnt),
                        .target_rot_v(l_target_rot_v),
                        .p_gain(l_p_gain),
                        .sa(l_sa_q3),
                        .sb(l_sb_q3),
                        .clk(clk200M),
                        .rstn(rstn));

   // for preventing meta-stable
   always_ff @(posedge clk200M) begin
      if(!rstn) begin
         r_sa_q1 <= 0;
         r_sa_q2 <= 0;
         r_sa_q3 <= 0;
         r_sb_q1 <= 0;
         r_sb_q2 <= 0;
         r_sb_q3 <= 0;
         l_sa_q1 <= 0;
         l_sa_q2 <= 0;
         l_sa_q3 <= 0;
         l_sb_q1 <= 0;
         l_sb_q2 <= 0;
         l_sb_q3 <= 0;
      end
      else begin
         r_sa_q3 <= r_sa_q2;
         r_sa_q2 <= r_sa_q1;
         r_sa_q1 <= r_sa;
         r_sb_q3 <= r_sb_q2;
         r_sb_q2 <= r_sb_q1;
         r_sb_q1 <= r_sb;
         l_sa_q3 <= l_sa_q2;
         l_sa_q2 <= l_sa_q1;
         l_sa_q1 <= l_sa;
         l_sb_q3 <= l_sb_q2;
         l_sb_q2 <= l_sb_q1;
         l_sb_q1 <= l_sb;
      end
   end

   //-----------------------------------------------------------------------------
   // OLED ctrl
   logic [31:0] oled_dbg_tl, oled_dbg_tr, oled_dbg_bl, oled_dbg_br;
   logic        oled_txd;

   HEX2OLED_module #(.CLK_FREQ(CLK_FREQ))
   oled_inst(.dbg_tl(oled_dbg_tl),
             .dbg_tr(oled_dbg_tr),
             .dbg_bl(oled_dbg_bl),
             .dbg_br(oled_dbg_br),
             .txd(oled_txd),
             .clk(clk200M),
             .rstn(rstn));

   always_comb begin
      oled_dbg_tl = {l_target_rot_v[15:0], l_pulse_width[15:0]}; // [????????????]????????????????????????????????????
      oled_dbg_tr = {r_target_rot_v[15:0], r_pulse_width[15:0]}; // [????????????]????????????????????????????????????
      oled_dbg_bl = l_rot_cnt; // {16'h0, 16'h0};
      oled_dbg_br = r_rot_cnt; // {16'h0, 16'h0};
   end

   //-----------------------------------------------------------------------------
   // counter
   logic [31:0] cnt_r;
   always_ff @(posedge clk200M) begin
      if(!rstn) begin
         cnt_r <= 0;
      end
      else begin
         cnt_r <= cnt_r + 1;
      end
   end

   //----------------------------------------------------------------
   // SW, BTN
   logic [3:0] sw_r, btn_r;
   always_ff @(posedge clk200M) begin
      if(!rstn) begin
         sw_r  <= 0;
         btn_r <= 0;
      end
      if(cnt_r[15:0] == 0) begin
        sw_r  <= sw;
        btn_r <= btn;
      end
   end
   assign btns_tri[3:0] = btn_r;
   assign btns_tri[7:4] = sw_r;
   assign btns_tri[31:8] = 24'd0;

   //----------------------------------------------------------------
   // LED
   logic [3:0] led_r;
   always_comb begin
      led = led_r;
   end

   always_ff @(posedge clk200M) begin
      led_r <= cnt_r[27:24];
   end

   //----------------------------------------------------------------
   // Pmod
   assign ja1  = 1'bz;
   assign ja2  = 1'bz;
   assign ja3  = 1'bz;
   assign ja4  = 1'bz;
   assign ja7  = 1'bz;
   assign ja8  = 1'bz;
   assign ja9  = 1'bz;
   assign ja10 = 1'bz;

   assign jb1  = 1'bz;
   assign jb2  = 1'bz;
   assign jb3  = 1'bz;
   assign jb4  = 1'bz;
   assign jb7  = 1'bz;
   assign jb8  = 1'bz;
   assign jb9  = 1'bz;
   assign jb10 = 1'bz;

   assign jc1  = 1'bz;
   assign jc2  = 1'bz;
   assign jc3  = 1'bz;
   assign jc4  = 1'bz;
   assign jc7  = 1'bz;
   assign jc8  = 1'bz;
   assign jc9  = 1'bz;
   assign jc10 = 1'bz;

   assign jd1  = r_dir;
   assign jd2  = r_pwm;
   assign jd3  = r_sa;
   assign jd4  = r_sb;
   assign jd7  = ~l_dir;
   assign jd8  = l_pwm;
   assign jd9  = l_sb;
   assign jd10 = l_sa;

   assign je1  = 1'bz;
   assign je2  = 1'bz;
   assign je3  = 1'bz;
   assign je4  = 1'bz;
   assign je7  = 1'bz;
   assign je8  = 1'bz;
   assign je9  = 1'bz;
   assign je10 = oled_txd;

endmodule
