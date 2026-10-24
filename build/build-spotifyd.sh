#!/bin/sh
# Spotify Connect (spotifyd) под glibc 2.28. Долгая сборка: Rust + librespot.
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/bin"; mkdir -p "$OUT"
VER="${SPOTIFYD_VER:-0.4.1}"
docker run --rm --platform linux/arm/v7 -v "$OUT:/out" arm32v7/debian:buster-slim sh -c '
export DEBIAN_FRONTEND=noninteractive
sed -i "s|deb.debian.org/debian|archive.debian.org/debian|g; s|security.debian.org/debian-security|archive.debian.org/debian-security|g" /etc/apt/sources.list
echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99nocheck
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq build-essential curl ca-certificates pkg-config libasound2-dev libssl-dev >/dev/null 2>&1
curl -kfsSL https://sh.rustup.rs | sh -s -- -y --profile minimal >/dev/null 2>&1
. "$HOME/.cargo/env"
cd /tmp && curl -kfsSL -o sd.tar.gz "https://github.com/Spotifyd/spotifyd/archive/refs/tags/v'"$VER"'.tar.gz"
tar xzf sd.tar.gz && cd spotifyd-'"$VER"'
cargo build --release >/tmp/build.log 2>&1 || { tail -20 /tmp/build.log; exit 1; }
strip target/release/spotifyd
cp target/release/spotifyd /out/spotifyd
'
ls -l "$OUT/spotifyd"
