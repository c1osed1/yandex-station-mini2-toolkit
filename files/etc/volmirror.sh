#!/bin/sh
# Связывает громкость Алисы и AirPlay.
#
# Алиса (и кнопки) крутят ALSA-контрол "Master", но на звук он не влияет —
# это зеркало для индикатора. Реальная громкость сидит в "SPK Master".
# AirPlay (shairport) пишет в "SPK Master" сам, поэтому ползунок на Mac работает.
# Здесь мы переносим "Master" -> "SPK Master", пока играет AirPlay, чтобы
# голосом и кнопками можно было регулировать и AirPlay.
#
# Когда AirPlay не играет, "SPK Master" возвращается в максимум: громкостью
# штатной колонки управляет прошивка, и дублировать её тут не нужно.
# Откат: /etc/init.d/S99volmirror stop

MIXVOL=/system/vendor/quasar/bin/mixvol
STATUS=/proc/asound/card0/pcm0p/sub0/status
INTERVAL=${VOLMIRROR_INTERVAL:-0.5}

mix_get() { "$MIXVOL" 2>/dev/null | grep "^$1 " | grep -oE "cur=[0-9]+" | cut -d= -f2; }
mix_set() { "$MIXVOL" set "$1" "$2" >/dev/null 2>&1; }

playing() { head -1 "$STATUS" 2>/dev/null | grep -q RUNNING; }

prev=""
was_playing=0
while :; do
	if playing; then
		cur=$(mix_get Master)
		if [ -z "$prev" ]; then
			# только что началась сессия: запоминаем значение Алисы, но НЕ пишем его,
			# иначе затираем громкость, которую выставил телефон/плеер
			prev=$cur
		elif [ -n "$cur" ] && [ "$cur" != "$prev" ]; then
			mix_set "SPK Master" "$cur"
			prev=$cur
		fi
		was_playing=1
	else
		if [ "$was_playing" = 1 ]; then
			mix_set "SPK Master" 255
			prev=""; was_playing=0
		fi
	fi
	sleep "$INTERVAL"
done
