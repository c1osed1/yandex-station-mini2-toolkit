#!/bin/sh
# SSH (dropbear) + ключ + автозапуск + имя хоста
. "$(dirname "$0")/lib.sh"

KEY="${SSH_KEY:-$HOME/.ssh/id_alisa2}"
HOSTNAME_NEW="${HOSTNAME_NEW:-alisa-2}"

connect
say "подготовка /data/local/tmp (его нет на станции)"
dev "mkdir -p /data/local/tmp $BIN_DIR /etc/dropbear"
dev "chmod 700 /etc/dropbear /root/.ssh 2>/dev/null; mkdir -p /root/.ssh; chmod 700 /root/.ssh"

say "бинарники"
for b in dropbear dropbearkey dbclient; do
	push "$(find_bin $b)" "$BIN_DIR/$b" 755
done

say "host-ключи"
dev "[ -f /etc/dropbear/dropbear_ed25519_host_key ] || $BIN_DIR/dropbearkey -t ed25519 -f /etc/dropbear/dropbear_ed25519_host_key"
dev "[ -f /etc/dropbear/dropbear_rsa_host_key ] || $BIN_DIR/dropbearkey -t rsa -s 2048 -f /etc/dropbear/dropbear_rsa_host_key"

say "ключ доступа"
[ -f "$KEY" ] || die "нет ключа $KEY (ssh-keygen -t ed25519 -f $KEY -N '')"
[ -f "$KEY.pub" ] || ssh-keygen -y -f "$KEY" > "$KEY.pub"
push "$KEY.pub" /root/.ssh/authorized_keys 600

say "автозапуск и имя хоста"
push "$ROOT/files/etc/init.d/S99dropbear" /etc/init.d/S99dropbear 755
push "$ROOT/files/etc/init.d/S99hostname-alisa" /etc/init.d/S99hostname-alisa 755
dev "echo '$HOSTNAME_NEW' > /etc/hostname"
dev "sed -i 's/^127.0.1.1.*/127.0.1.1\t$HOSTNAME_NEW/' /etc/hosts"

say "запуск"
dev "/etc/init.d/S99dropbear restart >/dev/null 2>&1 || /etc/init.d/S99dropbear start"
sleep 2
"$ADB" -s "$SERIAL" shell "netstat -tln | grep -q ':22 '" && say "SSH слушает :22" || warn "порт 22 не слушает — смотрите логи"

cat <<TIP

Добавьте в ~/.ssh/config:

Host $HOSTNAME_NEW
  HostName $STATION
  User root
  IdentityFile $KEY
  StrictHostKeyChecking accept-new

Проверка: ssh $HOSTNAME_NEW
TIP
