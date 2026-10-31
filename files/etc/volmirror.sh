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

# Кривая громкости. SPK Master линеен по амплитуде, а слышим мы логарифмически:
# ниже ~70 по этой шкале вообще тишина. Поэтому значение Алисы (0-255) пересчитываем
# в «амплитудное» по таблице, близкой к степени 0.45.
curve() {
	case "$1" in
		0) echo 0 ;;
		1|2|3|4|5|6|7|8|9|1[0-9]|2[0-5]) echo 90 ;;
		2[6-9]|3[0-9]|4[0-9]|5[01]) echo 124 ;;
		5[2-9]|6[0-9]|7[0-6]) echo 145 ;;
		7[7-9]|8[0-9]|9[0-9]|10[0-2]) echo 169 ;;
		10[3-9]|11[0-9]|12[0-8]) echo 187 ;;
		12[9]|13[0-9]|14[0-9]|15[0-3]) echo 203 ;;
		15[4-9]|16[0-9]|17[0-8]) echo 217 ;;
		17[9]|18[0-9]|19[0-9]|20[0-4]) echo 231 ;;
		20[5-9]|21[0-9]|22[0-9]|23[0]) echo 243 ;;
		*) echo 255 ;;
	esac
}

playing() { head -1 "$STATUS" 2>/dev/null | grep -q RUNNING; }

# отладочный режим: volmirror.sh curve 128  -> напечатать значение кривой
if [ "${1:-}" = "curve" ] && [ -n "${2:-}" ]; then
	curve "$2"
	exit 0
fi

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
			mix_set "SPK Master" "$(curve "$cur")"
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
