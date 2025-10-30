# CMake generated Testfile for 
# Source directory: /mnt/c/00 HENOSIS CODING PROJECTS/citl-raspi-starter
# Build directory: /mnt/c/00 HENOSIS CODING PROJECTS/citl-raspi-starter/build-rpi
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test([=[armhf_qemu]=] "/mnt/c/00 HENOSIS CODING PROJECTS/citl-raspi-starter/scripts/run_qemu_armhf.sh" "/mnt/c/00 HENOSIS CODING PROJECTS/citl-raspi-starter/build-rpi/rpi_tests")
set_tests_properties([=[armhf_qemu]=] PROPERTIES  _BACKTRACE_TRIPLES "/mnt/c/00 HENOSIS CODING PROJECTS/citl-raspi-starter/CMakeLists.txt;7;add_test;/mnt/c/00 HENOSIS CODING PROJECTS/citl-raspi-starter/CMakeLists.txt;0;")
