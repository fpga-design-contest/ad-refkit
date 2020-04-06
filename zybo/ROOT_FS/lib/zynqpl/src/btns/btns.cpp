#include <btns/btns.h>

namespace zynqpl {
    Btns::Btns(const std::string& btns_devname) {
        btns_fd_ = open(("/dev/" + btns_devname).c_str(), O_RDWR | O_SYNC);
        if(!btns_fd_) {
            throw std::runtime_error("could not open device of buttons : " +
                                     std::string(strerror(errno)));
        }
        btns_baseaddr_ = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, btns_fd_, 0);
        if(btns_baseaddr_ == MAP_FAILED) {
            throw std::runtime_error("could not get baseaddr of buttons : " +
                                     std::string(strerror(errno)));
        }
    }

    Btns::~Btns() {
        close(btns_fd_);
        munmap(btns_baseaddr_, 0x10000);
    }

    int Btns::getValue() const {
        return static_cast<int>(REG(btns_baseaddr_, 0));
    }
}
