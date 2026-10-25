#!/bin/sh
# логин-баннер: fastfetch + пара полезных строк
[ -n "$PS1" ] || exit 0
FF=/system/vendor/quasar/bin/fastfetch
if [ -x "$FF" ]; then
  "$FF" --logo small --structure Title:Separator:OS:Host:Kernel:Uptime:CPU:Memory:Disk:LocalIp 2>/dev/null
else
  printf '\n  %s — Yandex Station Mini 2\n\n' "$(hostname)"
fi
FW=$(cat /system/vendor/quasar/VERSION 2>/dev/null)
netstat -tln 2>/dev/null | grep -q ':5555 ' && A="ADB on" || A="ADB off"
netstat -tln 2>/dev/null | grep -q ':22 '   && S="SSH on" || S="SSH off"
printf '  \033[0;33mquasar\033[0m %s   \033[0;33m%s\033[0m  \033[0;33m%s\033[0m\n\n' "${FW:-?}" "$S" "$A"
