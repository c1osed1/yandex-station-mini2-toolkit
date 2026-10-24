#!/bin/sh
# Анимации на индикаторе Мини 2.
#   STATUSD_MODE=face     (по умолчанию) — глазки: моргают, иногда подмигивают
#   STATUSD_MODE=monitor  — температура и загрузка CPU
#
# Дисплей — 4-разрядный 7-сегментный индикатор. Штатный maind --platformd
# пишет сегменты дифференциально (только изменившиеся), поэтому перерисовка
# чаще одного раза в секунду держит картинку нашей и ничего не ломает.
# Откат: /etc/init.d/S99statusd stop && reboot

LED=/sys/class/leds
MODE=${STATUSD_MODE:-face}
STEP=40                       # мс между кадрами
BRIGHT=255

on_segs() {
	case "$1" in
		0) echo "A B C D E F" ;;
		1) echo "B C" ;;
		2) echo "A B D E G" ;;
		3) echo "A B C D G" ;;
		4) echo "B C F G" ;;
		5) echo "A C D F G" ;;
		6) echo "A C D E F G" ;;
		7) echo "A B C" ;;
		8) echo "A B C D E F G" ;;
		9) echo "A B C D F G" ;;
		C) echo "A D E F" ;;
		P) echo "A B E F G" ;;
		-) echo "G" ;;
		*) echo "" ;;
	esac
}

draw() {
	pos=$1; sym=$2
	on=$(on_segs "$sym")
	for s in A B C D E F G; do
		v=0
		case " $on " in *" $s "*) v=$BRIGHT ;; esac
		printf '%s' "$v" > "$LED/mini2:white:clock$s$pos/brightness" 2>/dev/null
	done
}

clear_digits() {
	for d in 1 2 3 4; do draw "$d" ""; done
	printf 0 > "$LED/mini2:white:clockDEGREE/brightness" 2>/dev/null
	printf 0 > "$LED/mini2:white:clockMINUS/brightness" 2>/dev/null
	for i in 1 2 3 4; do printf 0 > "$LED/mini2:white:clockPLUS$i/brightness" 2>/dev/null; done
}

ring() { # r g b
	i=1
	while [ "$i" -le 6 ]; do
		printf '%s' "$1" > "$LED/mini2:red:ring$i/brightness" 2>/dev/null
		printf '%s' "$2" > "$LED/mini2:green:ring$i/brightness" 2>/dev/null
		printf '%s' "$3" > "$LED/mini2:blue:ring$i/brightness" 2>/dev/null
		i=$((i + 1))
	done
}

rnd() { awk -v a="$1" -v b="$2" 'BEGIN{srand(); print int(rand()*(b-a+1))+a}'; }
temp_c() { awk '{printf "%d", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null; }
load_pct() { awk '{printf "%d", ($1+$2)*50}' /proc/loadavg 2>/dev/null; }

draw_int() {
	num=$1; start=$2; width=$3; i=$width
	while [ "$i" -ge 1 ]; do
		draw $((start + i - 1)) $((num % 10))
		num=$((num / 10)); i=$((i - 1))
	done
}

# ── глазки ───────────────────────────────────────────────────────────────
face_loop() {
	t=0
	next_blink=$(rnd 25 70)      # в кадрах: 1-3 секунды
	blink_until=0
	wink=0
	while :; do
		# глаза: 2 и 3 разряд, широко расставленные
		if [ "$t" -lt "$blink_until" ]; then
			if [ "$wink" = 1 ]; then draw 2 -; draw 3 0; else draw 2 -; draw 3 -; fi
		else
			draw 2 0; draw 3 0
		fi
		draw 1 ""; draw 4 ""

		# кольцо дышит: треугольная волна 0..60
		ph=$((t % 90))
		if [ "$ph" -lt 45 ]; then br=$((ph * 60 / 45)); else br=$(((90 - ph) * 60 / 45)); fi
		ring 0 $((br / 3)) "$br"

		if [ "$t" -ge "$next_blink" ] && [ "$blink_until" -eq 0 ]; then
			if [ "$(rnd 1 5)" = 1 ]; then wink=1; else wink=0; fi
			blink_until=$((t + $(rnd 3 5)))   # 120-200 мс
			next_blink=$((t + $(rnd 30 90)))  # следующее моргание через 1.2-3.6 с
		fi
		[ "$blink_until" -ne 0 ] && [ "$t" -ge "$blink_until" ] && blink_until=0

		t=$((t + STEP))
		sleep 0.04
	done
}

# ── монитор ──────────────────────────────────────────────────────────────
monitor_loop() {
	t=0
	while :; do
		if [ $((t / 25 % 2)) -eq 0 ]; then
			temp=$(temp_c); [ -n "$temp" ] || temp=0
			draw_int "$temp" 1 2; draw 3 C; draw 4 ""
			printf 255 > "$LED/mini2:white:clockDEGREE/brightness" 2>/dev/null
			[ "$temp" -lt 45 ] && ring 0 200 60
			[ "$temp" -ge 45 ] && [ "$temp" -lt 55 ] && ring 200 140 0
			[ "$temp" -ge 55 ] && ring 255 20 0
		else
			load=$(load_pct); [ -n "$load" ] || load=0
			clear_digits
			draw_int "$load" 1 2; draw 3 P
			ring 0 40 120
		fi
		t=$((t + STEP))
		sleep 0.04
	done
}

clear_digits
case "$MODE" in
	face)    face_loop ;;
	monitor) monitor_loop ;;
	*) echo "STATUSD_MODE: face|monitor" >&2; exit 1 ;;
esac
