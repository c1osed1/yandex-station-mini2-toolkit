#!/bin/sh
# Баннер при входе: логотип Квазара (силуэт Алисы) + сводка о станции.
# Цвет логотипа можно поменять: ALISA_LOGO_COLOR=99
[ -n "$PS1" ] || exit 0

FF=/system/vendor/quasar/bin/fastfetch
COLOR=${ALISA_LOGO_COLOR:-135}

if [ -x "$FF" ]; then
	"$FF" -l Quasar --logo-color-1 "$COLOR" --logo-padding-left 1 \
		--structure Title:Separator:OS:Host:Kernel:Uptime:CPU:Memory:Disk:LocalIp 2>/dev/null
else
	printf '\n  %s — Yandex Station Mini 2\n\n' "$(hostname)"
fi

FW=$(cat /system/vendor/quasar/VERSION 2>/dev/null)
if netstat -tln 2>/dev/null | grep -q ':5555 '; then A="ADB on"; else A="ADB off"; fi
if netstat -tln 2>/dev/null | grep -q ':22 ';   then S="SSH on"; else S="SSH off"; fi
printf '  \033[38;5;%smquasar %s   %s  %s\033[0m\n\n' "$COLOR" "${FW:-?}" "$S" "$A"
