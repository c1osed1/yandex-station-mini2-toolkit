#!/bin/sh
# Статический dropbear (musl) под armv7. На станции работает: clock_gettime64 не использует.
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/bin"; mkdir -p "$OUT"
VER="${DROPBEAR_VER:-2026.94}"
docker run --rm --platform linux/arm/v7 -v "$OUT:/out" alpine:3.20 sh -c '
apk add --no-cache build-base curl tar >/dev/null 2>&1
cd /tmp && curl -fsSL -o d.tbz "https://matt.ucc.asn.au/dropbear/releases/dropbear-'"$VER"'.tar.bz2"
tar xf d.tbz && cd dropbear-'"$VER"'
./configure --disable-zlib >/dev/null 2>&1
make -j4 PROGRAMS="dropbear dbclient dropbearkey" LDFLAGS="-static -s" >/dev/null 2>&1
cp dropbear dbclient dropbearkey /out/
'
ls -l "$OUT"/dropbear "$OUT"/dbclient "$OUT"/dropbearkey
