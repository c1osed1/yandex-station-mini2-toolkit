#!/bin/sh
# fastfetch + красивый баннер при входе
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

connect
say "fastfetch"
push "$(find_bin fastfetch)" "$BIN_DIR/fastfetch" 755
dev "ln -sf $BIN_DIR/fastfetch /usr/bin/fastfetch"

say "баннер"
dev "mkdir -p /etc/profile.d"
push "$ROOT/files/etc/profile.d/alisa-banner.sh" /etc/profile.d/alisa-banner.sh 755

say "готово — зайдите по SSH и увидите баннер"
