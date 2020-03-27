/*
  ------------------------------------
  (C) Kudo Yuya, Oct. 2018. All rights reserved.
  Last Modified 2018-10-23
  ------------------------------------
  モータ制御クラス
  ------------------------------------
*/

#ifndef ZYNQPL_INCLUDE_MOTOR_MOTOR_H_
#define ZYNQPL_INCLUDE_MOTOR_MOTOR_H_

#include <iostream>
#include <string>
#include <utility>
#include <stdexcept>
#include <cstring>
#include <cstdint>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#define REG(base, offset) *((volatile uint32_t*)((uintptr_t)(base) + (offset)))

namespace zynqpl {
    namespace motor {
        enum class ID { LEFT, RIGHT };

        const uint32_t OFFSET_VELOCITY = 0x0;
        const uint32_t OFFSET_PWM_GAIN = 0x8;
        const uint32_t OFFSET_ROT_CNT  = 0x0;
    }

    class Motor {
    public:
        Motor(const std::string& motor_r_devname,
              const std::string& motor_l_devname,
              const std::string& rot_r_devname,
              const std::string& rot_l_devname);
        ~Motor();

        void setAngulerVelocity(const double&    anguler_velocity,
                                const motor::ID& id) const;
        void setPGain(const double&    p_gain,
                      const motor::ID& id) const;
        int getRotCount(const motor::ID& id) const;
    private:
        int motor_r_fd_, motor_l_fd_, rot_r_fd_, rot_l_fd_;
        void* motor_l_baseaddr_;
        void* motor_r_baseaddr_;
        void* rot_l_baseaddr_;
        void* rot_r_baseaddr_;
    };
} /* namespace zynqpl */

#endif /* ZYNQPL_INCLUDE_MOTOR_MOTOR_H_ */
