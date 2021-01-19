/**
 *  PCam-test:
 *
 *  Copyright (C) 2019 Yuya Kudo.
 *  Copyright (C) 2019 Atsushi Takada.
 *  Authors:
 *      Yuya Kudo      <ri0049ee@ed.ritsumei.ac.jp>
 *      Atsushi Takada <ri0051rr@ed.ritsumei.ac.jp>
 *
 */

#include <sys/file.h>

#include "main.h"
using namespace std;

enum class PreimprocMode {
    GRAY,
    BIN,
    EDGE,
    SAT
};

void pcam_test() {

    std::cout << "pcam_test" << std::endl;
    double H[9] = {0.44493910474142623, -0.265170158024246, -23.667274634287185,
                   -0.010483730367221628, 0.03984000976025845, 44.47837644610684,
                   -3.556149627457038e-05, -0.0004076085446486301, 0.4412436729698192};

    zynqpl::PreImProc preimproc("uio4");
    preimproc.setGrayBinThreshold(224);
    preimproc.setHistThreshold(100, 80);
    preimproc.setSatBinThreshold(50);

    zynqpl::Pcam pcam("pcam0",
                      "i2c-0",
                      zynqpl::OV5640_cfg::mode_t::MODE_720P_1280_720_60fps,
                      zynqpl::OV5640_cfg::awb_t::AWB_ADVANCED,
                      V4L2_PIX_FMT_GREY);

    cv::Mat img(cv::Size(pcam.getImageWidth(), pcam.getImageHeight()), CV_8UC1);
    auto img_corrected = img;

    improc::ImageCorrector corrector(img.size(), "/root/app/pcam-test-websocket/data/pcam_calibration_parameter.xml", H);

    PreimprocMode mode            = PreimprocMode::GRAY;
    int           write_img_index = 0;
    bool          end_flag        = false;
    bool          prot_center     = false;
    int lock_fd = open("/root/app/pcam-test-websocket/lock", O_RDWR);
    while(!end_flag) {
        pcam.fetchFrame(img.data);
        img_corrected = img.clone();
        corrector.execute(img, img_corrected);

        // 表示モードの切り替え
        switch(mode) {
            case PreimprocMode::GRAY: {
                break;
            }
            case PreimprocMode::BIN: {
                for(int i = 0; i < img_corrected.size().area(); i++) {
                    img_corrected.data[i] = (img_corrected.data[i] & 0b00000001) ? 0xFF : 0x00;
                }
                break;
            }
            case PreimprocMode::EDGE: {
                for(int i = 0; i < img_corrected.size().area(); i++) {
                    img_corrected.data[i] = (img_corrected.data[i] & 0b00000010) ? 0xFF : 0x00;
                }
                break;
            }
            case PreimprocMode::SAT: {
                for(int i = 0; i < img_corrected.size().area(); i++) {
                    img_corrected.data[i] = (img_corrected.data[i] & 0b00000100) ? 0xFF : 0x00;
                }
                break;
            }
        }

        if(prot_center) {
            cv::circle(img_corrected, cv::Point(img_corrected.cols/2, img_corrected.rows/2), 10, cv::Scalar(255, 255, 255));
        }

        int rc = flock(lock_fd, LOCK_EX);
        cv::imwrite("image.png", img_corrected);
        flock(lock_fd, LOCK_UN);
    }
}

int main() {
    try {
        pcam_test();
    }
    catch(const std::exception& e) {
        std::cout << e.what() << std::endl;
    }
    catch(...) {
        std::cout << "An unexpected exception has occurred" << std::endl;
    }

    return 0;
}
