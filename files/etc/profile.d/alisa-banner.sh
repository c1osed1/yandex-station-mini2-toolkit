#!/bin/sh
# Баннер при входе: логотип Алисы (fastfetch) + строка состояния.
#
# ВАЖНО: этот файл не запускается, а ПОДКЛЮЧАЕТСЯ через /etc/profile,
# поэтому здесь нельзя использовать exit — он завершит саму оболочку
# и `adb shell <команда>` перестанет выдавать вывод.
# Показываем баннер только при интерактивном входе по SSH.

if [ -n "$SSH_CONNECTION" ] && [ -t 1 ] && [ -n "$PS1" ]; then
	FF=/system/vendor/quasar/bin/fastfetch
	CFG=/etc/fastfetch/config.jsonc

	if [ -x "$FF" ] && [ -f "$CFG" ]; then
		"$FF" -c "$CFG" 2>/dev/null
	elif [ -x "$FF" ]; then
		"$FF" --logo small 2>/dev/null
	else
		printf '\n  %s — Yandex Station Mini 2\n\n' "$(hostname)"
	fi

	FW=$(cat /system/vendor/quasar/VERSION 2>/dev/null)
	if netstat -tln 2>/dev/null | grep -q ':5555 '; then A="ADB on"; else A="ADB off"; fi
	if netstat -tln 2>/dev/null | grep -q ':22 ';   then S="SSH on"; else S="SSH off"; fi
	printf '  \033[38;2;122;85;255mquasar %s   %s  %s\033[0m\n\n' "${FW:-?}" "$S" "$A"
fi
