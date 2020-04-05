#ifndef AD_SAMPLE_SRC_AD_HANDLER_H_
#define AD_SAMPLE_SRC_AD_HANDLER_H_

#include <thread>
#include <mutex>
#include <memory>
#include <utility>

#include <ProcTimer.hpp>
#include <HandlerHelper.hpp>

#include "WOCalculator/WOCalculator.h"
#include "LineTracer/LineTracer.h"
#include "HWController/MotorController/MotorController.h"
#include "HWController/PcamController/PcamController.h"
#include "HWController/WebcamController/WebcamController.h"

namespace ad {
    class Handler {
    public:
        enum class Mode {
            LINETRACE
        };

        Handler();
        ~Handler();

        Handler(const Handler& obj) = delete;
        Handler &operator=(const Handler& obj) = delete;

        void run(const Mode& mode);
    private:
        const std::string HANDLER_PARAM_YAML_PATH = "/data/Handler/param.yaml";

        class DebugParam : public core::YAMLHelper::ParamBase {
        public:
            bool imwrite_mode;

            void read(const cv::FileNode& node) override {
                imwrite_mode = (int)node["imwrite_mode"];
            }
        };

        class ExecutePeriod : public core::YAMLHelper::ParamBase {
        public:
            double wo_calculating;
            double line_tracing;
            double debagging;

            void read(const cv::FileNode& node) override {
                wo_calculating = (double)node["wo_calculating"];
                line_tracing   = (double)node["line_tracing"];
                debagging      = (double)node["debagging"];
            }
        };

        struct AverageTime {
            double th_wo_calculating{0};
            double th_line_tracing{0};
            double th_debagging{0};
            AverageTime() = default;
        };

        template<typename T>
        class ExclusiveObj {
        public:
            T obj;
            void lock() { mtx_.lock(); }
            bool try_lock() { return mtx_.try_lock(); }
            void unlock() { mtx_.unlock(); }
        private:
            std::mutex mtx_;
        };

        const bool x11_is_valid_;

        DebugParam    debug_param_;
        ExecutePeriod exec_period_;
        double        bird_eye_img_ratio_;

        ExclusiveObj<std::unique_ptr<WOCalculator>>     wo_calc_;
        ExclusiveObj<std::unique_ptr<LineTracer>>       line_tracer_;
        ExclusiveObj<std::unique_ptr<MotorController>>  motor_ctrl_;
        ExclusiveObj<std::unique_ptr<PcamController>>   pcam_ctrl_;
        ExclusiveObj<std::unique_ptr<WebcamController>> webcam_ctrl_;

        ExclusiveObj<bool>               run_flag_;
        ExclusiveObj<core::VehicleState> current_state_;
        ExclusiveObj<AverageTime>        average_time_;

        void init();
        void doWOCalculatingWorker();
        void doLineTracingWorker();
        void doDebuggingWorker();
    };
}

#endif /* AD_SAMPLE_SRC_AD_HANDLER_H_ */
