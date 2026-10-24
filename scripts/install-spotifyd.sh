#!/bin/sh
# Spotify Connect (spotifyd) — станция как устройство в приложении Spotify
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect
say "бинарник"
push "$(find_bin spotifyd)" "$BIN_DIR/spotifyd" 755

say "конфиг"
if [ -n "$SPOTIFY_USER" ] && [ -n "$SPOTIFY_PASS" ]; then
	sed "s|^# username = .*|username = \"$SPOTIFY_USER\"|; s|^# password = .*|password = \"$SPOTIFY_PASS\"|" \
		"$ROOT/files/etc/spotifyd.conf" > /tmp/spotifyd.conf.$$
	push /tmp/spotifyd.conf.$$ /etc/spotifyd.conf 600
	rm -f /tmp/spotifyd.conf.$$
	say "логин записан в /etc/spotifyd.conf (права 600)"
else
	push "$ROOT/files/etc/spotifyd.conf" /etc/spotifyd.conf 644
	warn "логин Spotify не задан. Выполните один раз:"
	warn "  adb shell '$BIN_DIR/spotifyd --authenticate'"
	warn "или переустановите с SPOTIFY_USER=... SPOTIFY_PASS=..."
fi

say "хук освобождения ALSA и автозапуск"
push "$ROOT/files/etc/airplay-free.sh" /etc/airplay-free.sh 755
push "$ROOT/files/etc/init.d/S99spotifyd" /etc/init.d/S99spotifyd 755
dev "/etc/init.d/S99spotifyd restart >/dev/null 2>&1 || /etc/init.d/S99spotifyd start"
sleep 3
say "смотрите лог: adb shell tail -f /tmp/spotifyd.log"
