#include "util.h"
#include <fstream>
#include <filesystem>
#include <print>

std::string read_entire_file(const std::string&& path, int& failed) noexcept {
    std::error_code ec;
    auto length = std::filesystem::file_size(path, ec);
    if(ec.value()) {
        std::print("{}\n", ec.message());
        failed = 1;
        return {};
    }
    std::string out(length, 0);
    std::ifstream in(path);
    in.read(&out[0], length);
    in.close();
    failed = 0;
    return out;
}
