cmake_minimum_required(VERSION 3.0.0)
project(Proyecto VERSION 0.1.0 LANGUAGES C)

include(CTest)
enable_testing()

add_executable(Proyecto main.cu)

enable_language(CUDA)
set(CPACK_PROJECT_NAME ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
include(CPack)

find_package(GDAL CONFIG REQUIRED)
target_link_libraries(Proyecto PRIVATE GDAL::GDAL)