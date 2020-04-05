/**
 *  LineTracer: ライントレースを実行するクラス
 *
 *  Copyright (C) 2019 Yuya Kudo.
 *  Copyright (C) 2019 Atsushi Takada.
 *  Authors:
 *      Yuya Kudo      <ri0049ee@ed.ritsumei.ac.jp>
 *      Atsushi Takada <ri0051rr@ed.ritsumei.ac.jp>
 *
 */

#ifndef AD_SAMPLE_SRC_AD_LINETRACER_LINETRACER_H_
#define AD_SAMPLE_SRC_AD_LINETRACER_LINETRACER_H_

#include <iostream>
#include <vector>
#include <map>
#include <algorithm>
#include <cstdint>
#include <cmath>

#include <BirdEyeImg.hpp>
#include <VehicleState.hpp>
#include <YAMLHelper.hpp>
#include <AngularVelocity.hpp>

#include <improc.h>
#include <control.h>

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

namespace ad {
    class LineTracer {
        // ラベル番号 -> label_info
        using LabelInfoMap = std::map<uint16_t, improc::Labeling::Info>;

    public:
        class Line {
        public:
            double      rho;
            core::Theta theta;
        };

        LineTracer();
        ~LineTracer();

        LineTracer(const LineTracer& obj) = delete;
        LineTracer &operator=(const LineTracer& obj) = delete;

        // ラインの追跡状態を初期化する
        void init(const uint32_t& line_x_cog = std::numeric_limits<uint32_t>::max());

        // 角速度を導出する
        bool calcAngularVelocity(const core::BirdEyeImg<uint8_t>& bird_eye_img,
                                 const core::VehicleState&        current_state,
                                 core::AngularVelocity&           av);

        // ラインをy方向にサンプリングした座標を取得する
        const std::vector<cv::Point2d>& getLineSamplingPoints() const;

        // ラインを取得する
        Line getLine() const;

        // ラインのX方向の重心を取得する
        double getLineXCOG() const;

    private:
        const std::string LINE_TRACER_PARAM_YAML_PATH = "/data/LineTracer/param.yaml";
        const std::string MOTOR_PARAM_YAML_PATH       = "/data/Common/motor.yaml";

        class LineTracerParam : public core::YAMLHelper::ParamBase {
        public:
            double  distance_from_line;
            double  vehicle_target_velocity;
            double  error_weight;
            double  line_width;
            uint8_t num_line_samp;
            double  k;
            double  area_hthr;
            double  area_lthr;
            double  height_thr;
            double  cog_torelant_range;
            double  width_torelant_range;

            void read(const cv::FileNode& node) override {
                distance_from_line      = (double)node["distance_from_line"];
                vehicle_target_velocity = (double)node["vehicle_target_velocity"];
                error_weight            = (double)node["error_weight"];
                line_width              = (double)node["line_width"];
                num_line_samp           = (int)node["num_line_samp"];
                k                       = (double)node["k"];
                area_hthr               = (double)node["area_hthr"];
                area_lthr               = (double)node["area_lthr"];
                height_thr              = (double)node["height_thr"];
                cog_torelant_range      = (double)node["cog_torelant_range"];
                width_torelant_range    = (double)node["width_torelant_range"];
            }
        };

        class PIDParam : public core::YAMLHelper::ParamBase {
        public:
            double P_gain;
            double I_gain;
            double D_gain;

            void read(const cv::FileNode& node) override {
                P_gain = (double)node["P_gain"];
                I_gain = (double)node["I_gain"];
                D_gain = (double)node["D_gain"];
            }
        };

        class MotorParam : public core::YAMLHelper::ParamBase {
        public:
            double one_rotation_pulse;
            double one_rotation_dist;
            double tire_tread;

            void read(const cv::FileNode& node) override {
                one_rotation_pulse = (double)node["one_rotation_pulse"];
                one_rotation_dist  = (double)node["one_rotation_dist"];
                tire_tread         = (double)node["tire_tread"];
            }
        };

        LineTracerParam tracer_param_;
        MotorParam      m_param_;

        std::unique_ptr<control::PID> pid_ctrl_;

        // 追跡しているラインのx方向の重心
        double prev_line_x_cog_;

        // 追跡しているラインの幅
        double prev_line_width_;

        // 追跡しているラインの高さ
        double prev_line_height_;

        // ラインをy方向にサンプリングした座標
        std::vector<cv::Point2d> line_samp_points_;

        // 追跡しているライン
        Line line_;

        // ラベル画像
        core::BirdEyeImg<uint8_t> label_img_;

        // ラインを含む連結成分を推定する
        uint8_t estimateLineLabel(const LabelInfoMap& label_info_map);

        // ラインのサンプリング・停止線の検出を行う
        void samplingLine(LabelInfoMap&  label_info_map,
                          const uint8_t& line_label);

        // 最小二乗法でラインの傾きを算出する
        bool estimateLine();
    };
}

#endif /* AD_SAMPLE_SRC_AD_LINETRACER_LINETRACER_H_ */

