cmake_minimum_required(VERSION 3.29)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 23)

project(aven VERSION 0.1.0 LANGUAGES CXX)

set(aven_src
    ${CMAKE_SOURCE_DIR}/avenc.cpp
    ${CMAKE_SOURCE_DIR}/util/util.cpp
    ${CMAKE_SOURCE_DIR}/tokenizer/tokenizer.cpp
)

set(aven_inc
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/include
)

add_executable(avenc ${aven_src})

target_include_directories(avenc PUBLIC ${aven_inc})
target_compile_options(avenc PRIVATE
    -Werror
    -Wall
    -Wimplicit-fallthrough
)

target_link_libraries(avenc)
