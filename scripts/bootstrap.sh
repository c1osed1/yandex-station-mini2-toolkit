#!/bin/sh
# Ставит всё сразу: SSH + fastfetch (+ AirPlay по флагу).
#   scripts/bootstrap.sh                 # SSH + fastfetch
#   scripts/bootstrap.sh --with-airplay  # + AirPlay
#   STATION=192.168.1.50 scripts/bootstrap.sh
set -e
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

WITH_AIRPLAY=0
for a in "$@"; do
	case "$a" in
		--with-airplay) WITH_AIRPLAY=1 ;;
		-h|--help) sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*) echo "неизвестный аргумент: $a" >&2; exit 1 ;;
	esac
done

export STATION="${STATION:-192.168.1.94}"
# shellcheck source=scripts/lib.sh
. "$HERE/lib.sh"

say() { printf '\n\033[1;36m### %s\033[0m\n' "$*"; }

say "Связь со станцией $STATION"
connect
echo "  ADB с root: ok"

say "1/3 SSH (dropbear + ключ + автозапуск)"
"$HERE/install-ssh.sh"

say "2/3 fastfetch (баннер при входе)"
"$HERE/install-fastfetch.sh"

if [ "$WITH_AIRPLAY" -eq 1 ]; then
	say "3/3 AirPlay"
	"$HERE/install-airplay.sh"
else
	say "3/3 AirPlay пропущен (добавьте --with-airplay)"
fi

printf '\n\033[1;32mГотово.\033[0m\n'
printf '  ssh %s            — вход по ключу ~/.ssh/id_alisa2\n' "${HOSTNAME_NEW:-alisa-2}"
printf '  adb connect %s:5555   — ADB с root\n' "$STATION"
printf '  проблемы — docs/FINDINGS.md\n'
