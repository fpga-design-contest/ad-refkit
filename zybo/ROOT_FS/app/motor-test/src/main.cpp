/**
 *  motor_test:
 *
 *  Copyright (C) 2020 Yuya Kudo.
 *  Authors:
 *      Yuya Kudo <ri0049ee@ed.ritsumei.ac.jp>
 *
 */

#include "main.h"

void motor_test() {
    zynqpl::Motor motor("uio2", "uio0", "uio3", "uio1");
    motor.setPGain(10, zynqpl::motor::ID::LEFT);
    motor.setPGain(10, zynqpl::motor::ID::RIGHT);
    motor.setAngulerVelocity(3.14, zynqpl::motor::ID::LEFT);
    motor.setAngulerVelocity(3.14, zynqpl::motor::ID::RIGHT);
    std::cout << "Left: "  << motor.getRotCount(zynqpl::motor::ID::LEFT) << std::endl;
    std::cout << "Right: " << motor.getRotCount(zynqpl::motor::ID::RIGHT) << std::endl;
    while(true) {
        std::cout << "q: Quit" << std::endl;
        char c;
        std::cin >> c;
        if(c == 'q') break;
    }
    motor.setPGain(0, zynqpl::motor::ID::LEFT);
    motor.setPGain(0, zynqpl::motor::ID::RIGHT);
    motor.setAngulerVelocity(0, zynqpl::motor::ID::LEFT);
    motor.setAngulerVelocity(0, zynqpl::motor::ID::RIGHT);
    std::cout << "Left: "  << motor.getRotCount(zynqpl::motor::ID::LEFT) << std::endl;
    std::cout << "Right: " << motor.getRotCount(zynqpl::motor::ID::RIGHT) << std::endl;
}

int main() {
    motor_test();
    return 0;
}
