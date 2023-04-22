#!/usr/bin/env bash

set -euo pipefail

BUILD_DIR=$PWD/build

mkdir -p $BUILD_DIR

# build/mode
mode_path=$BUILD_DIR/mode

mode=${BUILD_MODE:-dev}
echo $mode > $mode_path

# build/janet
janet_path=$BUILD_DIR/janet
cc -rdynamic -O2 -std=c99 -Wall -Wextra -Ijanet -fvisibility=hidden -fPIC janet/janet.c ../janet/src/mainclient/shell.c -o $janet_path -lm -lpthread -lrt -ldl

# build/bauble.jimage
jimage_path=$BUILD_DIR/bauble.jimage

$janet_path -c src/bauble.janet $jimage_path

# build/wasm.js
wasm_path=$BUILD_DIR/wasm.js

extra_flags="-O0"
if [[ $mode == "prod" ]]; then
  extra_flags="-O3 --closure 1"
fi

emcc \
  $extra_flags \
  -o $wasm_path \
  -I janet \
  janet/janet.c \
  src/driver.cpp \
  --embed-file build/bauble.jimage@bauble.jimage \
  --embed-file src/intro.janet@intro.janet \
  -lembind \
  -s "EXPORTED_FUNCTIONS=['_main']" \
  -s "EXPORTED_RUNTIME_METHODS=['FS', 'UTF8ToString']" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s AGGRESSIVE_VARIABLE_ELIMINATION=1 \
  -s MODULARIZE \
  -s EXPORT_ES6 \
  -s SINGLE_FILE
