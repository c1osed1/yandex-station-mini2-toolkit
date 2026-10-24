#!/bin/sh
# Мини-монитор на индикаторе: температура и загрузка CPU на цифрах,
# цвет кольца по температуре. Штатные часы остаются рабочими — мы просто
# перерисовываем сегменты чаще, чем их трогает maind --platformd.
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect
say "демон"
push "$ROOT/files/etc/statusd.sh" /etc/statusd.sh 755

say "автозапуск"
dev "killall statusd.sh 2>/dev/null"
push "$ROOT/files/etc/init.d/S99statusd" /etc/init.d/S99statusd 755
dev "/etc/init.d/S99statusd start"
sleep 3

if dev "ps 2>/dev/null | grep -q '[s]tatusd.sh'"; then
	say "запущен — посмотрите на индикатор колонки"
else
	warn "не запустился, смотрите /tmp/statusd.log на станции"
fi

cat <<TIP

Показывает по кругу: температура (52°C) и загрузка CPU (37P).
Кольцо: зелёное до 45°, жёлтое до 55°, красное выше; яркость по загрузке.

Выключить и вернуть часы:  ssh alisa-2 /etc/init.d/S99statusd stop && ssh alisa-2 reboot
Интервал перерисовки:      STATUSD_INTERVAL=2 /etc/statusd.sh
TIP
