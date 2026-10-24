#!/bin/sh
# AirPlay-приёмник под glibc 2.28 (Debian buster) — как на станции (glibc 2.30).
# musl-сборка падает на ядре 4.9 из-за clock_gettime64, поэтому только glibc.
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/bin"; mkdir -p "$OUT"
VER="${SHAIRPORT_VER:-4.3.5}"
docker run --rm --platform linux/arm/v7 -v "$OUT:/out" arm32v7/debian:buster-slim sh -c '
export DEBIAN_FRONTEND=noninteractive
sed -i "s|deb.debian.org/debian|archive.debian.org/debian|g; s|security.debian.org/debian-security|archive.debian.org/debian-security|g" /etc/apt/sources.list
echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99nocheck
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq build-essential autoconf automake libtool pkg-config \
  libasound2-dev libconfig-dev libpopt-dev libssl-dev curl >/dev/null 2>&1
cd /tmp && curl -kfsSL -o sp.tar.gz "https://github.com/mikebrady/shairport-sync/archive/refs/tags/'"$VER"'.tar.gz"
tar xzf sp.tar.gz && cd shairport-sync-'"$VER"'
autoreconf -fi >/dev/null 2>&1
# libconfig и popt на станции отсутствуют — линкуем статически; alsa/ssl есть — динамически
L="-Wl,-Bstatic -lconfig -lpopt -Wl,-Bdynamic -lssl -lcrypto -lasound -lpthread -lm -lrt -ldl"
LIBS="$L" ./configure --with-alsa --without-soxr --with-ssl=openssl --with-tinysvcmdns \
  --without-avahi --without-pulseaudio --without-jack --without-sndio --without-pa \
  --without-convolution --disable-mqtt --disable-dbus --without-metadata CFLAGS="-Os" >/dev/null 2>&1
make -j4 LIBS="$L" >/dev/null 2>&1
strip shairport-sync && cp shairport-sync /out/shairport-sync
'
ls -l "$OUT/shairport-sync"
