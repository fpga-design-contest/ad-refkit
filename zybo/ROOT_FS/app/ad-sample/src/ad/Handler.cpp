#include "Handler.h"

namespace ad {
    Handler::Handler() :
        x11_is_valid_(std::getenv("DISPLAY") != nullptr ? true : false)
    {
        if(std::getenv("AD_SAMPLE_ROOT") == nullptr) {
            throw std::logic_error("[" + std::string(__PRETTY_FUNCTION__) + "] " +
                                   "Please set environment value : $ export AD_SAMPLE_ROOT=<path of project root> ");
        }
        const auto root_path = std::getenv("AD_SAMPLE_ROOT");

        // 各処理の実行周期を読み込む
        core::YAMLHelper::readStruct(root_path + HANDLER_PARAM_YAML_PATH, exec_period_, "ExecutePeriod");

        // デバッグに使用するパラメータを読み込む
        core::YAMLHelper::readStruct(root_path + HANDLER_PARAM_YAML_PATH, debug_param_, "Debug");

        // 路面の俯瞰画像の取得倍率を読み込む
        core::YAMLHelper::read(root_path + HANDLER_PARAM_YAML_PATH, bird_eye_img_ratio_, "BirdEyeImgRatio");

        // 各インスタンスを生成する
        motor_ctrl_.obj  = std::make_unique<MotorController>();
        pcam_ctrl_.obj   = std::make_unique<PcamController>();
        line_tracer_.obj = std::make_unique<LineTracer>();
        webcam_ctrl_.obj = std::make_unique<WebcamController>();
        wo_calc_.obj     = std::make_unique<WOCalculator>();
    }

    Handler::~Handler() {
    }

    void Handler::run(const Mode& mode) {
        std::exception_ptr ep;
        auto gen_th_lambda = [&](auto do_worker) -> auto {
                                 return [&]() -> void {
                                            try {
                                                do_worker();
                                            }
                                            catch(...) {
                                                std::lock_guard<ExclusiveObj<bool>> lock(run_flag_);
                                                run_flag_.obj = false;
                                                ep = std::current_exception();
                                            }
                                        };
                             };

        // BTN2の押下を待機
        std::cout << "It is initialized when the BTN2 is pressed" << std::endl;
        while(true && !ep) {
            // TODO: ZYBOのBTNのAPIを作成する
            // if(<zyboのBTN2が押されたら>)
            if(true) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        // 初期化
        init();

        switch(mode) {
            case Mode::LINETRACE: {
                auto th_wo_calculating = std::thread(gen_th_lambda([&]() -> void { doWOCalculatingWorker(); }));
                auto th_debagging      = std::thread(gen_th_lambda([&]() -> void { doDebuggingWorker(); }));

                // BTN1の押下を待機
                std::cout << "It is started when the BTN1 is pressed"    << std::endl;
                std::cout << "At emergency stop, press the BTN2 to stop" << std::endl;
                while(true && !ep) {
                    // TODO: ZYBOのBTNのAPIを作成する
                    // if(<zyboのBTN1が押されたら>)
                    if(true) break;
                    {
                        std::lock_guard<ExclusiveObj<bool>> lock(run_flag_);
                        if(!run_flag_.obj) break;
                    }
                    std::this_thread::sleep_for(std::chrono::milliseconds(100));
                }

                // Linetracerを起動
                auto th_line_tracing = std::thread(gen_th_lambda([&]() -> void { doLineTracingWorker(); }));

                // 終了を待機
                th_wo_calculating.join();
                th_debagging.join();
                th_line_tracing.join();
            }
        }

        motor_ctrl_.obj->setWheelAngularVelocity(core::AngularVelocity(0.0, 0.0));
        if(ep) {
            std::rethrow_exception(ep);
        }
    }

    void Handler::init() {
        run_flag_.obj = true;
        current_state_.obj = core::VehicleState();
    }

    void Handler::doWOCalculatingWorker() {
        core::ProcTimer           timer(10);
        MotorController::MotorCnt cnt;

        {
            std::lock_guard<ExclusiveObj<std::unique_ptr<MotorController>>> lock_motor(motor_ctrl_);
            cnt = motor_ctrl_.obj->getCntOfRotaryEncoder();

            std::lock_guard<ExclusiveObj<std::unique_ptr<WOCalculator>>> lock_wo(wo_calc_);
            wo_calc_.obj->init(cnt.right, cnt.left);
        }

        while(true) {
            timer.start();
            {
                std::lock_guard<ExclusiveObj<std::unique_ptr<MotorController>>> lock(motor_ctrl_);
                cnt = motor_ctrl_.obj->getCntOfRotaryEncoder();
            }

            {
                std::lock_guard<ExclusiveObj<std::unique_ptr<WOCalculator>>> lock(wo_calc_);
                wo_calc_.obj->update(cnt.right, cnt.left);
            }

            timer.stop();
            {
                std::lock_guard<ExclusiveObj<AverageTime>> lock_avt(average_time_);
                average_time_.obj.th_wo_calculating = timer.getAverageElapsedTime();
                std::lock_guard<ExclusiveObj<bool>> lock_rf(run_flag_);
                if(!run_flag_.obj) break;
            }
            std::this_thread::sleep_for(std::chrono::microseconds((uint32_t)(exec_period_.wo_calculating * 1e6)));
        }
    }

    void Handler::doLineTracingWorker() {
        core::ProcTimer           timer(10);
        core::BirdEyeImg<uint8_t> bin_img;
        core::VehicleState        current_state;

        auto prev_time = std::chrono::system_clock::now();
        while(true) {
            timer.start();
            {
                std::lock_guard<ExclusiveObj<std::unique_ptr<PcamController>>> lock(pcam_ctrl_);
                pcam_ctrl_.obj->updateRoadSurfaceImage(bird_eye_img_ratio_);
                bin_img = pcam_ctrl_.obj->getRoadSurfaceImage(PcamController::ImageType::BIN).clone();
            }

            {
                std::lock_guard<ExclusiveObj<std::unique_ptr<WOCalculator>>> lock_wo(wo_calc_);
                const auto wo = wo_calc_.obj->get(current_state_.obj.t);
                const auto current_time = std::chrono::system_clock::now();

                std::lock_guard<ExclusiveObj<core::VehicleState>> lock_state(current_state_);
                current_state_.obj   += wo;
                current_state_.obj.v  = wo.norm() / std::chrono::duration_cast<std::chrono::microseconds>(current_time - prev_time).count();
                current_state = current_state_.obj;
                prev_time     = current_time;
            }

            {
                std::lock_guard<ExclusiveObj<std::unique_ptr<LineTracer>>> lock(line_tracer_);
                core::AngularVelocity av;
                line_tracer_.obj->calcAngularVelocity(bin_img, current_state, av);
            }

            // TODO: ZYBOのBTNのAPIを作成する
            // if(<zyboのBTN2が押されたら>)
            if(false) {
                std::lock_guard<ExclusiveObj<bool>> lock(run_flag_);
                run_flag_.obj = false;
            }

            timer.stop();
            {
                std::lock_guard<ExclusiveObj<AverageTime>> lock_avt(average_time_);
                average_time_.obj.th_line_tracing = timer.getAverageElapsedTime();
                std::lock_guard<ExclusiveObj<bool>> lock_rf(run_flag_);
                if(!run_flag_.obj) break;
            }
            std::this_thread::sleep_for(std::chrono::microseconds((uint32_t)(exec_period_.line_tracing * 1e6)));
        }
    }

    void Handler::doDebuggingWorker() {
        size_t                          itr = 0;
        core::ProcTimer                 timer(10);
        std::vector<core::VehicleState> trajectory;
        core::BirdEyeImg<uint8_t>       bin_img, edge_img, sat_img;
        cv::Mat                         webcam_img;
        AverageTime                     average_time;

        cv::namedWindow("Online Map", cv::WINDOW_AUTOSIZE | cv::WINDOW_FREERATIO);
        while(true) {
            timer.start();
            {
                std::lock_guard<ExclusiveObj<bool>> lock(run_flag_);
                if(!run_flag_.obj) break;
            }

            if(x11_is_valid_) {
                {
                    std::lock_guard<ExclusiveObj<core::VehicleState>> lock(current_state_);
                    trajectory.push_back(current_state_.obj);
                }

                {
                    std::lock_guard<ExclusiveObj<std::unique_ptr<PcamController>>> lock(pcam_ctrl_);
                    bin_img  = pcam_ctrl_.obj->getRoadSurfaceImage(PcamController::ImageType::BIN).clone();
                    edge_img = pcam_ctrl_.obj->getRoadSurfaceImage(PcamController::ImageType::EDGE).clone();
                    sat_img  = pcam_ctrl_.obj->getRoadSurfaceImage(PcamController::ImageType::SAT).clone();
                }

                {
                    std::lock_guard<ExclusiveObj<std::unique_ptr<WebcamController>>> lock(webcam_ctrl_);
                    webcam_img = webcam_ctrl_.obj->getWebCamImage().clone();
                }

                const auto debug_map = core::HandlerHelper::createCurrentWorld(trajectory, webcam_img, bin_img, edge_img, sat_img);
                if(debug_param_.imwrite_mode) {
                    cv::imwrite("./img" + std::to_string(itr) + ".png", debug_map);
                    itr++;
                }
                cv::imshow("Online Map", debug_map);
                const char key = cv::waitKey(1);
                if(key == 'q') {
                    std::lock_guard<ExclusiveObj<bool>> lock(run_flag_);
                    run_flag_.obj = false;
                }
            }

            timer.stop();
            {
                std::lock_guard<ExclusiveObj<AverageTime>> lock(average_time_);
                average_time_.obj.th_debagging = timer.getAverageElapsedTime();
                average_time = average_time_.obj;
            }

            std::cout << "----------- Elapsed Time -----------" << std::endl;
            std::cout << "WO Calculating  : " << std::setprecision(5) << average_time.th_wo_calculating * 1000 << "ms" << std::endl;
            std::cout << "LineTrace       : " << std::setprecision(5) << average_time.th_line_tracing * 1000 << "ms" << std::endl;
            std::cout << "Debugging       : " << std::setprecision(5) << average_time.th_debagging * 1000 << "ms" << std::endl;
            std::cout << std::endl;
            std::this_thread::sleep_for(std::chrono::microseconds((uint32_t)(exec_period_.debagging * 1e6)));
        }
        cv::destroyAllWindows();
    }
}
