cmake_minimum_required(VERSION 3.20)
project(citl_rpi_suite C)

add_executable(rpi_demo  apps/c_hello/main.c)
add_executable(rpi_tests apps/c_hello/test_main.c)

include(CTest)
if(BUILD_TESTING)
  add_test(NAME armhf_qemu
           COMMAND ${CMAKE_SOURCE_DIR}/scripts/run_qemu_armhf.sh ${CMAKE_BINARY_DIR}/rpi_tests)
  add_test(NAME aarch64_qemu
           COMMAND ${CMAKE_SOURCE_DIR}/scripts/run_qemu_aarch64.sh ${CMAKE_BINARY_DIR}/rpi_tests)
endif()
