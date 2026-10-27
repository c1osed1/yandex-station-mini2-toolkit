#!/bin/sh
# bt-proxy: показывает Алисе MPRIS-плееры как подключённые Bluetooth-телефоны,
# чтобы она управляла ими голосом («пауза», «дальше», «тише»).
#
# ВНИМАНИЕ: на Мини 2 нами НЕ проверялось. Ломает штатный Bluetooth, пока работает:
# bluetoothd и bluealsa переезжают на приватную шину, а на системной остаётся прокси.
# Откат: /etc/init.d/S55zbtproxy stop && rm /etc/init.d/S55zbtproxy && reboot
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect

say "бинарник"
dev "mkdir -p /data/opt/btproxy"
push "$(find_bin bt-proxy)" /data/opt/btproxy/bt-proxy 755
push "$ROOT/files/opt/btproxy/bus.conf" /data/opt/btproxy/bus.conf 600

say "автозапуск"
push "$ROOT/files/etc/init.d/S55zbtproxy" /etc/init.d/S55zbtproxy 755
dev "/etc/init.d/S55zbtproxy start"
sleep 3

if dev "ps 2>/dev/null | grep -q '[b]t-proxy'"; then
	say "bt-proxy запущен"
else
	warn "не запустился, смотрите /tmp/bt-proxy.log и /tmp/btbus/ сразу после старта"
fi

cat <<TIP

Что теперь: плеер, который публикует MPRIS на шине, выглядит для Алисы как
подключённый телефон. Скажите «Алиса, включи музыку» — и она отдаст ему звук.

Требования к плееру:
  - shairport-sync собран с --with-mpris-interface;
  - spotifyd публикует MPRIS по умолчанию.

Откат (обязательно, если что-то пошло не так):
  ssh alisa-2 '/etc/init.d/S55zbtproxy stop; rm -f /etc/init.d/S55zbtproxy; reboot'
TIP
