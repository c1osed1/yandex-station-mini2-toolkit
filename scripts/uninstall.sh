#!/bin/sh
# Снять всё, что ставили (ADB-гард не трогаем)
. "$(dirname "$0")/lib.sh"

connect
say "останавливаю сервисы"
for s in S99shairport S99spotifyd S99dropbear S99hostname-alisa; do
	dev "[ -x /etc/init.d/$s ] && /etc/init.d/$s stop" || true
	dev "rm -f /etc/init.d/$s"
done

say "удаляю файлы"
dev "rm -f /etc/shairport-sync.conf /etc/spotifyd.conf /etc/airplay-free.sh"
dev "rm -f /etc/profile.d/alisa-banner.sh"
dev "rm -f $BIN_DIR/dropbear $BIN_DIR/dropbearkey $BIN_DIR/dbclient $BIN_DIR/fastfetch $BIN_DIR/shairport-sync $BIN_DIR/spotifyd"
dev "rm -f /usr/bin/fastfetch"
dev "sed -i '/openwrt-yandex/d' /root/.ssh/authorized_keys 2>/dev/null || true"

say "готово. ADB-гард и отключённые обновления остались — их снимает yandex-station-root (make restore-adb / restore-updates)"
