cmake_minimum_required(VERSION 2.8)
project(ad)

set(CMAKE_CXX_STANDARD 14)

IF(NOT CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE Release)
ENDIF()

MESSAGE("Build type: " ${CMAKE_BUILD_TYPE})

#-- enable output compile_command.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

#-- cmake -DCMAKE_BUILD_TYPE=debug ..
set(CMAKE_CXX_FLAGS_DEBUG   "-O0 -g -MMD -Wall -Wextra -Winit-self")

#-- cmake ..
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -Wall  -O3 -march=native ")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall   -O3 -march=native")

# Check C++14 support
include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
if(COMPILER_SUPPORTS_CXX14)
  add_definitions(-DCOMPILEDWITHC14)
  message(STATUS "Using flag -std=c++14.")
else()
  message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++14 support. Please use a different C++ compiler.")
endif()

find_package(OpenCV 4.0 QUIET)
if(NOT OpenCV_FOUND)
  message(FATAL_ERROR "OpenCV > 4.0 not found.")
endif()

find_package(Threads REQUIRED)

# 自作ライブラリへのパス
set(LIBRARIES_DIR "${PROJECT_SOURCE_DIR}/../../lib")

include_directories(
  ${PROJECT_SOURCE_DIR}/include
  ${LIBRARIES_DIR}/include/improc
  ${LIBRARIES_DIR}/include/zynqpl
  ${LIBRARIES_DIR}/include/control
  ${OpenCV_INCLUDE_DIRS}
  )

link_directories(
  ${LIBRARIES_DIR}
  )

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build)

add_executable(${PROJECT_NAME}
  src/main.cpp
  src/ad/Handler.cpp
  src/ad/WOCalculator/WOCalculator.cpp
  src/ad/LineTracer/LineTracer.cpp
  src/ad/HWController/MotorController/MotorController.cpp
  src/ad/HWController/PcamController/PcamController.cpp
  src/ad/HWController/PcamController/PcamImageCorrector/PcamImageCorrector.cpp
  src/ad/HWController/WebcamController/WebcamController.cpp
  )

target_link_libraries(${PROJECT_NAME}
  ${OpenCV_LIBS}
  Threads::Threads
  zynqpl
  improc
  control
  )
