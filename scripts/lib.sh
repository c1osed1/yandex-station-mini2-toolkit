#!/bin/sh
# Общие функции для установщиков. Подключается через . scripts/lib.sh
set -e

STATION="${STATION:-192.168.1.94}"
ADB="${ADB:-adb}"
SERIAL="$STATION:5555"
BIN_DIR=/system/vendor/quasar/bin
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

connect() {
	"$ADB" connect "$SERIAL" >/dev/null 2>&1 || true
	"$ADB" -s "$SERIAL" shell true >/dev/null 2>&1 || die "нет ADB к $SERIAL (проверьте STATION и что станция включена)"
}

# выполнить shell-команду на станции с rw-корнем
dev() { "$ADB" -s "$SERIAL" shell "mount -o remount,rw / >/dev/null 2>&1; $*"; }

# залить файл: push <локальный> <удалённый> [права]
push() {
	local src=$1 dst=$2 mode=${3:-644}
	[ -f "$src" ] || die "нет файла $src"
	"$ADB" -s "$SERIAL" push "$src" /tmp/.push >/dev/null 2>&1 || die "не удалось залить $src"
	dev "cp /tmp/.push '$dst' && chmod $mode '$dst' && rm -f /tmp/.push"
}

# найти бинарник: сначала $BIN_SRC, потом ./bin, потом ошибка с подсказкой
find_bin() {
	local name=$1
	for d in "${BIN_SRC:-}" "$ROOT/bin" "$ROOT"; do
		[ -n "$d" ] && [ -f "$d/$name" ] && { echo "$d/$name"; return 0; }
	done
	die "не найден бинарник $name. Скачайте из Releases или соберите: build/build-${name%%-*}.sh"
}
