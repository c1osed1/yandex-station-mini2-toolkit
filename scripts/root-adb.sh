#!/bin/sh
# Оркестратор: root ADB на Яндекс Станции Мини 2 «под ключ».
#
# Сам MITM делает инструмент hu553in/yandex-station-root (он использует
# публично раскрытый ключ промежуточного CA — мы его не распространяем).
# Этот скрипт: скачивает его, настраивает под вашу станцию и ведёт по шагам.
#
#   scripts/root-adb.sh
#   STATION_IP=192.168.1.94 DEVICE_ID=M00NMVZ009MZ1K scripts/root-adb.sh
set -e

WORKDIR="${WORKDIR:-$HOME/yandex-station-root}"
UPSTREAM="https://github.com/hu553in/yandex-station-root"
LOCAL_IP="${LOCAL_IP:-$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')}"

step() { printf '\n\033[1;36m══ %s ══\033[0m\n' "$1"; }
ask()  { # ask <переменная> <вопрос> <значение по умолчанию>
	eval "_cur=\${$1:-}"
	printf '%s [%s]: ' "$2" "${_cur:-$3}"
	read -r _ans
	eval "$1=\${_ans:-\${_cur:-$3}}"
}

for t in git make adb; do
	command -v "$t" >/dev/null 2>&1 || { echo "нужен $t" >&2; exit 1; }
done

step "1/6 Подготовка инструмента"
if [ -d "$WORKDIR" ]; then
	echo "уже скачан: $WORKDIR"
else
	git clone --depth 1 "$UPSTREAM" "$WORKDIR"
fi
cd "$WORKDIR"
make setup >/dev/null 2>&1 || true

step "2/6 Параметры"
echo "IP станции видно в приложении «Дом с Алисой» или в DHCP-лизах роутера."
echo "DEVICE_ID и платформа — из запроса GET /get_sync_info?device_id=...&platform=... (или из логов прокси)."
ask STATION_IP "  IP станции" "192.168.1.94"
ask DEVICE_ID "  device_id" "M00NMVZ009MZ1K"
ask PLATFORM "  платформа" "yandexmini_2"
ask PROXY_IP "  IP этой машины (для прокси и DNS)" "$LOCAL_IP"

cat > config.mk <<CFG
STATION_IP := $STATION_IP
STATION_DEVICE_ID := $DEVICE_ID
PROXY_IP := $PROXY_IP
STATION_PLATFORM := $PLATFORM
CFG
echo "записано в $WORKDIR/config.mk"
make check 2>&1 | tail -2 || true

step "3/6 Выключите станцию из розетки"
cat <<TXT
Оффер обновления одноразовый: если станция загрузится раньше времени — он «сгорит».
Убедитесь, что колонка обесточена.
TXT
printf 'Enter — продолжаем: '; read -r _

step "4/6 Оффер и прокси"
make offer
cat <<TXT

Теперь в ОТДЕЛЬНОМ терминале (прокси слушает 80/443, нужен root):

    cd $WORKDIR && sudo make proxy OFFER_UPDATE=1

Если прокси должен быть виден станции по DNS — настройте роутер (OpenWrt):

    $(pwd)/../yandex-station-mini2-toolkit/scripts/router-dns.sh --proxy $PROXY_IP

или, если не OpenWrt: отдайте станции DNS-сервер $PROXY_IP
(и уберите DNS-подмену у всех остальных устройств).
TXT
printf 'Enter — когда прокси запущен: '; read -r _

step "5/6 Сброс станции"
cat <<'TXT'
Питание off → зажать кнопку отключения микрофона → подать питание →
отпустить, когда загорится ЖЁЛТЫЙ (~5 секунд). Затем привяжите Wi-Fi в приложении.

Станция заберёт конфиг у прокси, один раз предложит прошивку .46 (качается с CDN
Яндекса) и после установки поднимет ADB на :5555.
TXT
printf 'Enter — начали сброс: '; read -r _

step "6/6 Ждём ADB"
printf 'ищу %s:5555 ' "$STATION_IP"
i=0
while [ $i -lt 180 ]; do
	adb connect "$STATION_IP:5555" >/dev/null 2>&1 || true
	if adb -s "$STATION_IP:5555" shell true >/dev/null 2>&1; then
		echo; echo "  ADB на связи"
		break
	fi
	printf '.'
	i=$((i + 1))
	sleep 2
done
if ! adb -s "$STATION_IP:5555" shell true >/dev/null 2>&1; then
	echo; echo "ADB не появился. Смотрите docs/FINDINGS.md: чаще всего это .50 вместо .46"
	echo "или вылет из окна доверия (1-2 минуты после сброса)."
	exit 1
fi

echo
echo "Закрепляю root и отключаю автообновления (make install у upstream)…"
make connect >/dev/null 2>&1 || true
make install 2>&1 | tail -5 || echo "см. ошибку выше: возможно, нет /data/local/tmp — выполните adb shell mkdir -p /data/local/tmp"

step "Готово"
cat <<TXT
Дальше — наш репозиторий:

    export STATION=$STATION_IP
    scripts/bootstrap.sh --with-airplay

Остановить прокси: Ctrl+C в его терминале (или sudo pkill -f mitmdump; sudo pkill -f dns_proxy.py)
TXT
