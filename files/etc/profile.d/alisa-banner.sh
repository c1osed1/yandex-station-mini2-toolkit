#!/bin/sh
# Баннер при входе: логотип Алисы (кольцо, фиолетовый градиент) + модули fastfetch.
# Картинка лежит в /etc/fastfetch/alisa-art.txt, её можно заменить своей.
[ -n "$PS1" ] || exit 0

FF=/system/vendor/quasar/bin/fastfetch
ART=/etc/fastfetch/alisa-art.txt
WIDTH=58   # ширина картинки в символах + два пробела

if [ -x "$FF" ] && [ -f "$ART" ]; then
	"$FF" -l none --structure Title:Separator:OS:Host:Kernel:Uptime:CPU:Memory:Disk:LocalIp 2>/dev/null |
		awk -v art="$ART" -v w="$WIDTH" '
			BEGIN { n = 0; while ((getline line < art) > 0) a[++n] = line }
			{ if (NR <= n) printf "%s  %s\n", a[NR], $0
			  else         printf "%" w "s  %s\n", "", $0 }'
	FW=$(cat /system/vendor/quasar/VERSION 2>/dev/null)
	[ -n "$PS1" ] || exit 0
	if netstat -tln 2>/dev/null | grep -q ':5555 '; then A="ADB on"; else A="ADB off"; fi
	if netstat -tln 2>/dev/null | grep -q ':22 ';   then S="SSH on"; else S="SSH off"; fi
	printf '%*s\033[38;2;200;162;255mquasar %s   %s  %s\033[0m\n\n' "$WIDTH" "" "${FW:-?}" "$S" "$A"
else
	printf '\n  %s — Yandex Station Mini 2\n\n' "$(hostname)"
fi
