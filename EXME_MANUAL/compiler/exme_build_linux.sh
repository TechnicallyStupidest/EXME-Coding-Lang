#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
g++ exme_main.cpp exme_manual.cpp -O3 -std=c++17 -DNDEBUG -s -o exme
