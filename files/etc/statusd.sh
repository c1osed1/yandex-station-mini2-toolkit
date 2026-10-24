#!/bin/sh
# Мини-монитор на индикаторе Мини 2: температура и загрузка CPU на цифрах,
# цвет кольца по температуре. Штатный демон пишет сегменты дифференциально,
# поэтому перерисовываем раз в секунду и держим картинку своей.
# Откат: /etc/init.d/S99statusd stop && reboot

LED=/sys/class/leds
SLEEP=${STATUSD_INTERVAL:-1}

# сегменты, которые надо зажечь для символа
segs() {
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
		L) echo "D E F" ;;
		P) echo "A B E F G" ;;
		r) echo "E G" ;;
		-) echo "G" ;;
	esac
}

# draw <разряд 1-4> <символ>
draw() {
	pos=$1; sym=$2
	on=$(segs "$sym")
	for s in A B C D E F G; do
		v=0
		case " $on " in *" $s "*) v=255 ;; esac
		printf '%s' "$v" > "$LED/mini2:white:clock$s$pos/brightness" 2>/dev/null
	done
}

# draw_int <число> <с какого разряда> <сколько разрядов>
draw_int() {
	num=$1; start=$2; width=$3
	i=$width
	while [ "$i" -ge 1 ]; do
		d=$((num % 10))
		draw $((start + i - 1)) "$d"
		num=$((num / 10))
		i=$((i - 1))
	done
}

blank() { for s in A B C D E F G; do for d in 1 2 3 4; do printf 0 > "$LED/mini2:white:clock$s$d/brightness" 2>/dev/null; done; done; }
degree() { printf '%s' "$1" > "$LED/mini2:white:clockDEGREE/brightness" 2>/dev/null; }

# ring <r> <g> <b> <яркость 0-255>
ring() {
	i=1
	while [ "$i" -le 6 ]; do
		printf '%s' "$1" > "$LED/mini2:red:ring$i/brightness" 2>/dev/null
		printf '%s' "$2" > "$LED/mini2:green:ring$i/brightness" 2>/dev/null
		printf '%s' "$3" > "$LED/mini2:blue:ring$i/brightness" 2>/dev/null
		i=$((i + 1))
	done
}

temp_c() { awk '{printf "%d", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null; }
load_pct() {
	awk '{printf "%d", ($1+$2)*100/2}' /proc/loadavg 2>/dev/null
}

mode=temp
while :; do
	t=$(temp_c); [ -n "$t" ] || t=0
	l=$(load_pct); [ -n "$l" ] || l=0

	if [ "$mode" = temp ]; then
		draw_int "$t" 1 2
		draw 3 C
		draw 4 ""
		degree 255
	else
		blank
		draw_int "$l" 1 2
		draw 3 P
		degree 0
	fi

	# кольцо: зелёный -> жёлтый -> красный по температуре, яркость по загрузке
	if [ "$t" -lt 45 ]; then r=0;   g=200; b=60
	elif [ "$t" -lt 55 ]; then r=200; g=140; b=0
	else r=255; g=20; b=0
	fi
	br=$((60 + l * 2))
	[ "$br" -gt 255 ] && br=255
	ring $((r * br / 255)) $((g * br / 255)) $((b * br / 255))

	[ "$mode" = temp ] && mode=load || mode=temp
	sleep "$SLEEP"
done
