#include "exme_manual.hpp"
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <unordered_set>

int main(int argc, char** argv) {
    try {
        if (argc < 2) {
            std::cerr << "EXME manual compiler\nusage: exme <source.exme> -o <output>\n";
            return 1;
        }
        std::filesystem::path input;
        std::filesystem::path output;
        for (int i=1;i<argc;++i) {
            std::string a=argv[i];
            if (a=="-o") {
                if (++i>=argc) throw std::runtime_error("-o requires an output file");
                output=argv[i];
            } else if (a=="--version") {
                std::cout << "EXME manual 2.0\n";
                return 0;
            } else if (!a.empty() && a[0]=='-') {
                throw std::runtime_error("unknown option: "+a);
            } else if (input.empty()) {
                input=a;
            } else {
                throw std::runtime_error("unexpected argument: "+a);
            }
        }
        if (input.empty()) throw std::runtime_error("missing .exme source file");
        if (input.extension() != ".exme") throw std::runtime_error("EXME source files must use .exme");
        if (output.empty()) throw std::runtime_error("you must provide -o; EXME will not choose an output name for you");

        std::unordered_set<std::string> seen;
        auto source=exme::load_with_imports(input,seen);
        auto program=exme::parse_program(source,input.string());
        exme::emit_binary(program,output);
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "EXME compile error: " << e.what() << '\n';
        return 1;
    }
}
