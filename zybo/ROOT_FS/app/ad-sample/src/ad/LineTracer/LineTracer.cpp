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

#include "LineTracer.h"

namespace ad {
    LineTracer::LineTracer() {
        if(std::getenv("AD_SAMPLE_ROOT") == nullptr) {
            throw std::logic_error("[" + std::string(__PRETTY_FUNCTION__) + "] " +
                                   "Please set environment value : $ export AD_SAMPLE_ROOT=<path of project root> ");
        }
        const auto root_path = std::getenv("AD_SAMPLE_ROOT");

        core::YAMLHelper::readStruct(root_path + LINE_TRACER_PARAM_YAML_PATH, tracer_param_, "Basis");
        core::YAMLHelper::readStruct(root_path + MOTOR_PARAM_YAML_PATH, m_param_, "Motor");

        PIDParam pid_param;
        core::YAMLHelper::readStruct(root_path + LINE_TRACER_PARAM_YAML_PATH, pid_param, "PID");
        pid_ctrl_ = std::make_unique<control::PID>(pid_param.P_gain, pid_param.I_gain, pid_param.D_gain, tracer_param_.vehicle_target_velocity);
    }

    LineTracer::~LineTracer() {
    }

    void LineTracer::init(const uint32_t& line_x_cog) {
        line_samp_points_.clear();
        pid_ctrl_->init();

        if(line_x_cog == std::numeric_limits<uint32_t>::max()) {
            prev_line_x_cog_ = tracer_param_.distance_from_line;
        }
        else {
            prev_line_x_cog_ = line_x_cog;
        }

        prev_line_width_ = tracer_param_.line_width;
        line_            = Line();
    }

    bool LineTracer::calcAngularVelocity(const core::BirdEyeImg<uint8_t>& bird_eye_img,
                                         const core::VehicleState&        current_state,
                                         core::AngularVelocity&           av) {
        // PID制御器を用いて目標速度を導出
        pid_ctrl_->updete(current_state.v);
        const auto velocity = pid_ctrl_->getOutValue();

        // ラベリング
        LabelInfoMap label_info_map;
        label_img_.ratio  = bird_eye_img.ratio;
        improc::Labeling::execute(bird_eye_img.map, label_img_.map, label_info_map);

        // ライン領域を推測
        const auto line_label = estimateLineLabel(label_info_map);
        if(line_label == 0) return false;

        // 状態を更新
        prev_line_x_cog_ = label_info_map[line_label].cog * label_img_.ratio;
        prev_line_width_ = label_info_map[line_label].area * std::pow(label_img_.ratio, 2) /
            (double)(label_info_map[line_label].end.y - label_info_map[line_label].begin.y) * label_img_.ratio;

        // サンプリング処理
        samplingLine(label_info_map, line_label);

        // 回帰直線を導出
        estimateLine();

        // 回帰直線から左右のモータの角速度を導出
        const auto dist_error  = (bird_eye_img.getRealWidth() / 2 + bird_eye_img.offset.y) - (tracer_param_.distance_from_line + line_samp_points_.front().x);
        const auto theta_error = (core::PI / 4 - line_.theta.get());

        // 正規化してそれっぽい重みを導出し、フィードバック制御器で求めた速度にかける
        const auto rate = tracer_param_.error_weight * ((dist_error / label_img_.getRealWidth() + theta_error / core::PI) / 2.0);

        const auto r_c = (0 < rate) ? 1.0 - rate : 1.0;
        const auto l_c = (rate < 0) ? 1.0 + rate : 1.0;

        av.r = (velocity / m_param_.one_rotation_dist) * r_c;
        av.l = (velocity / m_param_.one_rotation_dist) * l_c;

        return true;
    }

    const std::vector<cv::Point2d>& LineTracer::getLineSamplingPoints() const {
        return line_samp_points_;
    }

    LineTracer::Line LineTracer::getLine() const {
        return line_;
    }

    double LineTracer::getLineXCOG() const {
        return prev_line_x_cog_;
    }

    uint8_t LineTracer::estimateLineLabel(const LabelInfoMap& label_info_map) {
        uint8_t line_label = 0;

        // 各ラベルのx方向の重心、高さと面積の比(ライン幅)、それらの前状態から推定する
        auto max_eval_value = 0.0;
        for(const auto& label_info : label_info_map) {
            // 条件1 : 面積
            const auto label_area = label_info.second.area * std::pow(label_img_.ratio, 2);
            if(tracer_param_.area_lthr <= label_area && label_area < tracer_param_.area_hthr) {
                // 条件2 : 高さ
                const auto label_height = (label_info.second.end.y - label_info.second.begin.y) * label_img_.ratio;
                if(tracer_param_.height_thr < label_height) {
                    // 条件3 : 重心のブレ
                    const auto cog_diff = std::abs(prev_line_x_cog_ - label_info.second.cog * label_img_.ratio);
                    if(cog_diff < tracer_param_.cog_torelant_range) {
                        // 条件4 : ライン幅のブレ
                        const auto width_diff = std::abs(prev_line_width_ - label_area / label_height);
                        if(width_diff < tracer_param_.width_torelant_range) {
                            // 評価関数 eval_value = (1 - k)(1 - COG_DIFF/cog_torelant_range) + k(1 - WIDTH_DIFF/width_torelant_range)
                            const auto cog_eval_value   = (1 - tracer_param_.k) * (1 - (cog_diff / (double)(tracer_param_.cog_torelant_range)));
                            const auto width_eval_value = tracer_param_.k * (1 - (width_diff / tracer_param_.width_torelant_range));
                            if(max_eval_value < cog_eval_value + width_eval_value) {
                                max_eval_value = cog_eval_value + width_eval_value;
                                line_label     = label_info.first;
                            }
                        }
                    }
                }
            }
        }
        return line_label;
    }

    void LineTracer::samplingLine(LabelInfoMap&  label_info_map,
                                  const uint8_t& line_label) {
        line_samp_points_.clear();

        // 対象のラベル領域の高さを導出
        const auto line_height_pix = label_info_map[line_label].end.y - label_info_map[line_label].begin.y;

        // y方向のサンプリング間隔を導出
        const auto y_sample_interval = std::ceil(line_height_pix / (double)(tracer_param_.num_line_samp));

        // 対象のラベル領域からサンプリングを行う
        std::vector<cv::Point> unvalidated_line_samp_points;
        for(int yi = label_info_map[line_label].begin.y; yi < label_info_map[line_label].end.y; yi+=y_sample_interval) {
            // x方向に連続する領域の開始座標と連続数
            std::vector<std::pair<int, int>> line_x_continue_v;
            line_x_continue_v.reserve(10);

            auto line_continue_flag = false;
            for(int xi = label_info_map[line_label].begin.x; xi < label_info_map[line_label].end.x; xi++) {
                if(label_img_.map.at<uint8_t>(yi, xi) == line_label) {
                    if(!line_continue_flag) {
                        line_x_continue_v.emplace_back(xi, 1);
                        line_continue_flag = true;
                    }
                    else {
                        line_x_continue_v.back().second++;
                    }
                }
                else {
                    line_continue_flag = false;
                }
            }

            // 最も左の連続領域をサンプリング点として記録する
            unvalidated_line_samp_points.emplace_back(line_x_continue_v[0].first + line_x_continue_v[0].second / 2, yi);
        }

        // サンプリング点のバリデーション
        auto point_index = 0;
        for(const auto& unvalidated_line_samp_point : unvalidated_line_samp_points) {
            const auto bef_x = unvalidated_line_samp_points[point_index - 1].x;
            const auto aft_x = unvalidated_line_samp_points[point_index + 1].x;
            const auto bef_aft_avg = (bef_x + aft_x) / 2;

            if(bef_aft_avg - (int)label_img_.getCorrespondPixNum(prev_line_width_) <= unvalidated_line_samp_point.x &&
               unvalidated_line_samp_point.x <= bef_aft_avg + (int)label_img_.getCorrespondPixNum(prev_line_width_)) {
                line_samp_points_.emplace_back(unvalidated_line_samp_point.x * label_img_.ratio,
                                               unvalidated_line_samp_point.y * label_img_.ratio);
            }
            point_index++;
        }
    }

    bool LineTracer::estimateLine() {
        const auto& nof_points = line_samp_points_.size();
        if(nof_points == 0) return false;

        // y方向から回帰直線を求める
        // 回帰系数 = 共分散 / yの分散
        // a = ∑(x - x_average)(y - y_average) / ∑(y - y_average)^2
        auto x_sum = 0.0;
        auto y_sum = 0.0;
        for(const auto& line_samp_point : line_samp_points_) {
            x_sum += line_samp_point.x;
            y_sum += line_samp_point.y;
        }
        const auto x_average = x_sum / nof_points;
        const auto y_average = y_sum / nof_points;

        auto sq_deviation_sum = 0.0;
        for(const auto& line_samp_point : line_samp_points_) {
            sq_deviation_sum += (line_samp_point.y - y_average)*(line_samp_point.y - y_average);
        }
        const auto y_variance = sq_deviation_sum / nof_points;

        auto variance_product_sum = 0.0;
        for(const auto& line_samp_point : line_samp_points_) {
            variance_product_sum += (line_samp_point.x - x_average) * (line_samp_point.y - y_average);
        }
        const auto covariance  = variance_product_sum / nof_points;
        const auto inclination = covariance / y_variance;
        const auto intercept   = x_average - inclination * y_average;

        line_.rho   = std::fabs(intercept) / std::sqrt(inclination*inclination + 1);
        line_.theta = core::Theta(std::atan(inclination));
        return true;
    }
}
