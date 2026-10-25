#!/bin/sh
# fastfetch + логотип Алисы в приветствии при входе
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect
say "fastfetch"
push "$(find_bin fastfetch)" "$BIN_DIR/fastfetch" 755
dev "ln -sf $BIN_DIR/fastfetch /usr/bin/fastfetch"

say "логотип и конфиг"
dev "mkdir -p /etc/fastfetch"
push "$ROOT/files/etc/fastfetch/yandexstation.txt" /etc/fastfetch/yandexstation.txt 644
push "$ROOT/files/etc/fastfetch/config.jsonc" /etc/fastfetch/config.jsonc 644

say "баннер"
dev "mkdir -p /etc/profile.d"
push "$ROOT/files/etc/profile.d/alisa-banner.sh" /etc/profile.d/alisa-banner.sh 755

say "готово — зайдите по SSH и увидите логотип"
