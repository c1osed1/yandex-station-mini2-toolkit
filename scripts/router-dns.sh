#!/bin/sh
# Переключает DNS станции на машину с прокси (OpenWrt, fw4/nft).
# Нужно, чтобы DNS-подмена не задела телефон с приложением «Дом с Алисой».
#
#   scripts/router-dns.sh --proxy 192.168.1.166
#   scripts/router-dns.sh --proxy 192.168.1.166 --mac ac:ba:c0:1b:b5:e6
#   scripts/router-dns.sh --remove
#
# Требуется ssh-доступ к роутеру (по умолчанию root@192.168.1.1).
set -e

ROUTER="${ROUTER:-root@192.168.1.1}"
PROXY="${PROXY:-}"
MAC="${MAC:-ac:ba:c0:1b:b5:e6}"
MODE=add

while [ $# -gt 0 ]; do
	case "$1" in
		--proxy) PROXY=$2; shift 2 ;;
		--mac) MAC=$2; shift 2 ;;
		--router) ROUTER=$2; shift 2 ;;
		--remove) MODE=remove; shift ;;
		-h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*) echo "неизвестный аргумент: $1" >&2; exit 1 ;;
	esac
done

echo "==> роутер: $ROUTER"
[ "$MODE" = remove ] || { [ -n "$PROXY" ] || { echo "нужен --proxy <ip машины с прокси>" >&2; exit 1; }; }

if [ "$MODE" = remove ]; then
	ssh "$ROUTER" '
		for h in $(nft -a list ruleset | grep -E "ct status dnat .*:53|dport 53 .*dnat ip to" | grep -oE "handle [0-9]+" | awk "{print \$2}"); do
			nft delete rule inet fw4 dstnat handle $h 2>/dev/null
			nft delete rule inet fw4 srcnat handle $h 2>/dev/null
		done
		echo "правила сняты"
	'
	exit 0
fi

# переменные раскрываются на нашей стороне осознанно (SC2029)
# shellcheck disable=SC2029
ssh "$ROUTER" "
	set -e
	# DNS станции -> прокси (вставляем в начало, до перехвата DNS в homeproxy)
	nft insert rule inet fw4 dstnat iifname \"br-lan\" ether saddr $MAC udp dport 53 counter dnat ip to $PROXY:53
	nft insert rule inet fw4 dstnat iifname \"br-lan\" ether saddr $MAC tcp dport 53 counter dnat ip to $PROXY:53
	# обратная подмена: иначе прокси ответит напрямую и станция отбросит ответ
	nft add rule inet fw4 srcnat oifname \"br-lan\" ct status dnat ip daddr $PROXY meta l4proto { tcp, udp } th dport 53 counter snat to \$(uci get network.lan.ipaddr)
	echo 'правила добавлены:'
	nft list chain inet fw4 dstnat | grep -c \"dnat ip to $PROXY\"
"
echo "==> готово. Проверить: ssh alisa-2 'nslookup quasar.yandex.net'  — должен ответить $PROXY"
