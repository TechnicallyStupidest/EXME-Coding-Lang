#pragma once
#include <cstdint>
#include <filesystem>
#include <string>
#include <unordered_set>
#include <vector>

namespace exme {

struct WriteAction {
    char kind = 'D';
    std::uint64_t offset = 0;
    std::vector<std::uint8_t> bytes;
    std::string source;
    std::size_t line = 0;
};

struct Program {
    bool hasFile = false;
    std::uint64_t fileBytes = 0;
    std::uint8_t fill = 0;
    std::vector<WriteAction> writes;
};

std::string load_with_imports(const std::filesystem::path& file, std::unordered_set<std::string>& seen);
Program parse_program(const std::string& source, const std::string& source_name);
void emit_binary(const Program& program, const std::filesystem::path& output);

} // namespace exme
