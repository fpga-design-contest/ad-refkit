/**
 *  motor_test:
 *
 *  Copyright (C) 2020 Yuya Kudo.
 *  Authors:
 *      Yuya Kudo <ri0049ee@ed.ritsumei.ac.jp>
 *
 */

#include "main.h"
#include <iostream>
#include <string>

void motor_test(double lgain, double rgain, double languler, double ranguler, int sec) {
    zynqpl::Motor motor("uio2", "uio0", "uio3", "uio1");
    motor.setPGain(lgain, zynqpl::motor::ID::LEFT);
    motor.setPGain(rgain, zynqpl::motor::ID::RIGHT);
    motor.setAngulerVelocity(languler, zynqpl::motor::ID::LEFT);
    motor.setAngulerVelocity(ranguler, zynqpl::motor::ID::RIGHT);
    sleep(sec);
    motor.setPGain(0, zynqpl::motor::ID::LEFT);
    motor.setPGain(0, zynqpl::motor::ID::RIGHT);
    motor.setAngulerVelocity(0, zynqpl::motor::ID::LEFT);
    motor.setAngulerVelocity(0, zynqpl::motor::ID::RIGHT);
}

int main(int argc, char** argv) {
    double lgain = 10.0;
    double rgain = 10.0;
    double languler = 8.0;
    double ranguler = 8.0;
    int sec = 5;
    if(argc >= 6){
       lgain = std::stod(argv[1], 0); 
       rgain = std::stod(argv[2], 0); 
       languler = std::stod(argv[3], 0); 
       ranguler = std::stod(argv[4], 0); 
       sec = std::stoi(argv[5], 0); 
    }
    std::cout << "motor test: " << lgain << " " << rgain << " " << languler << " " << ranguler << " " << sec << std::endl;
    
    try {
        motor_test(lgain, rgain, languler, ranguler, sec);
    }
    catch(const std::exception& e) {
        std::cout << e.what() << std::endl;
    }
    catch(...) {
        std::cout << "An unexpected exception has occurred" << std::endl;
    }
    return 0;
}
