#!/bin/sh
# Баннер при входе: логотип Алисы (fastfetch) + строка состояния.
# Показываем только на терминале (ssh), чтобы не мусорить в выводе adb shell.
[ -t 0 ] || exit 0
[ -n "$PS1" ] || exit 0

FF=/system/vendor/quasar/bin/fastfetch
CFG=/etc/fastfetch/config.jsonc

if [ -x "$FF" ] && [ -f "$CFG" ]; then
	"$FF" -c "$CFG" 2>/dev/null
else
	"$FF" --logo small 2>/dev/null || printf '\n  %s — Yandex Station Mini 2\n\n' "$(hostname)"
fi

FW=$(cat /system/vendor/quasar/VERSION 2>/dev/null)
netstat -tln 2>/dev/null | grep -q ':5555 ' && A="ADB on" || A="ADB off"
netstat -tln 2>/dev/null | grep -q ':22 '   && S="SSH on" || S="SSH off"
printf '  \033[38;2;122;85;255mquasar %s   %s  %s\033[0m\n\n' "${FW:-?}" "$S" "$A"
