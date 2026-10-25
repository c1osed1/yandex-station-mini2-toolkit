#!/bin/sh
# Освобождает ALSA: mediad перезапустится сам и карту не заберёт без нужды.
# busybox ps печатает PID с ведущими пробелами, поэтому берём его через awk
# (с cut -d" " -f1 получается пустая строка и kill никого не убивает).
for p in $(ps -o pid,args 2>/dev/null | awk '/maind --mediad/ && !/awk/ {print $1}'); do
	kill -9 "$p" 2>/dev/null
done
sleep 1
exit 0
