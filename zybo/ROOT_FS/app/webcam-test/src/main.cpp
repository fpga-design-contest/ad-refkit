/**
 *  webcam-test:
 *
 *  Copyright (C) 2019 Yuya Kudo.
 *  Copyright (C) 2019 Atsushi Takada.
 *  Authors:
 *      Yuya Kudo      <ri0049ee@ed.ritsumei.ac.jp>
 *      Atsushi Takada <ri0051rr@ed.ritsumei.ac.jp>
 *
 */

#include "main.h"

void webcam_test() {
    std::cout << "webcam_test()" << std::endl;
    cv::VideoCapture cap(0);
    if(!cap.isOpened()) {
        return;
    }

    //cap.set(cv::CV_CAP_PROP_FRAME_WIDTH, 640);
    //cap.set(cv::CV_CAP_PROP_FRAME_HEIGHT, 480);
    cap.set(cv::CAP_PROP_FRAME_WIDTH, 640);
    cap.set(cv::CAP_PROP_FRAME_HEIGHT, 480);
    improc::ImageCorrector corr(cv::Size(640, 480), "../data/VGA/calib_param.xml");

    cv::Mat frame, corrected_frame;

    std::cout << "cap.read(frame)" << std::endl;
    cap.read(frame);
    corrected_frame = frame.clone();

    int index = 0;
    while(cap.read(frame)) {
        std::cout << "cap.read(frame) loop" << std::endl;
        corr.execute(frame, corrected_frame);
        cv::imshow("corrected_frame", corrected_frame);

        const int key = cv::waitKey(1);
        if(key == 'q') {
            break;
        }
        else if(key == 's') {
            std::cout << "write image as \"img" + std::to_string(index) + ".png\"" << std::endl;
            cv::imwrite("img" + std::to_string(index) + ".png", corrected_frame);
            index++;
        }
    }
    cv::destroyAllWindows();
}

int main() {
    try {
        webcam_test();
    }
    catch(const std::exception& e) {
        std::cout << e.what() << std::endl;
    }
    catch(...) {
        std::cout << "An unexpected exception has occurred" << std::endl;
    }
    return 0;
}
