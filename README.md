# Yandex Station Mini 2 — toolkit

Всё, что нужно, чтобы получить **root ADB**, поставить **SSH**, отключить автообновления и
добавить приёмник **AirPlay / Spotify Connect** на Яндекс Станции Мини 2.

Проверено на **YNDX-00020**, прошивка `0.369.1.50.4794659041.20261021.299`.

> Всё делается на **своём** устройстве. Теряется гарантия, устройство может превратиться в
> кирпич. Читайте [docs/FINDINGS.md](docs/FINDINGS.md) — там описано, на чём именно спотыкаются
> люди и почему.

## Что внутри

| Компонент | Что даёт | Где |
|---|---|---|
| ADB + root | шелл от root на `:5555`, переживает перезагрузки | `scripts/install-adb.sh` |
| SSH (dropbear) | `ssh alisa-2` с баннером, только по ключу | `scripts/install-ssh.sh` |
| fastfetch | красивый логин-баннер | `scripts/install-fastfetch.sh` |
| AirPlay | станция как AirPlay-приёмник | `scripts/install-airplay.sh` |
| Spotify Connect | станция как устройство в приложении Spotify (OAuth, без пароля) | `scripts/install-spotifyd.sh` |

## Быстрый старт

1. Получите root ADB по инструкции из [hu553in/yandex-station-root](https://github.com/hu553in/yandex-station-root)
   (это переупаковка [eQuasar](https://git.gay/iwakura/eQuasar)). Кратко:
   - поднять прокси и DNS-подмену для `quasar.yandex.net|ru`, `scbh.yandex.net`;
   - сбросить станцию, привязать Wi-Fi — станция сама предложит установку `.46`;
   - после активации `make connect && make install`.
2. Дальше — этим репозиторием:

```sh
export STATION=192.168.1.94        # IP станции
scripts/install-ssh.sh             # dropbear + ключ + автозапуск
scripts/install-fastfetch.sh       # баннер
scripts/install-spotifyd.sh        # Spotify Connect (по умолчанию)
# или, если нужен AirPlay:
# scripts/install-airplay.sh
```

### Spotify Connect: авторизация

Пароль вводить не нужно, используется OAuth:

```sh
# 1) на станции запускаем авторизацию
ssh alisa-2 '/system/vendor/quasar/bin/spotifyd authenticate \
  --cache-path /system/vendor/quasar/spotifyd-cache --oauth-port 8000'
# 2) в другом окне — туннель, чтобы redirect попал на станцию
ssh -L 8000:127.0.0.1:8000 alisa-2
# 3) открыть выданную ссылку в браузере и войти в Spotify
```

Токен сохраняется в `/system/vendor/quasar/spotifyd-cache` (переживает перезагрузку).

### AirPlay выключен по умолчанию

`S99shairport` в `files/` есть, но на устройстве он отключён (`S99shairport.disabled`).
Включить обратно: `adb shell 'mv /etc/init.d/S99shairport.disabled /etc/init.d/S99shairport && /etc/init.d/S99shairport start'`.

## Сборка бинарников

Готовые armv7-бинарники лежат в [Releases](../../releases). Если хотите собрать сами — есть
скрипты в `build/`, каждый использует Docker (`--platform linux/arm/v7`), ставить тулчейн на
хост не нужно.

```sh
build/build-dropbear.sh    # SSH-сервер
build/build-fastfetch.sh   # баннер
build/build-shairport.sh   # AirPlay
build/build-spotifyd.sh    # Spotify Connect
```

Все сборки — под **glibc 2.28** (Debian buster), потому что на станции glibc 2.30.
musl-сборки не подходят: см. [docs/FINDINGS.md](docs/FINDINGS.md#musl-и-ядро-49-падение-по-clock_gettime64).

## Устройство

| Что | Куда ставится |
|---|---|
| бинарники | `/system/vendor/quasar/bin/` |
| init-скрипты | `/etc/init.d/S99*` (busybox init) |
| баннер | `/etc/profile.d/alisa-banner.sh` |
| конфиги | `/etc/*.conf` |
| originals ADB-гарда | `/system/vendor/quasar/activate_adb.root_original.sh` |

## Требования

- Станция с root ADB.
- Mac/Linux с `adb` и (для сборки) Docker.
- Роутер, умеющий отдавать DNS на конкретное устройство.

## Лицензия

MIT. Код сборки — мой; идея и базовая методика — авторам eQuasar и hu553in.
