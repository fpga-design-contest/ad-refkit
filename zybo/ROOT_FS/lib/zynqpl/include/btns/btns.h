/*
  ------------------------------------
  (C) Takefumi MIYOSHI, Apr. 2020. All rights reserved.
  ------------------------------------
  read buttons status
  ------------------------------------
*/

#ifndef ZYNQPL_INCLUDE_BTNS_BTNS_H_
#define ZYNQPL_INCLUDE_BTNS_BTNS_H_

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
    namespace btns {
    }

    class Btns {
    public:
        Btns(const std::string& btns_devname);
        ~Btns();

        int getValue() const;
    private:
        int btns_fd_;
        void* btns_baseaddr_;
    };
} /* namespace zynqpl */

#endif /* ZYNQPL_INCLUDE_BTNS_BNTS_H_ */
