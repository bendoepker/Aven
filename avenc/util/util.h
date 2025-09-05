#ifndef UTIL_H
#define UTIL_H

#include <string>

// This brings operations such as std::move into the including scope
#include <utility>

std::string read_entire_file(const std::string&& path, int& failed) noexcept;

#endif //UTIL_H
