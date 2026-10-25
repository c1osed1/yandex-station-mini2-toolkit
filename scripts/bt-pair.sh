#!/bin/sh
# Сопряжение Bluetooth-устройства со станцией + проверка A2DP.
#
#   scripts/bt-pair.sh --list              — что видно в эфире
#   scripts/bt-pair.sh AA:BB:CC:DD:EE:FF   — сопрячь и проверить
#   scripts/bt-pair.sh AA:BB:... --test tone.wav
#
# Учтены грабли, на которые мы наступили:
#   - bluetoothctl не видит устройство, пока не поднят ACL-линк: сначала hcitool cc;
#   - bluealsa после ручных убийств не занимает имя в D-Bus: поднимаем через init;
#   - сопряжение НЕ переживает перезагрузку (база bluez во временной ФС) — повторять.
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

LIST=0; TESTFILE=""
for a in "$@"; do
	case "$a" in
		--list) LIST=1 ;;
		--test) TEST=1 ;;
		*.wav) TESTFILE=$a ;;
		-h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*:*) MAC=$a ;;
		*) ;;
	esac
done

connect

if [ "$LIST" = 1 ] || [ -z "${MAC:-}" ]; then
	say "поиск устройств (около 15 секунд)"
	dev "bluetoothctl scan on >/dev/null 2>&1 & S=\$!; sleep 10; hcitool scan --flush > /tmp/btscan.txt 2>&1 & sleep 5; kill \$S 2>/dev/null"
	dev "grep -E '^[[:space:]]+([0-9A-F]{2}:){5}' /tmp/btscan.txt" || true
	printf '\nЗапустите повторно с MAC нужного устройства.\n'
	exit 0
fi

say "ACL-линк (без него bluetoothctl отвечает Page Timeout)"
dev "hcitool cc $MAC 2>/dev/null; sleep 1"

say "сопряжение"
i=1
while [ "$i" -le 3 ]; do
	if dev "bluetoothctl pair $MAC 2>&1 | grep -q 'Pairing successful'"; then
		say "сопряжено с $i-й попытки"
		break
	fi
	warn "попытка $i не прошла, повторяю"
	dev "hcitool cc $MAC 2>/dev/null; sleep 2"
	i=$((i + 1))
done

dev "bluetoothctl trust $MAC >/dev/null 2>&1; bluetoothctl connect $MAC >/dev/null 2>&1"
sleep 3

say "bluealsa"
dev "bluealsa-aplay -L 2>/dev/null | grep -c a2dp" >/dev/null 2>&1 || true
if ! dev "bluealsa-aplay -L 2>/dev/null | grep -q a2dp"; then
	warn "A2DP не появился, перезапускаю bluealsa"
	dev "/etc/init.d/S52bluealsa restart >/dev/null 2>&1"
	sleep 4
	dev "bluetoothctl connect $MAC >/dev/null 2>&1"
	sleep 3
fi

say "итог"
dev "bluetoothctl info $MAC 2>/dev/null | grep -E 'Paired|Connected'"
if dev "bluealsa-aplay -L 2>/dev/null | grep -q a2dp"; then
	say "A2DP есть — можно выводить звук на устройство"
else
	warn "A2DP нет. По нашему опыту это чаще всего гарнитура с урезанным BT:"
	warn "доступен только SCO (8 кГц моно), для музыки не годится."
fi

if [ -n "$TESTFILE" ]; then
	say "тестовый тон"
	push "$TESTFILE" /tmp/bt-test.wav 644
	dev "aplay -D bluealsa:DEV=$MAC,PROFILE=a2dp /tmp/bt-test.wav 2>&1 | tail -2"
fi

cat <<TIP

Важно:
  - сопряжение не сохраняется после перезагрузки станции, повторяйте этот скрипт;
  - если хотите гнать AirPlay на BT-устройство, впишите в /etc/shairport-sync.conf
    output_device = "bluealsa:DEV=$MAC,PROFILE=a2dp"
    и перезапустите: /etc/init.d/S99shairport restart
TIP
