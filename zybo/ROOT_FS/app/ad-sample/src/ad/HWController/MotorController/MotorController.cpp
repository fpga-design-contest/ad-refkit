#include "MotorController.h"

namespace ad {
    MotorController::MotorController() {
        if(std::getenv("AD_SAMPLE_ROOT") == nullptr) {
            throw std::logic_error("[" + std::string(__PRETTY_FUNCTION__) + "] " +
                                   "Please set environment value : $ export AD_SAMPLE_ROOT=<path of project root> ");
        }
        const auto root_path = std::getenv("AD_SAMPLE_ROOT");

        DevNameParam devname_param;
        core::YAMLHelper::readStruct(root_path + HW_PARAM_YAML_PATH, devname_param, "devname");

        motor_ = std::make_unique<zynqpl::Motor>(devname_param.r_motor, devname_param.l_motor,
                                                 devname_param.r_rot, devname_param.l_rot);

        GainParam gain_param;
        core::YAMLHelper::readStruct(root_path + HW_PARAM_YAML_PATH, gain_param, "motor", "gain");
        motor_->setPGain(gain_param.P, zynqpl::motor::ID::RIGHT);
        motor_->setPGain(gain_param.P, zynqpl::motor::ID::LEFT);
    }

    MotorController::~MotorController() {
        setWheelAngularVelocity(core::AngularVelocity());
    }

    void MotorController::setWheelAngularVelocity(const core::AngularVelocity& av) {
        motor_->setAngulerVelocity(av.r, zynqpl::motor::ID::RIGHT);
        motor_->setAngulerVelocity(av.l, zynqpl::motor::ID::LEFT);
    }

    MotorController::MotorCnt MotorController::getCntOfRotaryEncoder() {
        return MotorCnt{motor_->getRotCount(zynqpl::motor::ID::RIGHT), motor_->getRotCount(zynqpl::motor::ID::LEFT)};
    }
}
