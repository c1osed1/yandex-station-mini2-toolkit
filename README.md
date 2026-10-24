# Яндекс Станция Мини 2 — root, SSH и AirPlay

[![CI](https://github.com/c1osed1/yandex-station-mini2-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/c1osed1/yandex-station-mini2-toolkit/actions)
[![Release](https://img.shields.io/github/v/release/c1osed1/yandex-station-mini2-toolkit)](https://github.com/c1osed1/yandex-station-mini2-toolkit/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Готовый набор для **Yandex Station Mini 2 (YNDX-00020)**: превращает колонку в нормальный
Linux-девайс — root по ADB, SSH с красивым баннером, приёмник AirPlay и отключённые
автообновления. Сборка бинарников и все грабли — внутри.

Проверено на прошивке `0.369.1.50.4794659041.20261021.299`.

> Работает только на **своём** устройстве. Гарантия теряется, колонку можно окирпичить.
> Перед началом прочитайте [docs/FINDINGS.md](docs/FINDINGS.md) — там 11 разделов боли,
> которую мы уже прошли за вас.

## Что вы получите

| | Команда | Что даёт |
|---|---|---|
| 🐚 | `make install-ssh` | SSH-сервер (dropbear), вход по ключу, автозапуск, имя хоста `alisa-2` |
| ✨ | `make install-fastfetch` | `fastfetch` в приветствии при входе |
| 🎵 | `make install-airplay` | станция как AirPlay-приёмник (Spotify, Apple Music, Mac/iPhone) |
| 📟 | `make install-statusd` | мини-монитор на индикаторе: температура и загрузка, цвет кольца по температуре |
| 📦 | `make build-all` | сборка всех бинарников в Docker, без тулчейна на хосте |
| 🔓 | `make root-adb` | полуавтоматический root ADB (шаг 0) + `make router-dns` для OpenWrt |

Всё сразу: `scripts/bootstrap.sh --with-airplay`

## Быстрый старт

**Шаг 0. Root ADB.** Полуавтомат: `make root-adb` — скрипт скачает
[hu553in/yandex-station-root](https://github.com/hu553in/yandex-station-root) (переупаковка
[eQuasar](https://git.gay/iwakura/eQuasar)), пропишет параметры вашей станции и проведёт по
шагам: оффер прошивки → прокси → сброс → ожидание ADB → закрепление root.

```sh
make root-adb
# отдельный терминал, когда попросит:
cd ~/yandex-station-root && sudo make proxy OFFER_UPDATE=1
# DNS станции на машину с прокси (если роутер на OpenWrt):
PROXY_IP=<ip-этой-машины> make router-dns
```

Подробности и грабли — [docs/ROOT-ADB.md](docs/ROOT-ADB.md). Вручную это выглядит так:

1. поднять прокси и подмену DNS для `quasar.yandex.net|ru` и `scbh.yandex.net`;
2. сбросить станцию и привязать Wi-Fi — она сама предложит установку прошивки `.46`;
3. после активации: `make connect && make install`.

На выходе — `adb connect <ip>:5555` и `adb shell` от root.

**Шаг 1. Бинарники.** Скачайте архив из [Releases](../../releases) и распакуйте в `bin/`:

```sh
mkdir -p bin && tar xzf yandex-station-mini2-bin-armv7.tar.gz -C bin
```

**Шаг 2. Установка.**

```sh
export STATION=192.168.1.94          # IP станции
scripts/bootstrap.sh --with-airplay  # или make install-ssh install-fastfetch install-airplay
```

**Шаг 3. Проверка.**

```sh
ssh alisa-2          # баннер + root shell
adb connect $STATION:5555
```

## Как это выглядит

```
$ ssh alisa-2
    ___       root@alisa-2
   (.. \      ------------
   (<> |      OS: Buildroot 2020.02.1 aarch64
  //  \ \     Host: Yandex Station Mini 2
 ( |  | /|    Kernel: Linux 4.9.68
_/\ __)/_)    Uptime: 3 days, 4 hours
\/-____\/     CPU:  axg (4) @ 1.20 GHz
              Memory: 117.30 MiB / 238.28 MiB (49%)
              Disk (/): 58.87 MiB / 65.74 MiB (90%) - ubifs
              Local IP (wlan0): 192.168.1.94/24
  quasar 3.21   SSH on  ADB on
```

## Требования

- Станция с **root ADB** (шаг 0).
- macOS или Linux с `adb`; для сборки — Docker (эмуляция `linux/arm/v7`).
- Всё ставится на системный раздел; бинарникам нужно ~4 МБ свободного места.

## Что работает, а что нет

Честно, по итогам проверки на живой колонке:

| Возможность | Статус |
|---|---|
| root ADB, переживает перезагрузки | ✅ |
| SSH (dropbear, только по ключу) | ✅ |
| fastfetch в баннере | ✅ |
| Отключение автообновлений (`updatesd`) | ✅ |
| AirPlay (shairport-sync) | ✅ |
| Spotify Connect (`spotifyd`, `librespot`, `spotiya`) | ❌ Spotify отказывает в аудиоключе — [подробности](docs/FINDINGS.md#11-окончательный-диагноз-аудиоключи-зависят-от-аккаунта) |
| Spotify через AirPlay | ✅ (работает, задержка ~0.5 с) |

## Установка по частям

```sh
scripts/install-ssh.sh         # SSH
scripts/install-fastfetch.sh   # баннер
scripts/install-airplay.sh     # AirPlay
scripts/uninstall.sh           # снять всё, кроме root ADB
```

Полезные переменные: `STATION` (IP), `BIN_SRC` (каталог с бинарниками), `SSH_KEY`,
`HOSTNAME_NEW`.

## Управление

```sh
ssh alisa-2                                   # вход
ssh alisa-2 /etc/init.d/S99shairport restart  # перезапустить AirPlay
ssh alisa-2 /etc/init.d/S99shairport stop     # остановить AirPlay
ssh alisa-2 /etc/init.d/S99dropbear restart   # перезапустить SSH
```

AirPlay: имя «Яндекс Станция Мини 2» в системном списке AirPlay. Задержка настраивается
в `/etc/shairport-sync.conf` (`audio_backend_latency_offset_in_seconds`, сейчас `-1.5`).

## Сборка бинарников

Всё собирается в Docker, на хосте ничего ставить не нужно:

```sh
make build-dropbear     # musl, статический
make build-fastfetch    # musl, статический
make build-shairport    # glibc 2.28 (libconfig/popt статически)
make build-spotifyd     # glibc 2.28, Rust — не работает (см. выше)
```

Почему именно glibc для части бинарников — [docs/FINDINGS.md § 4](docs/FINDINGS.md#4-musl-и-ядро-49-падение-по-clock_gettime64).

## Куда что ставится

| Что | Куда |
|---|---|
| бинарники | `/system/vendor/quasar/bin/` |
| init-скрипты | `/etc/init.d/S99*` (busybox init) |
| баннер | `/etc/profile.d/alisa-banner.sh` |
| конфиги | `/etc/*.conf` |
| оригиналы ADB-гарда | `/system/vendor/quasar/activate_adb.root_original.sh` |

## Если не работает

| Симптом | Куда смотреть |
|---|---|
| `no such file or directory` при установке | на станции нет `/data/local/tmp` — `adb shell mkdir -p /data/local/tmp` |
| `Read-only file system` | `mount -o remount,rw /` (скрипты делают это сами) |
| при загрузке не поднимается сервис | `/var/log/*.log`, `/tmp/*.log` на станции |
| AirPlay «busy» | `mediad` держит ALSA — см. [§ 5](docs/FINDINGS.md#5-mediad-монопольно-держит-alsa) |
| бинарник падает сразу | musl/`clock_gettime64` — см. [§ 4](docs/FINDINGS.md#4-musl-и-ядро-49-падение-по-clock_gettime64) |

## Что внутри

```
build/    — сборка бинарников в Docker (dropbear, fastfetch, shairport, spotifyd)
scripts/  — установка на станцию (bootstrap, ssh, fastfetch, airplay, uninstall)
files/    — init-скрипты, конфиги, баннер
docs/     — ROOT-ADB.md (как получить root), FINDINGS.md (вся техническая кухня и грабли)
```

## Благодарности

Методика получения root и идея с подменой конфига — авторам
[eQuasar](https://git.gay/iwakura/eQuasar) и [hu553in](https://github.com/hu553in).
AirPlay — [shairport-sync](https://github.com/mikebrady/shairport-sync).
Spotify Connect — [librespot](https://github.com/librespot-org/librespot),
[spotifyd](https://github.com/Spotifyd/spotifyd), [spotiya](https://github.com/klockky/spotiya).

## Лицензия

[MIT](LICENSE)
