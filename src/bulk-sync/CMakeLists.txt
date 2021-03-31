# Needs to be changed appropriately
cmake_minimum_required(VERSION 3.10 FATAL_ERROR)
project(bulk-sync CXX)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -W -Wall -Wextra -Wpedantic -std=gnu++17")

set(CMAKE_CXX_STANDARD 17)

find_package(PkgConfig REQUIRED)

pkg_check_modules(RAFT_LIB REQUIRED IMPORTED_TARGET raftlib)
# pkg_check_modules(VL_LIB REQUIRED IMPORTED_TARGET libvl)

add_executable(bulk-sync main.cpp)
target_link_libraries(bulk-sync PUBLIC PkgConfig::RAFT_LIB)
# target_link_libraries(bulk-sync PUBLIC PkgConfig::VL_LIB)
