#include "main.h"

int main() {
    try {
        ad::Handler handler;
        auto exit_flag = false;
        while(!exit_flag) {
            auto selected_mode = '0';
            std::cout << std::endl << " ---------------- Autonomous Driving Sample Design Top Menu ---------------- " << std::endl;
            std::cout << "1. Launch Linetracer" << std::endl;
            std::cout << "q. Quit" << std::endl << std::endl;
            std::cout << "Please input menu char : ";
            std::cin  >> selected_mode;
            switch(selected_mode) {
                case '1': {
                    std::cout << std::endl << " ---------------- Launch Linetracer ---------------- " << std::endl;
                    handler.run(ad::Handler::Mode::LINETRACE);
                    break;
                }
                case 'q': {
                    exit_flag = true;
                    break;
                }
                default: {
                    break;
                }
            }
        }
    }
    catch(const std::exception& e) {
        std::cout << e.what() << std::endl;
    }
    catch(...) {
        std::cout << "An unexpected exception has occurred" << std::endl;
    }

    return 0;
}
