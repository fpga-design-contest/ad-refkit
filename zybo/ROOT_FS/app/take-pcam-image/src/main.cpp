/**
 *  Take-pcam-image
 *
 *  Copyright (C) 2020 Takefumi Miyoshi.
 *  Authors:
 *      Takefumi Miyoshi <miyo@wasamon.net>
 *
 */

#include "main.h"
using namespace std;

void pcam_test() {

    std::cout << "take_pcam_image" << std::endl;

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

    cv::namedWindow("frame buffer", cv::WINDOW_AUTOSIZE | cv::WINDOW_FREERATIO);

    std::cout << "s : Stop" << std::endl;
    std::cout << "w : write image" << std::endl;
    std::cout << "q : Quit" << std::endl;

    int           write_img_index = 0;
    bool          end_flag        = false;
    while(!end_flag) {
        pcam.fetchFrame(img.data);

        cv::imshow("frame buffer", img);
        auto key = cv::waitKey(100);
        switch(key) {
            case 's': {
                // s : Stop
                while(true) {
                    if(cv::waitKey(0)) {
                        break;
                    }
                }
                break;
            }
            case 'w': {
                // w : Write image
                cv::imwrite("img" + std::to_string(write_img_index) + ".png", img);
                write_img_index++;
                break;
            }
            case 'q': {
                // q : Quit
                end_flag = true;
                break;
            }
            default: {
                break;
            }
        }
    }
    cv::destroyAllWindows();
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
