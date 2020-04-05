/**
 *  HandlerHelper: fad::Handlerで使用するユーティリティクラス
 *
 *  Copyright (C) 2019 Yuya Kudo.
 *  Copyright (C) 2019 Atsushi Takada.
 *  Authors:
 *      Yuya Kudo      <ri0049ee@ed.ritsumei.ac.jp>
 *      Atsushi Takada <ri0051rr@ed.ritsumei.ac.jp>
 *
 */

#ifndef INCLUDE_HANDLERHELPER_HPP_
#define INCLUDE_HANDLERHELPER_HPP_

#include <algorithm>

#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>

#include <BirdEyeImg.hpp>
#include <VehicleState.hpp>
#include <Util.hpp>

namespace core {
    class HandlerHelper {
    public:
        /**
         *  現状態を表す地図画像を生成する
         */
        static cv::Mat createCurrentWorld(std::vector<core::VehicleState> trajectory,
                                          const cv::Mat&                  webcam_img,
                                          const BirdEyeImg<uint8_t>&      road_bin_img,
                                          const BirdEyeImg<uint8_t>&      road_edge_img,
                                          const BirdEyeImg<uint8_t>&      road_sat_img) {
            const cv::Vec3b COLOR_TRAJECTORY(16, 16, 255);
            const cv::Vec3b COLOR_TRAJECTORY_LINE(32, 32, 224);
            const cv::Vec3b COLOR_ROAD_BIN_IMG(192, 192, 192);
            const cv::Vec3b COLOR_ROAD_EDGE_IMG(16, 224, 16);
            const cv::Vec3b COLOR_ROAD_SAT_IMG(16, 16, 224);

            const auto long_side_pix  = std::max(road_bin_img.map.rows, road_bin_img.map.cols);
            cv::Mat    trajectory_map = cv::Mat::zeros(cv::Size(long_side_pix, long_side_pix), CV_8UC3);

            // 軌跡の描画
            auto max_t_pt = cv::Point2d(0.0, 0.0);
            auto min_t_pt = cv::Point2d(0.0, 0.0);
            for(const auto& t : trajectory) {
                if(max_t_pt.x < t.x) max_t_pt.x = t.x;
                if(max_t_pt.y < t.y) max_t_pt.y = t.y;
                if(t.x < min_t_pt.x) min_t_pt.x = t.x;
                if(t.y < min_t_pt.y) min_t_pt.y = t.y;
            }
            const auto t_normalize_coef = cv::Point2d(trajectory_map.cols / (max_t_pt.x - min_t_pt.x) / 2,
                                                      trajectory_map.rows / (max_t_pt.y - min_t_pt.y) / 2);

            std::vector<cv::Point> cv_pt_trajectory;
            std::vector<std::vector<cv::Point>> cv_pt_trajectories;
            const auto trajectory_offset = cv::Point2d(trajectory.back().x, trajectory.back().y);
            for(const auto& t : trajectory) {
                const auto ptd = cv::Point2d(t.x, t.y) - trajectory_offset;
                const auto pt  = cv::Point(ptd.x * t_normalize_coef.x, ptd.y * t_normalize_coef.y) + cv::Point(trajectory_map.cols / 2, trajectory_map.rows / 2);
                if(0 <= pt.x && pt.x < trajectory_map.cols && 0 <= pt.y && pt.y < trajectory_map.rows) {
                    cv_pt_trajectory.push_back(pt);
                }
                else {
                    if(cv_pt_trajectory.size() != 0) {
                        cv_pt_trajectories.push_back(cv_pt_trajectory);
                        cv_pt_trajectory.clear();
                    }
                }
            }
            cv_pt_trajectories.push_back(cv_pt_trajectory);

            for(const auto& cv_pt_trajectory : cv_pt_trajectories) {
                cv::polylines(trajectory_map, cv_pt_trajectory, false, COLOR_TRAJECTORY_LINE, 1, cv::LINE_AA);
                for(const auto& pt : cv_pt_trajectory) {
                    cv::circle(trajectory_map, pt, 1, COLOR_TRAJECTORY, 1, cv::LINE_AA);
                }
            }

            // 路面の俯瞰画像を着色
            cv::Mat colored_road;
            cv::cvtColor(road_bin_img.map, colored_road, cv::COLOR_GRAY2BGR);
            for(int yi = 0; yi < colored_road.rows; yi++) {
                for(int xi = 0; xi < colored_road.cols; xi++) {
                    auto val = cv::Vec3b(0, 0, 0);
                    if(colored_road.at<cv::Vec3b>(yi, xi) != cv::Vec3b(0, 0, 0)) {
                        val += COLOR_ROAD_BIN_IMG;
                    }
                    if(road_edge_img.map.at<uint8_t>(yi, xi) != 0) {
                        val += COLOR_ROAD_EDGE_IMG;
                    }
                    if(road_sat_img.map.at<uint8_t>(yi, xi) != 0) {
                        val += COLOR_ROAD_SAT_IMG;
                    }
                    colored_road.at<cv::Vec3b>(yi, xi) = val;
                }
            }

            // Webカメラの画像の横幅を路面の俯瞰画像の横幅に合わせる
            cv::Mat scaled_webcam_img;
            const double webcam_scale_ratio = colored_road.cols / (double)webcam_img.cols;
            cv::resize(webcam_img, scaled_webcam_img, cv::Size(), webcam_scale_ratio, webcam_scale_ratio, cv::INTER_CUBIC);

            // 路面の俯瞰画像・Webカメラの画像を地図画像の右側に連結
            cv::Mat combined = cv::Mat::zeros(cv::Size(trajectory_map.cols + std::max(colored_road.cols, scaled_webcam_img.cols),
                                                       std::max(trajectory_map.rows, colored_road.rows + scaled_webcam_img.rows)), CV_8UC3);
            cv::Mat left(combined, cv::Rect(0, 0, trajectory_map.cols, trajectory_map.rows));
            cv::Mat right_top(combined, cv::Rect(trajectory_map.cols, 0, colored_road.cols, colored_road.rows));
            cv::Mat right_bottom(combined, cv::Rect(trajectory_map.cols, colored_road.rows, scaled_webcam_img.cols, scaled_webcam_img.rows));
            trajectory_map.copyTo(left);
            colored_road.copyTo(right_top);
            scaled_webcam_img.copyTo(right_bottom);
            return combined;
        }
    };
}

#endif /* INCLUDE_HANDLERHELPER_HPP_ */
