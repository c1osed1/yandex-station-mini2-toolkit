#!/bin/sh
# bt-proxy — прокси D-Bus, который показывает Алисе MPRIS-плееры как Bluetooth-телефоны.
#
# Собираем сами из исходников, а не кладём готовый бинарник: у проекта-источника нет
# лицензии, поэтому распространять чужие сборки нельзя. Скрипт скачивает исходники и
# собирает их локально — вы остаётесь в рамках личного использования.
#
# Нужен Docker: сборка идёт в контейнере linux/arm/v7.
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/bin"; mkdir -p "$OUT"
WORK="$(cd "$(dirname "$0")/.." && pwd)/build/.btproxy"
SRC_URL="${BT_PROXY_SRC_URL:-https://github.com/Marker284/yandex-station-extended/archive/refs/heads/main.tar.gz}"
RUST_VER="${RUST_VER:-1.99.1}"

rm -rf "$WORK"; mkdir -p "$WORK"
echo "== скачиваю исходники"
curl -fsSL "$SRC_URL" | tar xz -C "$WORK" --strip-components=1 "*/contrib/bt-proxy" 2>/dev/null ||
	{ echo "не удалось скачать исходники"; exit 1; }
ls "$WORK/contrib/bt-proxy/src" >/dev/null || { echo "исходники не найдены"; exit 1; }

echo "== собираю (Rust $RUST_VER, armv7)"
docker run --rm --platform linux/arm/v7 \
	-v "$WORK/contrib/bt-proxy:/w" -v "$OUT:/out" alpine:3.20 sh -c '
set -e
apk add --no-cache build-base curl tar >/dev/null 2>&1
curl -kfsSL -o /tmp/r.tgz "https://static.rust-lang.org/dist/rust-'"$RUST_VER"'-armv7-unknown-linux-gnueabihf.tar.gz"
tar xzf /tmp/r.tgz -C /tmp
cd /tmp/rust-'"$RUST_VER"'-armv7-unknown-linux-gnueabihf && ./install.sh --prefix=/usr/local/rust --disable-ldconfig >/dev/null 2>&1
export PATH=/usr/local/rust/bin:$PATH
cd /w && cargo build --release >/tmp/b.log 2>&1 || { grep -E "^error" /tmp/b.log | head -5; exit 1; }
strip target/release/bt-proxy
cp target/release/bt-proxy /out/bt-proxy
'
ls -l "$OUT/bt-proxy"
echo "готово: bin/bt-proxy"
