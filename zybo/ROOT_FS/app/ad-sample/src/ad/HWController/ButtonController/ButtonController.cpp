#include "ButtonController.h"

namespace ad {
    ButtonController::ButtonController() {
        const auto root_path = std::getenv("AD_SAMPLE_ROOT");
        DevNameParam devname_param;
        core::YAMLHelper::readStruct(root_path + HW_PARAM_YAML_PATH, devname_param, "devname");
        btns_ = std::make_unique<zynqpl::Btns>(devname_param.btns);
    }

    ButtonController::~ButtonController() {
    }

    bool ButtonController::pushed(const int id) {
        int mask = 1 << id;
        return ((btns_->getValue() & mask) == 0) ? false : true;
    }
}
