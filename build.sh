#!/usr/bin/env bash

set -euo pipefail

BUILD_DIR=$PWD/build

mkdir -p $BUILD_DIR

# build/mode
outpath=$BUILD_DIR/mode

mode=${BUILD_MODE:-dev}
echo $mode > $outpath

# build/bauble.jimage
outpath=$BUILD_DIR/bauble.jimage

janet -c src/bauble.janet $outpath

# build/wasm.js
outpath=$BUILD_DIR/wasm.js

extra_flags="-O0"
if [[ $mode == "prod" ]]; then
  extra_flags="-O3 --closure 1"
fi

emcc \
  $extra_flags \
  -o $outpath \
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
