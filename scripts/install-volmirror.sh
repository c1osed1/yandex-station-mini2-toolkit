#!/bin/sh
# Связка громкости: голос Алисы и кнопки на колонке регулируют AirPlay.
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect

if [ ! -x /system/vendor/quasar/bin/mixvol ]; then
	warn "нет /system/vendor/quasar/bin/mixvol — соберите из build/build-mixvol.sh"
	exit 1
fi

say "демон"
push "$ROOT/files/etc/volmirror.sh" /etc/volmirror.sh 755

say "автозапуск"
push "$ROOT/files/etc/init.d/S99volmirror" /etc/init.d/S99volmirror 755
dev "/etc/init.d/S99volmirror restart >/dev/null 2>&1 || /etc/init.d/S99volmirror start"
sleep 2

if dev "ps 2>/dev/null | grep -q '[v]olmirror.sh'"; then
	say "запущен — теперь Алиса и кнопки регулируют и AirPlay"
else
	warn "не запустился, смотрите /tmp/volmirror.log"
fi

cat <<TIP

Как это работает:
  Алиса и кнопки крутят ALSA-контрол "Master", но на звук он не влияет
  (зеркало для индикатора). Реальная громкость — в "SPK Master".
  AirPlay пишет в "SPK Master" сам, поэтому ползунок на Mac работает.
  Демон переносит "Master" -> "SPK Master", пока играет AirPlay.

Выключить: ssh alisa-2 /etc/init.d/S99volmirror stop && reboot
TIP
