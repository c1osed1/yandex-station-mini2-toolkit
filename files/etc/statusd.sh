#!/bin/sh
# Индикатор Мини 2.
#
#   STATUSD_MODE=auto (по умолчанию)
#       AirPlay не играет  -> рисуем часы ровно как штатные (та же яркость, тот же вид)
#       AirPlay играет     -> рисуем эквалайзер
#   STATUSD_MODE=off           ничего не рисовать, отдать индикатор прошивке
#
# Кольцо (mini2:*:ring*) не трогаем вообще.
#
# Дисплей — 4-разрядный 7-сегментный индикатор. В эквалайзере сегменты A (верх),
# G (середина) и D (низ) работают как полоски: 4 полосы по 3 уровня.
# Прошивка (maind --platformd) пишет сегменты дифференциально — только изменившиеся,
# поэтому своя перерисовка раз в кадр держит картинку нашей и ничего не ломает.
#
# Откат: /etc/init.d/S99statusd stop && reboot

LED=/sys/class/leds
MODE=${STATUSD_MODE:-auto}
STATE=${STATUSD_STATE:-/tmp/airplay.state}
TZOFF=${STATUSD_TZ_OFFSET:-3}          # сдвиг часового пояса для часов
CLOCK_BRIGHT=${STATUSD_CLOCK_BRIGHT:-170}

# ── сегменты ─────────────────────────────────────────────────────────────
sym_segs() {
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
		"") echo "" ;;
	esac
}

draw_sym() { # <разряд> <символ> <яркость>
	pos=$1; on=$(sym_segs "$2"); br=$3
	for s in A B C D E F G; do
		v=0
		case " $on " in *" $s "*) v=$br ;; esac
		printf '%s' "$v" > "$LED/mini2:white:clock$s$pos/brightness" 2>/dev/null
	done
}

set_br() { printf '%s' "$2" > "$LED/mini2:white:$1/brightness" 2>/dev/null; }

# ── часы ─────────────────────────────────────────────────────────────────
render_clock() {
	hm=$(date -u -d "@$(( $(date +%s) + TZOFF * 3600 ))" +%H%M 2>/dev/null) || return 0
	draw_sym 1 "$(echo "$hm" | cut -c1)" "$CLOCK_BRIGHT"
	draw_sym 2 "$(echo "$hm" | cut -c2)" "$CLOCK_BRIGHT"
	draw_sym 3 "$(echo "$hm" | cut -c3)" "$CLOCK_BRIGHT"
	draw_sym 4 "$(echo "$hm" | cut -c4)" "$CLOCK_BRIGHT"
	set_br clockPLUS1 "$CLOCK_BRIGHT"   # двоеточие, как у прошивки
	set_br clockPLUS2 "$CLOCK_BRIGHT"
	set_br clockDEGREE 0
	set_br clockMINUS 0
}

# ── эквалайзер ───────────────────────────────────────────────────────────
bar() { # <разряд> <уровень 0..3>
	pos=$1; lvl=$2
	a=0; g=0; d=0
	[ "$lvl" -ge 1 ] && d=255
	[ "$lvl" -ge 2 ] && g=255
	[ "$lvl" -ge 3 ] && a=255
	set_br "clockA$pos" "$a"; set_br "clockG$pos" "$g"; set_br "clockD$pos" "$d"
	for s in B C E F; do set_br "clock$s$pos" 0; done
}

get_v() { case "$1" in 1) echo "$v1" ;; 2) echo "$v2" ;; 3) echo "$v3" ;; 4) echo "$v4" ;; esac; }
set_v() { case "$1" in 1) v1=$2 ;; 2) v2=$2 ;; 3) v3=$2 ;; 4) v4=$2 ;; esac; }

equalizer() {
	v1=12; v2=12; v3=12; v4=12
	set_br clockPLUS1 0; set_br clockPLUS2 0
	while [ "$(cat "$STATE" 2>/dev/null)" = playing ]; do
		for b in 1 2 3 4; do
			cur=$(get_v "$b")
			seed=$(( (seed * 65 + 31) % 1000 ))
			cur=$(( cur + (seed % 9) - 4 ))
			[ "$cur" -lt 2 ] && cur=2
			[ "$cur" -gt 30 ] && cur=30
			set_v "$b" "$cur"
			if [ "$cur" -le 10 ]; then lvl=1
			elif [ "$cur" -le 20 ]; then lvl=2
			else lvl=3
			fi
			bar "$b" "$lvl"
		done
		sleep 0.08
	done
	render_clock    # сразу вернуть часы, чтобы не осталось мусора
}

seed=$(od -An -N2 -tu2 /dev/urandom 2>/dev/null | tr -d ' '); [ -n "$seed" ] || seed=7

case "$MODE" in
	auto)
		while :; do
			if [ "$(cat "$STATE" 2>/dev/null)" = playing ]; then
				equalizer
			else
				render_clock
				sleep 1
			fi
		done
		;;
	off)  exit 0 ;;
	*) echo "STATUSD_MODE: auto|off" >&2; exit 1 ;;
esac
