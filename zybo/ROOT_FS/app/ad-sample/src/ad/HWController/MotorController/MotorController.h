#ifndef AD_SAMPLE_SRC_AD_HWCONTROLLER_MOTORCONTROLLER_MOTORCONTROLLER_H_
#define AD_SAMPLE_SRC_AD_HWCONTROLLER_MOTORCONTROLLER_MOTORCONTROLLER_H_

#include <WheelOdometry.hpp>
#include <YAMLHelper.hpp>
#include <AngularVelocity.hpp>

#include <zynqpl.h>

namespace ad {
    class MotorController {
    public:
        struct MotorCnt {
            int right;
            int left;
        };

        MotorController();
        ~MotorController();

        MotorController(const MotorController& obj) = delete;
        MotorController &operator=(const MotorController& obj) = delete;

        /**
         *  @brief モータの角速度を設定する
         */
        void setWheelAngularVelocity(const core::AngularVelocity& av);

        /**
         *  @brief 左右のモータに付属しているロータリーエンコーダのカウンタ値を取得する
         */
        MotorCnt getCntOfRotaryEncoder();

    private:
        const std::string HW_PARAM_YAML_PATH    = "/data/HWController/param.yaml";

        class DevNameParam : public core::YAMLHelper::ParamBase {
        public:
            std::string r_motor;
            std::string l_motor;
            std::string r_rot;
            std::string l_rot;

            void read(const cv::FileNode& node) override {
                r_motor = (std::string)node["r_motor"];
                l_motor = (std::string)node["l_motor"];
                r_rot   = (std::string)node["r_rot"];
                l_rot   = (std::string)node["l_rot"];
            }
        };

        class GainParam : public core::YAMLHelper::ParamBase {
        public:
            double P;

            void read(const cv::FileNode& node) override {
                P = (double)node["P"];
            }
        };

        std::unique_ptr<zynqpl::Motor> motor_;
    };
}

#endif  /* AD_SAMPLE_SRC_AD_HWCONTROLLER_MOTORCONTROLLER_MOTORCONTROLLER_H_ */
