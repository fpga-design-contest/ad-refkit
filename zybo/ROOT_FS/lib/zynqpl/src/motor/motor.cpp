#include <motor/motor.h>

namespace zynqpl {
    Motor::Motor(const std::string& motor_r_devname,
                 const std::string& motor_l_devname,
                 const std::string& rot_r_devname,
                 const std::string& rot_l_devname) {
        motor_r_fd_ = open(("/dev/" + motor_r_devname).c_str(), O_RDWR | O_SYNC);
        if(!motor_r_fd_) {
            throw std::runtime_error("could not open device of right motor : " +
                                     std::string(strerror(errno)));
        }
        motor_l_fd_ = open(("/dev/" + motor_l_devname).c_str(), O_RDWR | O_SYNC);
        if(!motor_l_fd_) {
            throw std::runtime_error("could not open device of left motor : " +
                                     std::string(strerror(errno)));
        }
        rot_r_fd_ = open(("/dev/" + rot_r_devname).c_str(), O_RDWR | O_SYNC);
        if(!rot_r_fd_) {
            throw std::runtime_error("could not open device of right p controller : " +
                                     std::string(strerror(errno)));
        }
        rot_l_fd_ = open(("/dev/" + rot_l_devname).c_str(), O_RDWR | O_SYNC);
        if(!rot_l_fd_) {
            throw std::runtime_error("could not open device of left p controller : " +
                                     std::string(strerror(errno)));
        }
        motor_r_baseaddr_ = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, motor_r_fd_, 0);
        if(motor_r_baseaddr_ == MAP_FAILED) {
            throw std::runtime_error("could not get baseaddr of right motor : " +
                                     std::string(strerror(errno)));
        }
        motor_l_baseaddr_ = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, motor_l_fd_, 0);
        if(motor_l_baseaddr_ == MAP_FAILED) {
            throw std::runtime_error("could not get baseaddr of left motor : " +
                                     std::string(strerror(errno)));
        }
        rot_r_baseaddr_ = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, rot_r_fd_, 0);
        if(rot_r_baseaddr_ == MAP_FAILED) {
            throw std::runtime_error("could not get baseaddr of right p controller : " +
                                     std::string(strerror(errno)));
        }
        rot_l_baseaddr_ = mmap(NULL, 0x10000, PROT_READ | PROT_WRITE, MAP_SHARED, rot_l_fd_, 0);
        if(rot_l_baseaddr_ == MAP_FAILED) {
            throw std::runtime_error("could not get baseaddr of left p controller : " +
                                     std::string(strerror(errno)));
        }
    }

    Motor::~Motor() {
        close(motor_r_fd_);
        close(motor_l_fd_);
        close(rot_r_fd_);
        close(rot_l_fd_);
        munmap(motor_r_baseaddr_, 0x10000);
        munmap(motor_l_baseaddr_, 0x10000);
        munmap(rot_r_baseaddr_, 0x10000);
        munmap(rot_l_baseaddr_, 0x10000);
    }

    void Motor::setAngulerVelocity(const double&    anguler_velocity,
                                   const motor::ID& id) const {
        uint32_t data = 0;
        data |= static_cast<int>(anguler_velocity * 256);
        REG(id == motor::ID::LEFT ? motor_l_baseaddr_ : motor_r_baseaddr_, motor::OFFSET_VELOCITY) = data;
    }

    void Motor::setPGain(const double&    p_gain,
                         const motor::ID& id) const {
        uint32_t data = 0;
        data |= static_cast<int>(p_gain * 256);
        REG(id == motor::ID::LEFT ? motor_l_baseaddr_ : motor_r_baseaddr_, motor::OFFSET_PWM_GAIN) = data;
    }

    int Motor::getRotCount(const motor::ID& id) const {
        return static_cast<int>(REG(id == motor::ID::LEFT ? rot_l_baseaddr_ : rot_r_baseaddr_, motor::OFFSET_ROT_CNT));
    }
}
