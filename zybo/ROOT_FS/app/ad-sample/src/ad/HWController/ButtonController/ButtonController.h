#ifndef AD_SAMPLE_SRC_AD_HWCONTROLLER_BUTTONCONTROLLER_BUTTONCONTROLLER_H_
#define AD_SAMPLE_SRC_AD_HWCONTROLLER_BUTTONCONTROLLER_BUTTONCONTROLLER_H_

#include <YAMLHelper.hpp>

#include <zynqpl.h>

namespace ad {
    class ButtonController {
    public:
        ButtonController();
        ~ButtonController();

        ButtonController(const ButtonController& obj) = delete;
        ButtonController &operator=(const ButtonController& obj) = delete;

        /**
         *  @brief read button pushed status
         */
        bool pushed(int id);

    private:
        const std::string HW_PARAM_YAML_PATH    = "/data/HWController/param.yaml";

        class DevNameParam : public core::YAMLHelper::ParamBase {
        public:
            std::string btns;

            void read(const cv::FileNode& node) override {
                btns = (std::string)node["btns"];
            }
        };

        std::unique_ptr<zynqpl::Btns> btns_;
    };
}

#endif  /* AD_SAMPLE_SRC_AD_HWCONTROLLER_BUTTONCONTROLLER_BUTTONCONTROLLER_H_ */
