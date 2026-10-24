#!/bin/sh
# Статический fastfetch (musl) под armv7.
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/bin"; mkdir -p "$OUT"
VER="${FASTFETCH_VER:-2.70.0}"
docker run --rm --platform linux/arm/v7 -v "$OUT:/out" alpine:3.20 sh -c '
apk add --no-cache cmake make gcc g++ linux-headers curl tar libdrm-dev >/dev/null 2>&1
cd /tmp && curl -fsSL -o ff.tar.gz "https://github.com/fastfetch-cli/fastfetch/archive/refs/tags/'"$VER"'.tar.gz"
tar xzf ff.tar.gz && cd fastfetch-'"$VER"'
# DRM не отключаем: при -DENABLE_DRM=OFF ломается gpu_linux.c
cmake -B build -DCMAKE_BUILD_TYPE=MinSizeRel -DCMAKE_C_FLAGS="-Wno-error" \
  -DCMAKE_EXE_LINKER_FLAGS="-static -s" \
  -DENABLE_X11=OFF -DENABLE_WAYLAND=OFF -DENABLE_GIO=OFF -DENABLE_DBUS=OFF \
  -DENABLE_VULKAN=OFF -DENABLE_OPENGL=OFF -DENABLE_EGL=OFF -DENABLE_GLX=OFF -DENABLE_OPENCL=OFF \
  -DENABLE_FREETYPE=OFF -DENABLE_RPM=OFF -DENABLE_IMAGEMAGICK7=OFF -DENABLE_CHAFA=OFF >/dev/null 2>&1
cmake --build build -j4 >/dev/null 2>&1
strip build/fastfetch 2>/dev/null
cp build/fastfetch /out/fastfetch
'
ls -l "$OUT/fastfetch"
