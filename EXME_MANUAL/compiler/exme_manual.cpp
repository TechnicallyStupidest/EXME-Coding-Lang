#include "exme_manual.hpp"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <limits>
#include <regex>
#include <sstream>
#include <stdexcept>

namespace exme {
namespace {

std::string trim(std::string s) {
    auto not_space = [](unsigned char c){ return !std::isspace(c); };
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), not_space));
    s.erase(std::find_if(s.rbegin(), s.rend(), not_space).base(), s.end());
    return s;
}

std::string strip_comment(const std::string& line) {
    auto p = line.find("```");
    return p == std::string::npos ? line : line.substr(0, p);
}

std::uint64_t parse_u64(const std::string& s, const std::string& what) {
    if (s.empty()) throw std::runtime_error("missing " + what);
    std::size_t used = 0;
    int base = 10;
    if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) base = 16;
    unsigned long long v = 0;
    try { v = std::stoull(s, &used, base); }
    catch (...) { throw std::runtime_error("invalid " + what + ": " + s); }
    if (used != s.size()) throw std::runtime_error("invalid " + what + ": " + s);
    return static_cast<std::uint64_t>(v);
}

std::vector<std::string> split_fields(const std::string& payload) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : payload) {
        if (c == '\\') {
            if (!trim(cur).empty()) out.push_back(trim(cur));
            cur.clear();
        } else {
            cur.push_back(c);
        }
    }
    if (!trim(cur).empty()) out.push_back(trim(cur));
    return out;
}

std::string field_exact(const std::vector<std::string>& fields, char prefix, bool required=true) {
    std::string found;
    bool seen = false;
    for (const auto& f : fields) {
        if (!f.empty() && f[0] == prefix) {
            if (seen) throw std::runtime_error(std::string("duplicate field ") + prefix);
            seen = true;
            found = f.substr(1);
        }
    }
    if (!seen && required) throw std::runtime_error(std::string("missing field ") + prefix);
    return found;
}

void reject_unknown(const std::vector<std::string>& fields, const std::string& allowed) {
    for (const auto& f : fields) {
        if (f.empty() || allowed.find(f[0]) == std::string::npos)
            throw std::runtime_error("unknown field: " + f);
    }
}

int hex_nibble(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

std::vector<std::uint8_t> parse_hex_bytes(std::string s) {
    std::string clean;
    clean.reserve(s.size());
    for (char c : s) {
        if (std::isspace(static_cast<unsigned char>(c)) || c == '_') continue;
        clean.push_back(c);
    }
    if (clean.size() % 2 != 0) throw std::runtime_error("X field must contain complete bytes");
    std::vector<std::uint8_t> out;
    out.reserve(clean.size()/2);
    for (std::size_t i=0;i<clean.size();i+=2) {
        int hi=hex_nibble(clean[i]), lo=hex_nibble(clean[i+1]);
        if (hi<0 || lo<0) throw std::runtime_error("X field contains non-hex characters");
        out.push_back(static_cast<std::uint8_t>((hi<<4)|lo));
    }
    return out;
}

std::uint8_t parse_fill_byte(const std::string& s) {
    auto b = parse_hex_bytes(s);
    if (b.size() != 1) throw std::runtime_error("F must be exactly one byte, e.g. F00 or FCC");
    return b[0];
}

std::string remove_comments_preserve_lines(const std::string& source) {
    std::stringstream in(source), out;
    std::string line;
    bool first = true;
    while (std::getline(in,line)) {
        if (!first) out << '\n';
        first=false;
        out << strip_comment(line);
    }
    return out.str();
}

std::size_t line_of(const std::string& s, std::size_t pos) {
    return 1 + static_cast<std::size_t>(std::count(s.begin(), s.begin()+static_cast<std::ptrdiff_t>(pos), '\n'));
}

WriteAction parse_write(char kind, const std::string& payload, const std::string& source, std::size_t line) {
    auto fields = split_fields(payload);
    reject_unknown(fields, "OBX");
    auto off = parse_u64(field_exact(fields,'O'), "O offset");
    auto count = parse_u64(field_exact(fields,'B'), "B byte count");
    auto bytes = parse_hex_bytes(field_exact(fields,'X'));
    if (bytes.size() != count) {
        throw std::runtime_error("B says " + std::to_string(count) + " bytes but X contains " + std::to_string(bytes.size()));
    }
    return WriteAction{kind, off, std::move(bytes), source, line};
}

} // namespace

std::string load_with_imports(const std::filesystem::path& file, std::unordered_set<std::string>& seen) {
    auto absolute = std::filesystem::absolute(file).lexically_normal();
    auto key = absolute.string();
    if (seen.count(key)) throw std::runtime_error("recursive/duplicate import: " + key);
    seen.insert(key);

    std::ifstream in(absolute, std::ios::binary);
    if (!in) throw std::runtime_error("cannot open EXME source: " + absolute.string());
    std::stringstream buffer;
    buffer << in.rdbuf();

    std::stringstream src(buffer.str());
    std::stringstream out;
    std::string line;
    std::regex import_re(R"(^\s*~import\s+\"([^\"]+)\"\s*~\s*$)");
    std::smatch m;
    while (std::getline(src,line)) {
        auto no_comment = strip_comment(line);
        if (std::regex_match(no_comment,m,import_re)) {
            auto child = absolute.parent_path() / m[1].str();
            out << load_with_imports(child, seen) << '\n';
        } else {
            out << line << '\n';
        }
    }
    return out.str();
}

Program parse_program(const std::string& source, const std::string& source_name) {
    Program p;
    std::string s = remove_comments_preserve_lines(source);

    // ~file\B4096\F00~
    std::regex file_re(R"(~file\s*\\([^~]+)~)", std::regex::icase);
    for (std::sregex_iterator it(s.begin(),s.end(),file_re), end; it!=end; ++it) {
        if (p.hasFile) throw std::runtime_error("only one ~file...~ directive is allowed");
        auto fields=split_fields((*it)[1].str());
        reject_unknown(fields,"BF");
        p.fileBytes=parse_u64(field_exact(fields,'B'),"file B size");
        p.fill=parse_fill_byte(field_exact(fields,'F'));
        p.hasFile=true;
    }

    // Keep every byte write in exact source order. Later writes intentionally overwrite earlier bytes.
    std::vector<std::pair<std::size_t,WriteAction>> ordered;

    // ~data\O1024\B4\X01020304~
    std::regex data_re(R"(~data\s*\\([^~]+)~)", std::regex::icase);
    for (std::sregex_iterator it(s.begin(),s.end(),data_re), end; it!=end; ++it) {
        auto pos=static_cast<std::size_t>((*it).position());
        auto line=line_of(s,pos);
        ordered.push_back({pos,parse_write('D',(*it)[1].str(),source_name,line)});
    }

    // Executable operations are only W/G/M/J. Their contents are exact bytes.
    std::regex op_re(R"(\*@([WGMJ])\s*<([\s\S]*?)>\$)", std::regex::icase);
    for (std::sregex_iterator it(s.begin(),s.end(),op_re), end; it!=end; ++it) {
        auto pos=static_cast<std::size_t>((*it).position());
        char kind=static_cast<char>(std::toupper(static_cast<unsigned char>((*it)[1].str()[0])));
        auto line=line_of(s,pos);
        ordered.push_back({pos,parse_write(kind,(*it)[2].str(),source_name,line)});
    }
    std::sort(ordered.begin(),ordered.end(),[](const auto& a,const auto& b){return a.first<b.first;});
    for (auto& item:ordered) p.writes.push_back(std::move(item.second));

    if (!p.hasFile) throw std::runtime_error("missing ~file\\B...\\F..~ directive; EXME will not choose a file size for you");

    for (const auto& w : p.writes) {
        if (w.offset > p.fileBytes || w.bytes.size() > p.fileBytes - w.offset) {
            throw std::runtime_error(std::string(1,w.kind) + " write at line " + std::to_string(w.line) + " exceeds manually declared file size");
        }
    }

    return p;
}

void emit_binary(const Program& program, const std::filesystem::path& output) {
    if (program.fileBytes > static_cast<std::uint64_t>(std::numeric_limits<std::size_t>::max()))
        throw std::runtime_error("output file is too large for this host compiler");
    std::vector<std::uint8_t> image(static_cast<std::size_t>(program.fileBytes), program.fill);

    // Source order wins. Overlapping writes are intentional and allowed.
    for (const auto& w : program.writes) {
        std::copy(w.bytes.begin(),w.bytes.end(),image.begin()+static_cast<std::size_t>(w.offset));
    }

    std::ofstream out(output,std::ios::binary|std::ios::trunc);
    if (!out) throw std::runtime_error("cannot create output: " + output.string());
    out.write(reinterpret_cast<const char*>(image.data()),static_cast<std::streamsize>(image.size()));
    if (!out) throw std::runtime_error("failed while writing output: " + output.string());
}

} // namespace exme
