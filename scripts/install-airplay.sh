#!/bin/sh
# AirPlay-приёмник (shairport-sync) + освобождение ALSA
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect
say "бинарник"
push "$(find_bin shairport-sync)" "$BIN_DIR/shairport-sync" 755

say "конфиг и хуки"
push "$ROOT/files/etc/shairport-sync.conf" /etc/shairport-sync.conf 644
push "$ROOT/files/etc/airplay-free.sh" /etc/airplay-free.sh 755

say "автозапуск"
push "$ROOT/files/etc/init.d/S99shairport" /etc/init.d/S99shairport 755
dev "/etc/init.d/S99shairport restart >/dev/null 2>&1 || /etc/init.d/S99shairport start"
sleep 3

if dev "netstat -tln | grep -q ':5000 '"; then say "AirPlay слушает :5000"; else warn "порт 5000 не слушает"; fi

cat <<TIP

Имя в эфире: «Яндекс Станция Мини 2» (см. files/etc/shairport-sync.conf).

Важно: mediad монопольно держит ALSA. Хук /etc/airplay-free.sh убивает его перед
воспроизведением — тот перезапустится сам и карту не заберёт. Пока играет AirPlay,
Алиса молчит.

Задержка ~0.5 c (offset -1.5 в конфиге). Если слышны пропуски — поставьте -1.0.
TIP
