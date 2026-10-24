# Yandex Station Mini 2 — toolkit
STATION ?= 192.168.1.94
export STATION

.PHONY: help install-statusd root-adb router-dns build-all build-dropbear build-fastfetch build-shairport build-spotifyd \
        install-ssh install-fastfetch install-airplay install-spotifyd uninstall lint

help:
	@printf '%s\n' \
	  'Сборка (нужен Docker, ничего ставить на хост не требуется):' \
	  '  make build-dropbear     SSH-сервер (musl, статический)' \
	  '  make build-fastfetch    баннер (musl, статический)' \
	  '  make build-shairport    AirPlay (glibc 2.28)' \
	  '  make build-spotifyd     Spotify Connect (glibc 2.28, долго)' \
	  '  make build-all          всё подряд' \
	  '' \
	  'Root ADB (шаг 0) и роутер:' \
	  '  make root-adb           оркестратор: тянет upstream-инструмент и ведёт по шагам' \
	  '  make router-dns         DNS станции -> машина с прокси (OpenWrt)' \
	  '' \
	  'Установка (нужен adb и root на станции):' \
	  '  make install-ssh        dropbear + ключ + автозапуск' \
	  '  make install-fastfetch  fastfetch + баннер при входе' \
	  '  make install-airplay    AirPlay-приёмник' \
	  '  make install-statusd    мини-монитор на индикаторе (температура/загрузка)' \
	  '  make install-spotifyd   Spotify Connect' \
	  '  make uninstall          снять всё, кроме ADB-гарда' \
	  '' \
	  'Переменные: STATION=192.168.1.94 BIN_SRC=/путь/к/бинарникам'

root-adb:   ; scripts/root-adb.sh
router-dns: ; scripts/router-dns.sh --proxy "$${PROXY_IP:?укажите PROXY_IP=...}"

build-all: build-dropbear build-fastfetch build-shairport build-spotifyd

build-dropbear:    ; build/build-dropbear.sh
build-fastfetch:   ; build/build-fastfetch.sh
build-shairport:   ; build/build-shairport.sh
build-spotifyd:    ; build/build-spotifyd.sh

install-ssh:       ; scripts/install-ssh.sh
install-fastfetch: ; scripts/install-fastfetch.sh
install-airplay:   ; scripts/install-airplay.sh
install-statusd:   ; scripts/install-statusd.sh
install-spotifyd:  ; scripts/install-spotifyd.sh
uninstall:         ; scripts/uninstall.sh

lint:
	@command -v shellcheck >/dev/null && shellcheck -s sh scripts/*.sh build/*.sh || echo "shellcheck не установлен — пропускаю"
