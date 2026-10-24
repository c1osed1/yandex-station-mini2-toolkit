#!/bin/sh
# Общие функции для установщиков. Подключается через: . "$(dirname "$0")/lib.sh"
set -e

STATION="${STATION:-192.168.1.94}"
ADB="${ADB:-adb}"
SERIAL="$STATION:5555"
BIN_DIR=/system/vendor/quasar/bin
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
export STATION ADB SERIAL BIN_DIR ROOT

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

connect() {
	"$ADB" connect "$SERIAL" >/dev/null 2>&1 || true
	if ! "$ADB" -s "$SERIAL" shell true >/dev/null 2>&1; then
		die "нет ADB к $SERIAL (проверьте STATION и что станция включена)"
	fi
}

# выполнить команду на станции с rw-корнем
dev() { "$ADB" -s "$SERIAL" shell "mount -o remount,rw / >/dev/null 2>&1; $*"; }

# push <локальный> <удалённый> [права]
push() {
	src=$1; dst=$2; mode=${3:-644}
	[ -f "$src" ] || die "нет файла $src"
	"$ADB" -s "$SERIAL" push "$src" /tmp/.push >/dev/null 2>&1 || die "не удалось залить $src"
	dev "cp /tmp/.push '$dst' && chmod $mode '$dst' && rm -f /tmp/.push"
}

# найти бинарник: $BIN_SRC, затем ./bin, затем корень репозитория
find_bin() {
	for d in "${BIN_SRC:-}" "$ROOT/bin" "$ROOT"; do
		if [ -n "$d" ] && [ -f "$d/$1" ]; then
			printf '%s\n' "$d/$1"
			return 0
		fi
	done
	die "не найден бинарник $1 — скачайте из Releases или соберите: build/build-*.sh"
}
